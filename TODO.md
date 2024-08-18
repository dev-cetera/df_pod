1. Since TempPod cannot take listners, it doesn't make sense to have the temp flag in Pod and have a crazy disposeIfTemp method.
2. Same with GlobalPod -- no need to disable dispose. Just print a warking
3. This is a must: invalid_use_of_protected_member: error
