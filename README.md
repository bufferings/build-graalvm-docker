# build-graalvm-docker

This is a Dockerfile to build GraalVM from its master branch just for my project :)

This is because currently GraalVM 19.0.2 fails to build native image due to
https://github.com/oracle/graal/issues/1295

Therefore I created this Dockerfile and use it until the following commit is included into the official release:
https://github.com/oracle/graal/commit/c6237d219a91c82b1954dfbfa0898ed917db09eb

I refered the official Dockerfile of GraalVM:
https://github.com/oracle/docker-images/tree/2a89e3d4c945156a0db66e7954826965a08cacb6/GraalVM/CE/1.0.0-rc16

