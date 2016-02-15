## 0.3.2.3 - Improve logging control
## 0.3.2.1 - Add the ability to log cache hits and misses
## 0.3.2.0 - Revise the method for computing keys in cacheable.
Need to use the digest for both the arguments and the instance properties.

## 0.3.1.0 - Fix the method for computing argument keys in cacheable.
Was using Ruby's hash(), but that varies by ruby runtime.

## 0.3.0.0 - Detect attempts to pass a block to cached or memoized methods and raise an error.
## 0.2.0.0 - Still pre release, but made a new method for memoizing methods with args.
## 0.1.0.0 - Pre Release
