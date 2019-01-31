FROM opensuse/leap:15.0
RUN zypper --non-interactive install python && \
    zypper clean --all
RUN mkdir /srv/web
WORKDIR /srv/web
COPY files/version2.jpg /srv/web/image.jpg
COPY files/index.html /srv/web/
CMD ["python","-m","SimpleHTTPServer"]
