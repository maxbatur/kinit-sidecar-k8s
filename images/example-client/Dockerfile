FROM alpine:3.19.0

MAINTAINER mbaturlov@gmail.com

ADD ./rekinit.sh /
ADD krb5.conf /etc/krb5.conf

USER root

RUN apk --no-cache add krb5 && mkdir -p /krb5 && chmod 755 /krb5 

VOLUME ["/krb5","/dev/shm","/etc/krb5.conf.d"]

USER 1001

ENTRYPOINT ["sh","/rekinit.sh"]

