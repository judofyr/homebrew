require 'formula'

class Mercury < Formula
  url 'http://www.mercury.csse.unimelb.edu.au/download/files/mercury-compiler-11.01.tar.gz'
  homepage 'http://www.mercury.csse.unimelb.edu.au/'
  md5 '5d7dc00ab06f87ee5ddfb8dca088be56'

  GRADES = %w[java csharp erlang] unless defined?(GRADES)

  def current_grades
    GRADES.each do |grade|
      yield grade if ARGV.include?("--#{grade}")
    end
  end

  def options
    [
      ['--minimal', 'Minimal build'],
      ['--java', 'Enable Java grade'],
      ['--csharp', 'Enable C# grade'],
      ['--erlang', 'Enable Erlang grade']
    ]
  end
  
  def install
    # If we're reinstalling, some files in prefix are not writable
    # by the owner.  In order for installation to succseed, we
    # need to run chmod.
    system "chmod", "-R", "u+w", prefix if prefix.exist?
    
    configure_args = ["--prefix=#{prefix}"]

    if ARGV.include?('--minimal')
      configure_args << "--disable-most-grades"
    end

    current_grades do |grade|
      configure_args << "--enable-#{grade}-grade"
    end

    system "./configure", *configure_args

    # Verify that the current grades will actually be installed.
    libgrades = `grep LIBGRADES config.log`[/'([^']+)/, 1].split(" ")
    current_grades do |grade|
      if !libgrades.include?(grade)
        onoe "Can't enable --#{grade}. Are you sure it's installed?"
      end
    end

    # Install!
    system "make"
    system "make install"

    # Install man- and info-pages to the right place.
    man.parent.mkpath
    (prefix + 'man').rename(man)
    info.parent.mkpath
    (prefix + 'info').rename(info)
  end

  def patches
    # These two patches are only needed to get Mercury compiling
    # with GCC-LLVM 4.2. They're both type-related issues.
    DATA
  end
end
__END__
diff --git a/boehm_gc/libatomic_ops/src/atomic_ops/sysdeps/gcc/x86_64.h b/boehm_gc/libatomic_ops/src/atomic_ops/sysdeps/gcc/x86_64.h
index 78a4a0f..5dc57d6 100644
--- a/boehm_gc/libatomic_ops/src/atomic_ops/sysdeps/gcc/x86_64.h
+++ b/boehm_gc/libatomic_ops/src/atomic_ops/sysdeps/gcc/x86_64.h
@@ -119,7 +119,7 @@ AO_test_and_set_full(volatile AO_TS_t *addr)
   /* Note: the "xchg" instruction does not need a "lock" prefix */
   __asm__ __volatile__("xchgb %0, %1"
                 : "=q"(oldval), "=m"(*addr)
-                : "0"(0xff), "m"(*addr) : "memory");
+                : "0"((unsigned char)0xff), "m"(*addr) : "memory");
   return (AO_TS_VAL_t)oldval;
 }
 
diff --git a/runtime/mercury_tags.h b/runtime/mercury_tags.h
index 94907a9..b824859 100644
--- a/runtime/mercury_tags.h
+++ b/runtime/mercury_tags.h
@@ -68,7 +68,7 @@
 ** const and the LHS is not declared const.
 */
 
-#define	MR_mkword(t, p)			((MR_Word *)((char *)(p) + (t)))
+#define	MR_mkword(t, p)			((MR_Word *)((MR_Word)(p) + (t)))
 #define	MR_tmkword(t, p)		(MR_mkword(MR_mktag(t), p))
 #define	MR_tbmkword(t, p)		(MR_mkword(MR_mktag(t), MR_mkbody(p)))
 
