#LAA apply for legal aid

This is the service api for persisting application related information to the back end database and
may well be used to fire requests to other services.

* Ruby version 
    * Ruby version 2.5.1
    * Rails 5


* System dependencies
    * none

* Configuration
    * ```bundle install```

* Database creation
   * not needed yet

* Database initialization
    * ```rake db:migrate```

* How to run the test suite
    * ```bundle exec rspec spec```

* Services (job queues, cache servers, search engines, etc.)
    

* Deployment instructions
    * check the code out and run ```rails s```

* play with application
    Once the server is started you can actualy use postman to fire requests using the endpoints below
    

* Developer local Endpoints
    * ``http://localhost:3000/api/v1/applications``
        * Only POST is supported at the moment so this wil create an application and retrun application ref
    * ``http://localhost:3000/api/v1/status``
        * Only GET is supported at the moment not sure anything else is needed here


#Docker

The docker file is created against a ruby alpine image using version 2.5.1 which is consistent
with the latest version at the time of writing.

Alpine images are usually very lightweight and such are preferred choice for deploying containers.

In order to create a local build you can run

```docker build -t laa-apply-for-legalaid-api .```


And then run the image using

```docker container run  -d -p 3000:3000 laa-apply-for-legalaid-api```


