;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :maxima)
;;	** (c) Copyright 1982 Massachusetts Institute of Technology **

(macsyma-module dskfn)

(declare-top (genprefix dk)
	     (special $filename $device $direc $storenum $filenum $dskall
		      $filesize filelist filelist1 opers $packagefile
		      fasdumpfl fasdeqlist fasdnoneqlist savenohack
		      dsksavep aaaaa errset lessorder greatorder indlist
		      $labels $aliases varlist mopl $props defaultf
		      $infolists $features featurel savefile $gradefs
		      $values $functions $arrays prinlength prinlevel
		      $contexts context $activecontexts)
	     (fixnum n $filesize $storenum $filenum)
	     (*lexpr $facts))


(setq filelist nil filelist1 nil $packagefile nil
      indlist (purcopy '(evfun evflag bindtest nonarray sp2 sp2subs opers 
			 special autoload assign mode)))

(defmspec $unstore (form) (i-$unstore (cdr form)))

(defmfun i-$unstore (x)
  (do ((x x (cdr x)) (list (ncons '(mlist simp))) (prop) (fl nil nil))
      ((null x) list)
    (setq x (infolstchk x))
    (when (and (boundp (car x)) (mfilep (setq prop (symbol-value (car x)))))
      (setq fl t)
      (set (car x) (eval (dskget (cadr prop) (caddr prop) 'value nil))))
    (do ((props (cdr (or (safe-get (car x) 'mprops) '(nil))) (cddr props))) ((null props))
      (cond ((mfilep (cadr props))
	     (setq fl t)
	     (cond ((memq (car props) '(hashar array))
		    (let ((aaaaa (gensym)))
		      (setq prop (dskget (cadadr props)
					 (caddr (cadr props))
					 (car props)
					 t))
		      (mputprop (car x)
				(if (eq prop 'aaaaa) aaaaa (car x))
				(car props))))
		   (t (setq prop (dskget (cadadr props) (caddr (cadr props))
					 (car props) nil))
		      (mputprop (car x) prop (car props)))))))
    (and fl (nconc list (ncons (car x))))))

(defun infolstchk (x)    
  ((lambda (iteml)
     (if (eq iteml t) x (append (or iteml '(nil)) (cdr x))))
   (cond ((not (and x (or (memq (car x) '($all $contexts))
			  (memq (car x) (cdr $infolists)))))
	  t)
	 ((eq (car x) '$all)
	  (infolstchk (append (cdr $infolists)
			      '($linenum $ratvars $weightlevels *ratweights
				tellratlist $dontfactor $features $contexts))))
	 ((eq (car x) '$labels) (reverse (cdr $labels)))
	 ((memq (car x) '($functions $macros $gradefs $dependencies))
	  (mapcar #'caar (cdr (symbol-value (car x)))))
	 ((eq (car x) '$contexts) (delq '$global (reverse (cdr $contexts)) 1))
	 (t (cdr (symbol-value (car x)))))))


(defun filelength (file)
  (file-length file))

(defmspec $save (form) (dsksetup (cdr form) nil nil '$save))


(defmfun i-$store (x) (dsksetup x t nil '$store))

(defmspec $fassave (form) (dsksetup (cdr form) nil t '$fassave))

(defvar *macsyma-extend-types-saved* nil)

#-(or cl nil)
(defun dsksetup (x storefl fasdumpfl fn)
  (let (#-cl(*nopoint t) prinlength prinlevel ofile file
	    list fasdeqlist fasdnoneqlist maxima-error #+pdp10 length #+pdp10 oint)
    #-franz
    (setq file (cond (($listp (car x)) (prog1 (filestrip (cdar x)) (setq x (cdr x))))
		     (t	;;Set OFILE to the last thing we wrote to.
		      #-cl (setq ofile (defaultf ()))
		      #+cl (setq ofile (file-expand-pathname ""))
		      ;;Cons up a new filename if none specified in
		      ;;SAVE or STORE command.
		      #+multics
		      (merror "First argument to ~:M must be a list.~
				 ~%~:M([/"myfile/"],all); is acceptable."
				 fn fn)
		      #-multics
		      (fullstrip (list $filename
				       (if dsksavep
					   (setq $storenum (f1+ $storenum))
					   (setq $filenum (f1+ $filenum)))
				       $device $direc)))))
    #+franz (setq file (filestrip x) x (cdr x))
    ;;Lisp Machine FILESTRIP returns a string.  Fix later.
    #+lispm (if (stringp file) (setq file (unexpand-pathname file)))
    (dolist (u x)
      (cond ((atom u) (if (not (symbolp u)) (improper-arg-err u fn)))
	    ((listargp u))
	    ((or (not (eq (caar u) 'mequal)) (not (symbolp (cadr u))))
	     (improper-arg-err u fn))))
    #-franz
    (if (and storefl (eq (cadr file) '>))
	(merror "> as second filename has not been implemented for `store'."))
    #+pdp10 (if storefl (setq oint (nointerrupt 'tty)))
    (cond (dsksavep (setq filelist (cons file filelist)))
	  (ofile (setq filelist1 (cons file filelist1))))
    ;;Create a stream to the file.  On ITS, use a hack to avoid repeated
    ;;creation of file arrays.
    #-franz
    (let ((temp-file #-multics`(,(carfile (cddr file)) |!SAVE!| output)
		     #+multics "macsyma.saved.output"))
      #+pdp10 (open (cnamef savefile temp-file)
		    (if fasdumpfl '(out fixnum block) '(out ascii)))
      #+cl (setq savefile (open temp-file :direction :output))
      #-(or cl pdp10) (setq savefile (open temp-file '(out ascii))))
    #+franz (setq savefile (outfile file))
    (let ((*print-base* 10.))
      #-cl(setq *nopoint nil)
      (when (null fasdumpfl)
	(princ ";;; -*- Mode: LISP; package:maxima; syntax:common-lisp; -*- Saved by " savefile)
	(princ (sys-user-id) savefile))
      #-(or franz cl multics) (fasprint t `(setq saveno ,savenohack))
      (setq list (ncons (if (symbolp file) file (mfile-out file)))
	    x (cons '$aliases x)
	    *macsyma-extend-types-saved* nil)
      (if (null (errset (dskstore x storefl file list))) (setq maxima-error t))
      (if (not (null *macsyma-extend-types-saved*))
	  (block nil
	    (if (null (errset
		       (dskstore (cons '&{ *macsyma-extend-types-saved*)
				 storefl file list)))
		(setq maxima-error t))
	    (setq *macsyma-extend-types-saved* nil)))
      #-cl(setq *nopoint t))
    (cond ((null (cdr list))
	   (delete-file savefile)
	   (if (not dsksavep)
	       (mtell "~M~%Nothing has been ~:Md.  ~:M attempt aborted."
		      (car list) fn fn))
	   (setq list '$aborted))
	  #-franz
	  (fasdumpfl (*fasdump savefile (nreverse fasdnoneqlist) (nreverse fasdeqlist) nil)
		     (renamef savefile file))
	  (t (terpri savefile) #-franz (renamef savefile file)))
    #+pdp10 (if storefl (nointerrupt oint))
    #-(or franz cl multics) (defaultf (if dsksavep ofile file))
    #+pdp10
    (when (not (atom list))
      (rplaca list (mtruename savefile))
      (setq length (filelength savefile))
      (when (> (cadr length) 30.)
	(mtell "~:M is ~A blocks big!" (car list) (cadr length))
	(cond ((> (cadr length) 60.)
	       (mtell "You probably want to zl-delete it."))
	      ((> (cadr length) 50.)
	       (mtell "Do you really want such a large file?")))))
    (if maxima-error (let ((errset 'errbreak1)) (merror "Error in ~:M attempt" fn)))
    ;;The CLOSE happens inside of RENAMEF on ITS.
    #-pdp10 (close savefile)
    (if (atom list) list
	`((mlist simp) ,(car list) #+pdp10 ,length . ,(cdr list))))) 

#+(or cl nil)
(defun dsksetup (x storefl fasdumpfl fn)
  (let (#-cl(*nopoint t) prinlength prinlevel ofile file (fname (nsubstring (print-invert-case (car x)) 1))
	    *print-gensym*
	    list fasdeqlist fasdnoneqlist maxima-error #+pdp10 length #+pdp10 oint)
    #+cl
    (setq savefile
      (if (or (eq $file_output_append '$true) (eq $file_output_append t))
        (open fname :direction :output :if-exists :append :if-does-not-exist :create)
        (open fname :direction :output :if-exists :supersede :if-does-not-exist :create)))
    #+nil
    (setq savefile (open ($filename_merge (car x)) :out))
    (setq file (list (car x)))
    (when (null fasdumpfl)
      (princ ";;; -*- Mode: LISP; package:maxima; syntax:common-lisp; -*- " savefile)
      (terpri savefile)
      (princ "(in-package :maxima)" savefile)
      )
    (dolist (u x)
      (cond ((atom u) (if (not (symbolp u)) (improper-arg-err u fn)))
	    ((listargp u))
	    ((or (not (eq (caar u) 'mequal)) (not (symbolp (cadr u))))
	     (improper-arg-err u fn))))
    (cond (dsksavep (setq filelist (cons file filelist)))
	  (ofile (setq filelist1 (cons file filelist1))))
    (setq list (ncons (car x)) x (cdr x) *macsyma-extend-types-saved* nil)
    (if (null (errset (dskstore x storefl file list))) (setq maxima-error t))
    (if (not (null *macsyma-extend-types-saved*))
	(block nil
	  (if (null (errset
		     (dskstore (cons '&{ *macsyma-extend-types-saved*)
			       storefl file list)))
	      (setq maxima-error t))
	  (setq *macsyma-extend-types-saved* nil)))
    (close savefile)
    (namestring savefile)))

(defun dskstore (x storefl file list)
  (do ((x x (cdr x)) (val) (rename) (item)
       (alrdystrd) (stfl storefl storefl) (nitemfl nil nil))
      ((null x))
    (cond ((setq val (listargp (car x)))
	   (setq x (nconc (getlabels (car val) (cdr val) nil) (cdr x))))
	  ((setq val (assq (car x) '(($inlabels . $inchar) ($outlabels . $outchar)
				     ($linelabels . $linechar))))
	   (setq x (nconc (getlabels* (eval (cdr val)) nil) (cdr x)))))
    (if (not (atom (car x)))
	(setq rename (cadar x) item (getopr (caddar x)))
	(setq x (infolstchk x) item (setq rename (and x (getopr (car x))))))
    (cond ((not (symbolp item))
	   (setq nitemfl item)
	   (setq item (let ((nitem (gensym))) (set nitem (meval item)) nitem)))
	  ((eq item '$ratweights) (setq item '*ratweights))
	  ((eq item '$tellrats) (setq item 'tellratlist)))
    (cond
      ((null x) (return nil))
      ((null (car x)))
      ((and (setq val (assq item alrdystrd)) (eq rename (cdr val))))
      ((null (setq alrdystrd (cons (cons item rename) alrdystrd))))
      ((and (or (not (boundp item))
		(and (eq item '$ratvars) (null varlist))
		(prog2 (setq val (symbol-value item))
		    (or (and (memq item '($weightlevels $dontfactor))
			     (null (cdr val)))
			(and (memq item '(tellratlist *ratweights)) (null val))
			(and (eq item '$features) (alike (cdr val) featurel))
			(and (eq item '$default_let_rule_package)
			     (eq item val))))
		(and (mfilep val)
		     (or dsksavep (not (unstorep item)) (null (setq stfl t)))))
	    (or (null (setq val (safe-get item 'mprops))) (equal val '(nil))
		(if (not dsksavep) (not (unstorep item))))
	    (not (getl item '(operators reversealias grad noun verb expr op data)))
	    (not (memq item (cdr $props)))
	    (or (not (memq item (cdr $contexts)))
		(not (eq item '$initial))
		(let ((context '$initial)) (null (cdr ($facts '$initial)))))))
      (t (when (and (boundp item) (not (mfilep (setq val (symbol-value item)))))
	   (if (eq item '$context) (setq x (list* nil val (cdr x))))
	   (dskatom item rename val)
	   (if (not (optionp rename)) (infostore item file 'value stfl rename)))
	 (when (setq val (and (memq item (cdr $aliases)) (get item 'reversealias)))
	   (dskdefprop rename val 'reversealias)
	   (pradd2lnc rename '$aliases)
	   (dskdefprop (makealias val) rename 'alias)
	   (and greatorder (not (assq 'greatorder alrdystrd))
		(setq x (list* nil 'greatorder (cdr x))))
	   (and lessorder (not (assq 'lessorder alrdystrd))
		(setq x (list* nil 'lessorder (cdr x))))
	   (setq x (list* nil (makealias val) (cdr x))))
	 (cond ((setq val (get item 'noun))
		(setq x (list* nil val (cdr x)))
		(dskdefprop rename val 'noun))
	       ((setq val (get item 'verb))
		(setq x (list* nil val (cdr x)))
		(dskdefprop rename val 'verb)))
	 (when (mget item '$rule)
	   (if (setq val (ruleof item))
	       (setq x (list* nil val (cdr x))))
	   (pradd2lnc (getop rename) '$rules))
	 (when (and (setq val (cadr (getl-fun item '(expr))))
		    (or (mget item '$rule) (get item 'translated)))
	   #-franz
	   (if (mget item 'trace)
	       (let (val1 #+pdp10 (oint (nointerrupt 'tty)))
		 (remprop item 'expr)
		 (if (setq val1 (get item 'expr))
		     (dskdefprop rename val1 'expr))
		 (setplist item (list* 'expr val (symbol-plist item)))
		 #+pdp10 (nointerrupt oint))
	       (dskdefprop rename val 'expr))
	   #+franz (fasprin `(def ,rename ,(getd item)))
	   (if (setq val (args item))
	       (fasprin `(args (quote ,rename) (quote ,val))))
	   (propschk item rename 'translated))
	 ;; 	  (WHEN (AND (SETQ VAL (GETL ITEM '(A-EXPR FEXPR TRANSLATED-MMACRO))) 
	 ;; 		     (GET ITEM 'TRANSLATED))
	 ;; 		(DSKDEFPROP RENAME (CADR VAL) (CAR VAL))
	 ;; 		(PROPSCHK ITEM RENAME 'TRANSLATED))
	 (when (setq val (get item 'operators))
	   (dskdefprop rename val 'operators)
	   (when (setq val (get item 'rules))
	     (dskdefprop rename val 'rules)
	     (setq x (cons nil (append val (cdr x)))))
	   (if (memq item (cdr $props)) (pradd2lnc rename '$props))
	   (setq val (mget item 'oldrules))
	   (and val (setq x (cons nil (nconc (cdr (reverse val)) (cdr x))))))
	 (if (memq item (cdr $features)) (pradd2lnc rename '$features))
	 (when (memq (getop item) (cdr $props))
	   (dolist (ind indlist) (propschk item rename ind))
	   (when (get (setq val (stripdollar item)) 'alphabet)
	     (dskdefprop val t 'alphabet)
	     (pradd2lnc (getcharn val 1) 'alphabet)
	     (pradd2lnc item '$props))
	   (dolist (oper opers) (propschk item rename oper)))
	 (when (and (setq val (get item 'op)) (memq val (cdr $props)))
	   (dskdefprop item val 'op)
	   (dskdefprop val item 'opr)
	   (pradd2lnc val '$props)
	   (if (setq val (extopchk item val))
	       (setq x (list* nil val (cdr x)))))
	 (when (and (setq val (get item 'grad)) (zl-assoc (ncons item) $gradefs))
	   (dskdefprop rename val 'grad)
	   (pradd2lnc (cons (ncons rename) (car val)) '$gradefs))
	 (when (and (get item 'data)
		    (not (memq item (cdr $contexts)))
		    (setq val (cdr ($facts item))))
	   (fasprin `(restore-facts (quote ,val)))
	   (if (memq item (cdr $props)) (pradd2lnc item '$props)))
	 (when (and (memq item (cdr $contexts))
		    (let ((context item)) (setq val (cdr ($facts item)))))
	   (fasprint t `(dsksetq $context (quote ,item)))
	   (if (memq item (cdr $activecontexts))
	       (fasprint t `($activate (quote ,item))))
	   (fasprint t `(restore-facts (quote ,val))))
	 (mpropschk item rename file stfl)
	 (if (not (get item 'verb))
	     (nconc list (ncons (or nitemfl (getop item)))))))))

(defun dskatom (item rename val)
  (cond ((eq item '$ratvars)
	 (fasprint t `(setq varlist (append varlist (quote ,varlist))))
	 (fasprint t '(setq $ratvars (cons '(mlist simp) varlist)))
	 (pradd2lnc '$ratvars '$myoptions))
	((memq item '($weightlevels $dontfactor))
	 (fasprin `(setq ,item (nconc (quote ,val) (cdr ,item))))
	 (pradd2lnc item '$myoptions))
	((eq item 'tellratlist)
	 (fasprin `(setq tellratlist (nconc (quote ,val) tellratlist)))
	 (pradd2lnc 'tellratlist '$myoptions))
	((eq item '*ratweights)
	 (fasprin `(apply (function $ratweight) (quote ,(dot2l val)))))
	((eq item '$features)
	 (dolist (var (cdr $features))
	   (if (not (memq var featurel)) (pradd2lnc var '$features))))
	((and (eq item '$linenum) (eq item rename))
	 (fasprint t `(setq $linenum ,val)))
	((not ($ratp val))
	 (fasprint t (list 'dsksetq rename
			   (if (or (numberp val) (memq val '(nil t)))
			       val
			       (list 'quote val)))))
	(t (fasprint t `(dsksetq ,rename (dskrat (quote ,val)))))))

(defun mpropschk (item rename file stfl)
  (do ((props (cdr (or (get item 'mprops) '(nil))) (cddr props)) (val))
      ((null props))
    (cond ((or (memq (car props) '(trace trace-type trace-level trace-oldfun))
	       (mfilep (setq val (cadr props)))
	       (and (eq (car props) 't-mfexpr) (not (get item 'translated)))))
	  ((not (memq (car props) '(hashar array)))
	   (fasprin (list 'mdefprop rename val (car props)))
	   (if (not (memq (car props) '(mlexprp mfexprp t-mfexpr)))
	       (infostore item file (car props) stfl
			  (cond ((memq (car props) '(mexpr mmacro))
				 (let ((val1 (args item)))
				   (if val1 (fasprin `(args (quote ,rename)
						       (quote ,val1)))))
				 (let ((val1 (get item 'function-mode)))
				   (if val1 (dskdefprop rename
							val1
							'function-mode)))
				 (cons (ncons rename) (cdadr val)))
				((eq (car props) 'depends)
				 (cons (ncons rename) val))
				(t rename)))))
	  (t (dskary item (list 'quote rename) val (car props))
	     (infostore item file (car props) stfl rename)))))

(defun dskary (item rename val ind)
					; Some small forms ordinarily non-EQ for fasdump must be output 
					; in proper sequence with the big mungeables.
					; For this reason only they are output as EQ-forms.
  (let ((ary (cond ((and (eq ind 'array) (get item 'array)) rename)
					; This code handles "complete" arrays.
		   (t (fasprint t '(setq aaaaa (gensym))) 'aaaaa)))
	(dims (arraydims val))
	val1)
    (if (eq ind 'hashar) (fasprint t `(remcompary ,rename)))
    (fasprint t `(mremprop ,rename (quote ,(if (eq ind 'array) 'hashar 'array))))
    (fasprint t `(mputprop ,rename ,ary (quote ,ind)))
    (fasprint t `(*array ,ary (quote ,(car dims)) ,.(cdr dims)))
    (fasprint t `(fillarray ,ary (quote ,(listarray val))))
    (if (setq val1 (get item 'array-mode))
	(fasprint t `(defprop ,(cadr rename) ,val1 array-mode)))))

(defun extopchk (item val)
  (let ((val1 (implode (cons #\$ (cdr (exploden val))))))
    (when (or (get val1 'nud) (get val1 'led) (get val1 'lbp))
      (fasprin `(define-symbol (quote ,val)))
      (if (memq val mopl)
	  (fasprin `(setq mopl (cons (quote ,val) mopl))))
      (when (setq val (get val1 'dimension))
	(dskdefprop val1 val 'dimension)
	(dskdefprop val1 (get val1 'dissym) 'dissym)
	(dskdefprop val1 (get val1 'grind) 'grind))
      (if (setq val (get val1 'lbp)) (dskdefprop val1 val 'lbp))
      (if (setq val (get val1 'rbp)) (dskdefprop val1 val 'rbp))
      (if (setq val (get val1 'nud)) (dskdefprop val1 val 'nud))
      (if (setq val (get val1 'led)) (dskdefprop val1 val 'led))
      (when (setq val (get val1 'verb))
	(dskdefprop val (get val 'dimension) 'dimension)
	(dskdefprop val (get val 'dissym) 'dissym))
      (when (setq val (get item 'match))
	(dskdefprop item val 'match) val))))

(defun propschk (item rename ind)
  (let ((val (get item ind)))
    (when val (dskdefprop rename val ind)
	  (pradd2lnc (getop rename) '$props))))

(defun fasprin (form) (fasprint nil form))

(defun fasprint (eqfl form)
  (cond ((null fasdumpfl) #-franz (print form savefile)
	 #+franz (pp-form form savefile))
	(eqfl (setq fasdeqlist (cons form fasdeqlist)))
	(t (setq fasdnoneqlist (cons form fasdnoneqlist)))))

(defun unstorep (item) (i-$unstore (ncons item)))

(defun infostore (item file flag storefl rename)
  (let ((prop (cond ((eq flag 'value)
		     (if (memq rename (cdr $labels)) '$labels '$values))
		    ((eq flag 'mexpr) '$functions)
		    ((eq flag 'mmacro) '$macros)
		    ((memq flag '(array hashar)) '$arrays)
		    ((eq flag 'depends) (setq storefl nil) '$dependencies)
		    (t (setq storefl nil) '$props))))
    (cond ((eq prop '$labels)
	   (fasprin `(addlabel (quote ,rename)))
	   (if (get item 'nodisp) (dskdefprop rename t 'nodisp)))
	  (t (pradd2lnc rename prop)))
    (cond (storefl
	   (cond ((memq flag '(mexpr mmacro)) (setq rename (caar rename)))
		 ((eq flag 'array) (remcompary item)))
	   (setq prop (list '(mfile) file rename))
	   (cond ((eq flag 'value) (set item prop))
		 ((memq flag '(mexpr mmacro aexpr array hashar))
		  (mputprop item prop flag)))))))

(defun pradd2lnc (item prop)
  (if (or (null $packagefile) (not (memq prop (cdr $infolists)))
	  (and (eq prop '$props) (get item 'opr)))
      (fasprin `(add2lnc (quote ,item) ,prop))))

(defun dskdefprop (name val ind)
  (fasprin (if (and (memq ind '(expr fexpr macro)) (eq (car val) 'lambda))
	       (list* 'defun name
		      (if (eq ind 'expr) (cdr val) (cons ind (cdr val))))
	       (list 'defprop name val ind))))

(defun dskget (file name flag unstorep)
  (let ((defaultf defaultf) (eof (list nil)) item #-cl(*nopoint t))
    (setq file (open file #-cl '(in ascii)))
    (setq item (do ((item (read file eof) (read file eof)))
		   ((eq item eof) (merror "~%~:M not found" name))
		 (if (or (and (not (atom item)) (eq (car item) 'dsksetq)
			      (eq flag 'value) (eq (cadr item) name))
			 (and (not (atom item)) (= (length item) 4)
			      (or (eq (cadddr item) flag)
				  (and (eq (car (cadddr item)) 'quote)
				       (eq (cadr (cadddr item)) flag)))
			      (or (eq (cadr item) name)
				  (and (eq (caadr item) 'quote)
				       (eq (cadadr item) name)))))
		     (return item))))
    (when unstorep (eval (read file)) (eval (read file)))
    (close file)
    (caddr item)))

(defun dsksave nil
  (let ((dsksavep t))
    (if $dskall (i-$store '($labels $values $functions $macros $arrays))
	(i-$store '($labels)))))

;;(DEFMSPEC $REMFILE (L) (SETQ L (CDR L))
;;  (IF (AND L (OR (CDR L) (NOT (MEMQ (CAR L) '($ALL $TRUE T)))))
;;      (IMPROPER-ARG-ERR L '$REMFILE))
;;  (DOLIST (FILE (IF L (APPEND FILELIST1 FILELIST) FILELIST))
;;    (ERRSET (DELETEF FILE) NIL)
;;    (SETQ FILELIST (zl-DELETE FILE FILELIST 1))
;;    (SETQ FILELIST1 (zl-DELETE FILE FILELIST1 1)))
;;  '$DONE)

(defmspec $restore (file) (setq file (cdr file))
	  (let ((eof (ncons nil)) (in (open (filestrip file)#-cl '(in ascii))))
	    (setq file (truename in))
	    (setq file (if (atom file) file (append (cdr file) (car file))))
	    (do ((item (read in eof) (read in eof))) ((eq item eof))
	      (cond ((and (eq (car item) 'dsksetq) (not (optionp (cadr item))))
		     (set (cadr item) (list '(mfile) file (cadr item))))
		    ((and (eq (car item) 'mdefprop)
			  (memq (cadddr item) '(mexpr mmacro aexpr)))
		     (mputprop (cadr item)
			       (list '(mfile) file (cadr item))
			       (cadddr item)))
		    ((and (eq (car item) 'mputprop)
			  (memq (cadr (cadddr item)) '(array hashar)))
		     (mputprop (cadadr item)
			       (list '(mfile) file (cadadr item))
			       (cadr (cadddr item)))
		     (do ((item (read in) (read in))) (nil)
		       (if (eq (car item) 'add2lnc) (return (eval item)))))
		    (t (eval item))))
	    (close in)
	    (if (atom file) file (mfile-out file))))

