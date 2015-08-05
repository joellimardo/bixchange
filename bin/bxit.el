;Most of the functions in this file were TOTALLY copied from other emacs
;files located around the net(all GNU GPL though). Thanks to all contributors.
;$Id: bxit.el,v 1.1 2007/07/20 00:25:29 joellimardo Exp $

(setq this-dir "c:/WebServ/wwwroot/cgi-bin/bixchange")

(defun bxit-new-ini (topic)
   "create a new INI file"
    (interactive "sPlease enter new INI file name: ")
    ; open the file
    (find-file (concat this-dir "/data/harbor/"  topic ".ini"))
    ;set the cursor and stuff
    (insert (concat "#<!-- This INI file created for BixChange -->\n"
                   "[GENERAL]\nPAGETYPE=\nREFRESHSPEED=\n"
                   "META-DESCRIPTION=\nMETA-STARTLINK=\nMETA-NAME=\nMETA-KEYWORDS=\nMETA-ICON=\n"
                    ))
    (beginning-of-buffer)
    (forward-char 5)
 )


(defun read-line-from-buffer (line-number)

"Returns the contents of current buffer at argument `line-number' as a string."

  (end-of-buffer)
  (setq total-lines (count-lines 1 (point)))
   (if (and (> line-number 0) (<= line-number total-lines))
      (progn
	(goto-line line-number)
	(beginning-of-line)
	(setq beg (point))
	(end-of-line)
	(setq end (point))
	(buffer-substring beg end))
    )
  )

;; This on is mine

(defun load-these-buffers (datFile)
  (interactive "sPlease enter the package .DAT name: ")
(progn
  (find-file-read-only (concat this-dir "/" datFile ".dat"))
  (end-of-buffer)
  (setq no-of-lines (point))
  (beginning-of-buffer)
  (setq cnt 1)
  (goto-line 1)
  (while (<= cnt no-of-lines)
    (find-file-other-window (concat this-dir (read-line-from-buffer cnt)))
    (switch-to-buffer (concat datFile ".dat"))
    (setq cnt (+ cnt 1))
    (goto-line cnt)
  )
)
)

(defun go-here (dummy)
 (interactive "sClick OK")
(progn
  (end-of-line)
  (setq endl (point))
  (search-backward "/")
  (setq strt (+ (point) 1))
 (switch-to-buffer-other-window (buffer-substring strt endl)))
)


(global-set-key "\C-c\C-bn" 'bxit-new-ini)
(global-set-key "\C-c\C-br" 'load-these-buffers)
(global-set-key "\C-c\C-bg" 'go-here)