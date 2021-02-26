# Writing faster code

These notes cover some basics about the two principal aspects of
speeding up your code:

1. basic tools for identifying bottlenecks and
2. some tips for how to actually speed up the code.

I'm not an expert at either of these and will only cover basics
because that's all I know myself.

This posts has some snippets entered at the command line, which I
indicate with a `$` as in
```
$ echo hello
hello
```
and some code entered into an IPython console, which I indicate
with the default prompt `In [x]:` as in
```
In [1]: print('hello')
hello
```

## Context

Before we start, it's worth bearing in mind the particular context I'm assuming
and what that implies.  I'll discuss ...

### ... scientific code ...

I'm assuming that we're talking about codes that either analyse or
generate data, usually by doing lots of numerical work on data
organised and stored in tables, arrays or matrices.

I also assume that we're optimising for speed, i.e. we're trying to
reduce runtime.  Under different circumstances, you might try to
optimise e.g. RAM usage, number of I/O operations or network usage.
Optimising one metric might or might not help another.

Though most of us do, it's worth saying that I also assume we're
talking about standard laptop/desktop/cluster hardware, which might
also affect what code is faster or slower.  In case this point isn't
clear, consider a program that is overflowing RAM and starting to use
a swap file on the hard disk.  You'll see different bottlenecks if you
have an SSD compared with an optical disk.

### ... in Python scripts ...

I know many people use
Jupyter notebooks, for which I'm sure there are profiling tools that I
don't know about.  But you can always copy the code you want to
optimise into a Python script.

I'll also say a little bit about compiled code and a few command line
tools.

### ... that already works correctly.

There is no point optimising code that doesn't already produce the
correct result.  Put differently, it's trivially easy to write [very
fast code that produces garbage](https://xkcd.com/221/). e.g.

```python
def randint():
    return 4
```

More importantly, you don't want to break your code by speeding it up.
The best way to avoid this is to have unit tests that cover most
(ideally all) of the code and run regularly (ideally automatically).

## Profiling

Before you start trying to make your code faster, you need to know
what part is slow.  Even if you speed things up by a factor of 100 in
a part of the code that contributes 1% to the runtime, you'll still
only reduce the overall runtime by 0.99%.

But that does *not* mean you shouldn't try to find what is dominating
the runtime, speed that up and, having done so, profile again to find
the next bottleneck.

Also, remember to try profiling your code on varying amounts of data.
You might find different bottlenecks on an array of 10⁴ elements as an
array of 10⁸ elements.  Generally, try to profile as realistic run as
you can afford time.

### Simple tools

There are a few simple tools that tell you how long a given
snippet of Python takes to run.  IPython provides the magic functions
`%time` and `%timeit`, which use the
[`timeit`](https://docs.python.org/3/library/timeit.html)
module from the standard
library.  `%time` on its own just tells you how long a single line of code
takes to run. e.g.
```
In [1]: %time x = [i**2.2 for i in range(10_000_000) if i%3==1]
CPU times: user 920 ms, sys: 42.6 ms, total: 962 ms
Wall time: 957 ms
```

`%timeit` will instead run the snippet of code a number of times to
give a mean and standard deviation. e.g.

```
In [2]: %timeit x = [i**2.2 for i in range(10_000_000) if i%3==1]
931 ms ± 3.33 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
```

`%timeit` decides how many times to run the code based on
how long it takes.

At the command line, we can use `time <command>` to see
how long `<command>` takes. e.g.

```
$ time sleep 1

real    0m1.003s
user    0m0.000s
sys     0m0.003s
```

which is what we expect because `sleep <n>` simply does nothing for
`n` seconds.

### cProfile

[cProfile](https://docs.python.org/3/library/profile.html)
is a simple and standard profiler whose main advantage is
that it's part of Python's standard library.  If you have Python, you
have cProfile.

Consider this very simple script called `script.py`:
```python
#!/usr/bin/env python3

import numpy as np

A = np.random.rand(2000,1000)
b = np.random.rand(2000)
Ainv = np.linalg.pinv(A)
x = Ainv.dot(b)
```
We run cProfile on it with
```
$ python3 -m cProfile script.py
         76569 function calls (74416 primitive calls) in 0.837 seconds

   Ordered by: standard name

   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1    0.000    0.000    0.000    0.000 <__array_function__ internals>:2(<module>)
        1    0.000    0.000    0.000    0.000 <__array_function__ internals>:2(amax)
        1    0.000    0.000    0.000    0.000 <__array_function__ internals>:2(concatenate)
        1    0.000    0.000    0.000    0.000 <__array_function__ internals>:2(copyto)
        1    0.000    0.000    0.711    0.711 <__array_function__ internals>:2(pinv)
        1    0.000    0.000    0.670    0.670 <__array_function__ internals>:2(svd)
        2    0.000    0.000    0.000    0.000 <__array_function__ internals>:2(swapaxes)
    150/1    0.001    0.000    0.109    0.109 <frozen importlib._bootstrap>:1002(_find_and_load)
   178/15    0.000    0.000    0.106    0.007 <frozen importlib._bootstrap>:1033(_handle_fromlist)
      448    0.001    0.000    0.001    0.000 <frozen importlib._bootstrap>:112(release)
      150    0.000    0.000    0.000    0.000 <frozen importlib._bootstrap>:152(__init__)
      150    0.000    0.000    0.001    0.000 <frozen importlib._bootstrap>:156(__enter__)
      150    0.000    0.000    0.001    0.000 <frozen importlib._bootstrap>:160(__exit__)
      448    0.001    0.000    0.001    0.000 <frozen importlib._bootstrap>:166(_get_module_lock)
      227    0.000    0.000    0.000    0.000 <frozen importlib._bootstrap>:185(cb)
...
```

where I've only showed the first 20 lines of output.  So, what does
this say?  Each row gives the following information about calls to a
specific function:

* `ncalls`: the number of calls to that function,
* `tottime`: the number of seconds spent in that function but *not* the functions it called,
* `cumtime`: the number of seconds spent in that function *including* the functions it called,
* `percall`: `tottime` or `cumtime` divided by `ncalls`, and
* `filename:lineno(function)`: the name of the function and which line it occurs on in the given source file.

By default, the function calls are sorted alphabetically by name,
which usually isn't what we want.  To sort by a different key, you can
pass the `-s <column name>` flag to cProfile. e.g.

```
$ python3 -m cProfile -s tottime script.py
         76569 function calls (74416 primitive calls) in 0.903 seconds

   Ordered by: internal time

   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1    0.738    0.738    0.738    0.738 linalg.py:1482(svd)
        1    0.038    0.038    0.776    0.776 linalg.py:1915(pinv)
      320    0.020    0.000    0.020    0.000 {built-in method builtins.compile}
        2    0.016    0.008    0.016    0.008 {method 'rand' of 'numpy.random.mtrand.RandomState' objects}
      107    0.011    0.000    0.011    0.000 {built-in method marshal.loads}
    31/29    0.009    0.000    0.011    0.000 {built-in method _imp.create_dynamic}
  230/229    0.004    0.000    0.006    0.000 {built-in method builtins.__build_class__}
      687    0.003    0.000    0.003    0.000 {built-in method posix.stat}
      382    0.003    0.000    0.010    0.000 <frozen importlib._bootstrap_external>:1438(find_spec)
      107    0.002    0.000    0.002    0.000 {built-in method io.open_code}
      107    0.002    0.000    0.002    0.000 {method 'read' of '_io.BufferedReader' objects}
      620    0.001    0.000    0.002    0.000 _inspect.py:65(getargs)
    31/21    0.001    0.000    0.008    0.000 {built-in method _imp.exec_dynamic}
     1905    0.001    0.000    0.003    0.000 <frozen importlib._bootstrap_external>:62(_path_join)
     3956    0.001    0.000    0.001    0.000 {built-in method builtins.getattr}
...
```

where we can now see that most of the time is spent computing the
[singular value decomposition (SVD)](https://en.wikipedia.org/wiki/Singular_value_decomposition),
presumably to compute the
[pseudo-inverse](https://en.wikipedia.org/wiki/Moore%E2%80%93Penrose_inverse)
(`pinv`), followed by generating random numbers.  In a
real program, you might then decide to have a look at whether that
matrix needs inverting or if you could do something else that's
faster.

You can also visualise the output with a standard visualiser called
[KCachegrind](http://kcachegrind.sourceforge.net/html/Home.html).
I'll assume you've somehow installed it.  In Linux, it
should be available from the system's repos (e.g. `dnf install
kcachegrind` or `apt install kcachegrind`).  If you don't want to pull
all the KDE dependencies, you can try the equivalent `qcachegrind`.

First, we need to create the binary profile data with cProfile using
the `-o <binary file name>` flag. e.g.

```
$ python3 -m cProfile -o script.prof script.py
```

We then call [`pyprof2calltree`](https://pypi.org/project/pyprof2calltree/)
on the output, where the `-i` flag
indicates the input file and the `-k` flag tells it to run
KCachegrind.

```
$ pyprof2calltree -i script.prof -k
```

`pyprof2calltree` is not a standard package but you can download it
wherever you get your Python packages.

### Valgrind

For compiled code in many languages (notably including C, C++ or Fortran), there's a standard
profiler called [Valgrind](https://valgrind.org/).  It's actually a suite of tools and the one
for profiling runtime is `callgrind`.  You should be able to install
Valgrind from your system packages.  You can then run it on a compiled
program called `./program` with

```
$ valgrind --tool=callgrind ./program
```

Your program will then run *very very slowly* and produce a file
called something like `callgrind.out.<pid>`.  The output is produced
as the program runs, so if it's taking too long, you can interrupt it
with `Ctrl-c` and still look at whatever was produced up to that
point.

The output file is in an unintelligible binary format but can also
be visualised with KCachegrind by running e.g.

```
$ kcachegrind callgrind.out.<pid>
```

(or `qcachegrind` if you installed that instead of `kcachegrind`).

## Broad strategies

This is a somewhat random collection of things you can try to speed up
a block of code.  They are roughly in order of increasing difficulty
but it depends on your skills and how the code works.

### Avoid loops

Python for-loops are notoriously slow, though I think this is probably
true of many interpreted languages.  (It was true of MATLAB the last
time I used it.)  Because we work with arrays, you might be able to
replace a loop over two arrays with operations directly on the arrays
themselves (we say we *vectorise* the operation), perhaps by using some
logical indexing or broadcasting.  The gains are potentially huge:
eliminating a for loop often speeds things up by an order of magnitude
or more.

Though a bit contrived, this is what we're talking about:
```
In [1]: import numpy as np

In [2]: x = np.random.rand(1_000_000)

In [3]: %timeit y = np.array([np.sin(xi**2) for xi in x])
1.57 s ± 16.7 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)

In [4]: %timeit y = np.sin(x**2)
13.4 ms ± 174 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
```

### Don't repeat expensive things

This might seem obvious but it requires knowing what part of the code is
expensive and whether you can afford to store an intermediate result
(which might require a lot of memory or something).

Note that special functions can be quite expensive.  Even
trigonometric functions are much slower than the basic operations `+`,
`-` and `*`, so e.g. rather use `np.sin(2*x)` than
`2*np.sin(x)*np.cos(x)`.

### Try "magic" packages

There are several Python packages that will potentially speed up your
code dramatically with relatively small changes that don't damage
readability.  These are usually worth a try because they're so simple
but I seldom get the advertised performance gains when working with
arrays.  A few example packages are

* [Numba](https://numba.readthedocs.io/)
* [NumExpr](https://numexpr.readthedocs.io/)
* [Bottleneck](https://bottleneck.readthedocs.io/)

but there are probably more that I don't know about.

### Parallelise

Most modern computers have multiple cores, so
one way to speed things up is to make use of them.  But only
do this if the libraries you are using for the slow parts of your code
aren't already parallelised!

The standard module for parallelising in Python is
[`multiprocessing`](https://docs.python.org/3/library/multiprocessing.html)
but the overhead can be large enough that you don't see a gain
compared to array operations.  In Fortran or C++, it's sometimes quite
easy to parallelise with [OpenMP](https://www.openmp.org/).  If you need more advanced
parallelisation, your skills probably far exceed the content of this
article.

If you can parallelise, you should try to do so at the highest level
that you can, so I tend to parallelise the execution of my scripts
using the command line tool `xargs`.  The main purpose of `xargs` is
to take the output from one command line program and provide it as
input arguments to the next. e.g. consider `seq`, which prints a list of numbers.
```
$ seq 4
1
2
3
4
```
Let's say we want to provide each of these numbers as an argument to, say, `echo`.
```
$ seq 4 | xargs echo
1 2 3 4
```

Wait, what?  `xargs` defaults to sending all the output from the
previous program to one instance of the next one.  We can confirm this by using `xargs`'s `-t` flag, which will show us what `xargs` has decided to execute (I usually use `-t`):
```
$ seq 4 | xargs -t echo
echo 1 2 3 4 
1 2 3 4
```
If we want to send only one argument to each instance of `xargs`, we can use the `-n <N>` flag, where `<N>` is the number of arguments we want to send to each instance of `echo`.
```
$ seq 4 | xargs -t -n 1 echo
echo 1 
1
echo 2 
2
echo 3 
3
echo 4 
4
```
Let's get back to parallelisation.  First, try passing the numbers to `sleep` and use `time` to see how long it takes.
```
$ time seq 4 | xargs -t -n 1 sleep
sleep 1 
sleep 2 
sleep 3 
sleep 4 

real    0m10.006s
user    0m0.003s
sys     0m0.004s
```
That makes sense, because we ran sleep for 1s+2s+3s+4s=10s.  To use
`xargs` to run `sleep` in parallel, we use the `-P <N>` flag, where
now `<N>` is the number of jobs we'd like to use.

```
$ time seq 4 | xargs -t -n 1 -P 4 sleep
sleep 1 
sleep 2 
sleep 3 
sleep 4 

real    0m4.003s
user    0m0.002s
sys     0m0.004s
```
Again, this makes sense because my computer runs all 4 `sleep`s in
parallel, so we just have to wait for the last one to finish, which
takes 4s.

### Link compiled code

The final change you can try making to your code is to call compiled
code directly from Python.  The standard tool to call Fortran is
[F2PY](https://numpy.org/doc/stable/f2py/),
which is part of NumPy.

There are many options for C and C++.  I don't really know C or C++ so
haven't used them but as far as I know some options are
[ctypes](https://docs.python.org/3/library/ctypes.html),
[Cython](https://cython.readthedocs.io/),
[CFFI](https://cffi.readthedocs.io/)
and [PyBind](https://pybind11.readthedocs.io/).
Also have a look at [this post](https://dfm.io/posts/python-c-extensions/)
by Daniel Foreman-Mackay.

### Rethink

If no tricks are working, it might be worth getting away from the code
and rethinking the overall algorithm you're using and whether there
are things you can change.  Perhaps you can do an MCMC burn-in with an
approximate calculation?  Or perhaps you can replace a section with a
difficult but fast analytic result?

## Some specific things

It's impossible to make a list of every change that might speed up
your code but here are some things that I often run into or work
around.

### Python imports can take the better part of a second.

Consider this simple script that just import a few things we might
want to use in our analysis.

```
$ cat imports.py 
#!/usr/bin/env python3

import numpy as np
from scipy import optimize
from scipy import integrate
from astropy.io import fits
from astropy.timeseries import LombScargle
```
How long does it take to run?
```
$ time python3 ../faster_code/imports.py 

real    0m0.564s
user    0m0.776s
sys     0m0.295s
```

A bit over half a second.  That might not seem like much but if you're
running a script to do half a second of work (besides the imports) on
thousands of files, you might spend hours just importing Python
modules.

My standard solution is to write scripts that take lists of filenames
as arguments and run the scripts over multiple files (perhaps dozens)
on each call, usually using `xargs`.

### Binary I/O is usually faster than plain-text I/O.

It's usually faster to read and write data in binary formats
(e.g. NumPy binaries, FITS, HDF5) than plain text (e.g. CSV).  So if
you're repeatedly working with a plain text file that's a bit slow to
read, take a moment to convert it into a binary format.

Here's a simple demonstration:
```
In [1]: import numpy as np

In [2]: x = np.random.rand(1_000_000)

In [3]: np.savetxt('x.txt', x)

In [4]: %timeit y = np.loadtxt('x.txt')
2.84 s ± 27.8 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)

In [5]: np.save('x.npy', x)

In [6]: %timeit y = np.load('x.npy')
1.75 ms ± 49 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)
```
Though somewhat contrived, you really can speed things up by an order
of magnitude or more.

Binary files are also usually somewhat smaller and occasionally *much*
smaller than the corresponding plain text files.

### Network I/O can be slow for lots of small files.

Since we're all working from home, you're possibly spending some big
data files over the Internet.  This may or may not be a problem.  If
you use a decent broadband internet connection to fetch one file, you
might not notice anything.  But I find things get quite slow when
accessing multiple smaller files, in which case you can either somehow
bundle your files up on the server so you can read them once, or just
take the plunge and copy them to your hard drive (if you can afford
the space).

### Know when to stop

Computers run at a finite speed; there's a limit to how fast any
particular piece of code will run.  If your code already spends most
of its time in the part that *should* take the most time, it's worth
considering whether there's anything more to be done.
