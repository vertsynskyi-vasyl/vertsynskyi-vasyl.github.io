FROM nginx
ARG GITDIR=/srv/git/hw08.git
ARG JENKINS_URL
ARG JENKINS_USER
ARG TOKEN
ARG PROJECT

# Copy config files
COPY default.conf /etc/nginx/conf.d/default.conf
COPY fcgiwrap /etc/default/fcgiwrap

# Install and set up git, fcgiwrap and prepare git directory
RUN apt update && apt install git fcgiwrap -y \
    && mkdir -p $GITDIR && cd $GITDIR \
    && git init --bare --shared \
    && git config --global --add safe.directory $GITDIR \
    && git config --file config http.receivepack true \
    && git update-server-info \
    && chown -R nginx:nginx $GITDIR

# Create post-receive hook
RUN echo "#!/bin/bash" > $GITDIR/hooks/post-receive \
    && echo "curl -X POST 'http://$JENKINS_USER:$TOKEN@$JENKINS_URL/job/$PROJECT/build'" \
       > $GITDIR/hooks/post-receive \
    && chmod +x $GITDIR/hooks/post-receive

# Run service
CMD service fcgiwrap start && service nginx start && tail -f /var/log/nginx/error.log

