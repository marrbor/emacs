;;--------------------------------------------------------------------------
;; ins-ref.el (Version 1.02)
;;--------------------------------------------------------------------------
;; ����:
;;   �ޡ������줿�꤫�饫������Τ���ԤޤǤδ֤ιԤ���Ƭ��ʸ�����
;;   ����� emacs-lisp �ץ����Ǥ����᡼��� GUNS �ΰ��ѵ����
;;   ���������ꡢlisp �� C++ �Υ����ȥ����Ȥ���Τ˻��ѤǤ��ޤ��� 
;;
;; ��.emacs�פ�����:
;;    (setq load-path (cons ("�ץ������־��") load-path))
;;    (load "ins-ref")
;; 
;; �Ȥ���:
;;    [Ctrl]+[c][j] : �ޡ�����Ĥ����Ȥ����鸽�ߤΥ���������֤ޤǤ�
;;                    �Ԥ���Ƭ�˰��ѵ���(�ǥե���Ȥ�" | ")���������ޤ���
;;    [Ctrl]+[c][i] : �ޡ�����Ĥ����Ȥ����鸽�ߤΥ���������֤ޤǤ�
;;                    �Ԥ���Ƭ�˻����ʸ������������ޤ���
;;    [Ctrl]+[c][d] : �ޡ�����Ĥ����Ȥ����鸽�ߤΥ���������֤ޤǤ�
;;                    ����ΰ�������ޤ���
;;    �� [Ctrl]+[c][j] �ϥ���ȥ��륭���򲡤��ʤ��� c ��
;;       ���������Ȥˡ�j �Τߤ򲡤����Ȥ򼨤��Ƥ��ޤ���
;; 
;; ��:
;;   [����]
;;     +---------------+    ��G�פΤȤ����           +---------------+ 
;;     |ABCDEF         |    [Ctrl]+[space] ��         |ABCDEF         |
;;     |GHIJKL         |    �����ƥޡ�����Ĥ���      |// GHIJKL      |
;;     |MNOPQR         | �� ����������S�פ�      �� |// MNOPQR      |
;;     |STUVWX         |    ��ư��[Ctrl]+[c][i]��     |// STUVWX      |
;;     |YZ             |    ������// �פ����Ϥ��롣   |YZ             |
;;     +---------------+    GUI�δĶ��Ǥϡ���G��      +---------------+
;;                          �����S�פޤǤ�ɥ�å�
;;                          �������Ȥ�[Ctrl]+[c][i]
;;                          �Ǥ��ǽ�Ǥ���
;;
;;   [���]
;;     +---------------+    ��G�פιԤι�Ƭ��         +---------------+ 
;;     |ABCDEF         |    [Ctrl]+[space] ��         |ABCDEF         |
;;     |// GHIJKL      |    �����ƥޡ�����Ĥ���      |GHIJKL         |
;;     |// MNOPQR      | �� ����������S�פ�      �� |MNOPQR         |
;;     |// STUVWX      |    ��ư��[Ctrl]+[c][d]��     |STUVWX         |
;;     |YZ             |    ������                    |YZ             |
;;     +---------------+    GUI�δĶ��Ǥϡ���G�פ�    +---------------+
;;                          ��Ƭ�Ρ�/�פ����S��
;;                          �ޤǤ�ɥ�å��������Ȥ�
;;                          [Ctrl]+[c][d]�Ǥ��ǽ�Ǥ���
;;
;;--------------------------------------------------------------------------
;;                             Copyright (C) 1994-2001 TSURUTA Mitsutoshi
;;--------------------------------------------------------------------------

;;  ����������
(defun ins-ref-str (ref-str)
  "�Ԥ�Ƭ�ˡ����ѵ���򤤤�롣"
  (interactive "sinsert string : ")
  (if (> (mark) (point)) (exchange-point-and-mark))
  (save-excursion
    (goto-char (mark))
    (beginning-of-line)
    (setq top_pos (point)))
  (beginning-of-line)
  (while (< top_pos (point))
    (insert ref-str)
    (previous-line 1)
    (beginning-of-line))
  (insert ref-str)
)

;;  ����ʸ���������뤫���䤤��碌�ʤ��Ǽ¹Ԥ��롣
;;        (ins-ref-str ....) �� ʸ������ʬ��񤭴������
;;        ����ʸ�������������褦�ˤʤ�ޤ���
(defun ins-ref ()
  "����ʸ���������뤫���䤤��碌�ʤ��ǹԤ�Ƭ�ˡ����ѵ���򤤤�롣"
  (interactive)
  (ins-ref-str "  | ")
)

;; ������
(defun del-ref ()
  "����ΰ�������롣"
  (interactive)
  (kill-rectangle (mark) (point))
)

;;  �����γ������
;;(global-set-key "\C-cj" 'ins-ref)
(global-set-key "\C-ci" 'ins-ref-str)
(global-set-key "\C-cd" 'del-ref)


;;----------------------------------------------------------------------
;; �ʲ��ϡ�gnus �ѤǤ���ɬ�פʤ����Ϻ�����Ƥ�����פǤ���
;;----------------------------------------------------------------------
;;  �˥塼���Υե����򤹤���λ��ȵ����������դ��ä���
;
;  news-reply-yank-message-id : �˥塼���Υ�å�����ID
;  news-reply-yank-from : ���Υ˥塼������Ƥ�����
;
(defvar news-reply-header-hook
  '(lambda () (insert news-reply-yank-from " ���� wrote : \n\n"))
  "�˥塼���Υե����򤹤���λ��ȵ����������դ��ä���")
;(defvar news-reply-header-hook
;  '(lambda () (insert (mail-fetch-field "date") " ����\n"
;                      news-reply-yank-from " ����Ͻ񤭤ޤ��� \n\n"))
;  "�˥塼���Υե����򤹤���λ��ȵ����������դ��ä���")

;;  �˥塼����sendmail�Υե����򤹤���λ��ȵ�����
;;  �������륹�ڡ����ο�������ʥǥե���Ȥϣ��Ǥ�����
(defvar mail-indentation-spaces 0 
    "�ե����򤹤���λ��ȵ������������륹�ڡ����ο�")

;;  rnewspost �� �ȤäƤ���ͤ褦������Ǥ�
;;
(setq news-reply-mode-hook
      '(lambda ()
         (defun news-reply-yank-original (arg)
           "�˥塼���Υե����򤹤���λ��ȵ���������"
           (interactive "P")
           (mail-yank-original mail-indentation-spaces)
           (exchange-point-and-mark)
           (run-hooks 'news-reply-header-hook))))
