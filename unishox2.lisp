;; git clone https://github.com/siara-cc/Unishox2.git
;; clang -dynamiclib -o unishox2.dylib unishox2.c -I ./

(uiop::define-package  :unishox2
    (:use :cl :cffi)
  (:export #:compress-string #:uncompress))

(in-package :unishox2)

(defvar *library* (cffi::load-foreign-library-path  "unishox2" (namestring (asdf/system::system-relative-pathname :unishox2 "unishox2.dylib"))))

;; int unishox2_compress_simple(const char *in, int len, char *out);
;; int unishox2_decompress_simple(const char *in, int len, char *out);

;; Compress a string to an unsigned byte vector
(defun compress (string)
  (with-foreign-pointer (compressed (length string) nil)
    (with-foreign-string (str string)
      (let ((compressed-length (foreign-funcall "unishox2_compress_simple" :string str :int (length string) :pointer compressed :int)))
          (loop with res = (make-array compressed-length :element-type '(unsigned-byte 8))
                for i below compressed-length
                do (setf (aref res i) (mem-aref compressed :unsigned-char i))
                finally (return res))
        ))))

;; Uncompress a compressed string as unsigned byte vector to a string 
(defun uncompress (vector)
  (with-foreign-pointer (compressed (length vector) nil)
    (with-foreign-pointer (uncompressed (* (length vector) 20) nil) ;; this is unsafe. How do we know how much to allocate?
      (loop for i below (length vector)
            do (setf (mem-aref compressed :uint8 i) (aref vector i)))
      (let ((uncompressed-length 
              (foreign-funcall "unishox2_decompress_simple"
                               :pointer compressed
                               :int (length vector)
                               :pointer uncompressed
                               :int)))
        (foreign-string-to-lisp uncompressed :count uncompressed-length)))))

;(unishox2:uncompress (unishox2:compress-string "http://example.com/foobar.html"))
