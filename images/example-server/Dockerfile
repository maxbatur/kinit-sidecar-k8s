FROM alpine:3.19.0

MAINTAINER mbaturlov@gmail.com

# install kdc and kadmin
RUN apk --no-cache add krb5 krb5-server && mkdir -p /krb5 && chmod 755 /krb5 

RUN mkdir -p /var/lib/krb5kdc.d && \
    mkdir -p /etc/krb5.conf.d 

ADD ./init.sh /
ADD ./kdc.conf /var/lib/krb5kdc/
ADD ./krb5.conf /etc/


RUN chmod g+X,o+X,g+w,a+r -R /var/lib/krb5kdc && \
    chmod g+X,o+X,g+w,a+r -R /var/lib/krb5kdc.d && \
    chmod g+X,o+X,g+w,a+r -R /etc/krb5.conf.d && \
    chmod 664 /etc/krb5.conf


RUN sed -i 's|kerberos-adm[[:blank:]]*749|kerberos-adm\ \ \ \ 8749|g' /etc/services && \
    sed -i 's|kpasswd[[:blank:]]*464/|kpasswd\ \ \ \ 8464/|g' /etc/services

VOLUME ["/var/lib/krb5kdc","/var/lib/krb5kdc.d", "/etc/krb5.conf.d", "/dev/shm" ]
EXPOSE 8888 8464 8749

USER 1001

ENTRYPOINT ["sh","/init.sh"]
