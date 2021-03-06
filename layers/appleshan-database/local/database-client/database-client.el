;;; database-client.el --- Setup Emacs as an SQL Database client
;;; -*- coding: utf-8 -*-

;;; Commentary:

;; @see https://truongtx.me/2014/08/23/setup-emacs-as-an-sql-database-client
;; @see https://github.com/tmtxt/.emacs.d/blob/master/config/tmtxt-sql.el

;;; Code:


;; (require 'sql)

;;; hooks
(add-hook 'sql-interactive-mode-hook
          (lambda ()
            (toggle-truncate-lines t)
            (setq-local show-trailing-whitespace nil)
            ;; (auto-complete-mode t) ;; TODO
            ))

(add-hook 'sql-mode-hook
          (lambda ()
            (setq-local ac-ignore-case t)
            (auto-complete-mode)))

(defun dbclient/sql-connect-server (connection)
  "Connect to the input server using sql-connection-alist"
  (interactive
    (helm-comp-read "Select server: " (mapcar (lambda (item)
                                                (list
                                                  (symbol-name (nth 0 item))
                                                  (nth 0 item)))
                                              sql-connection-alist)))
  (require 'my-password "./database-password.el.gpg")
  ;; get the sql connection info and product from the sql-connection-alist
  (let* ((connection-info (assoc connection sql-connection-alist))
         (connection-product (nth 1 (nth 1 (assoc 'sql-product connection-info))))
         (sql-password (nth 1 (assoc connection my-sql-password))))
    ;; delete the connection info from the sql-connection-alist
    (setq sql-connection-alist (assq-delete-all connection sql-connection-alist))
    ;; delete the old password from the connection-info
    (setq connection-info (assq-delete-all 'sql-password connection-info))
    ;; add the password to the connection-info
    (nconc connection-info `((sql-password ,sql-password)))
    ;; add back the connection info to the beginning of sql-connection-alist
    ;; (last used server will appear first for the next prompt)
    (add-to-list 'sql-connection-alist connection-info)
    ;; override the sql-product by the product of this connection
    (setq sql-product connection-product)
    ;; connect
    (if current-prefix-arg
        (sql-connect connection connection)
      (sql-connect connection))))


(provide 'database-client)

;;; database-client.el ends here
