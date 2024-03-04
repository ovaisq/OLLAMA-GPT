## ZOllama-GPT

### General Overview

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'lineColor': 'Blue'}}}%%
flowchart TD
Z((ZOllama
Service API))
A(gemma)
AZA(llama2)
AZB(deepseek-llm)
B(meditron)
BA(medllama)
C(Patient)
F(Redditor)
D[(PostgreSQL)]
AE(Posts)
AF(Comments)
AG(Subreddits)
CAC(Clinical Notes OSCE)
Reddit --> Z
C --> EMR
EMR --> Z
Z --> Local
F --> Reddit

subgraph Local
PatientOllama --> ProcessedPatientData
RedditOllama --> ProcessedRedditData
PJSON -- Encrypted --> D
ProcessedRedditData -- "Un-Encrypted" --> D

RDD --> RedditOllama
RDE --> RedditOllama
RDD --"Un-Encrypted"--> D
RDE --"Un-Encrypted"--> D
RDC --"Un-Encrypted"--> D
OPDA --> PatientOllama
OPDB -- "Un-Encrypted" --> D
DiagnosticKeyWords -- "Un-Encrypted" --> D

subgraph OriginalPatientData["Original Patient Data"]
OPDA(Clinical Notes OSCE)
OPDB(Patient ID)
end
subgraph RedditData["Original Reddit Data"]
subgraph RDBMS
RDD(Redditor Posts)
RDE(Redditor Comments)
RDC(Subreddits)
end
end

subgraph OLLAMA-LLM

subgraph RedditOllama["Reddit"]
A
AZA
AZB
end
subgraph PatientOllama["Patient"]
B
BA
end
end
subgraph ProcessedPatientData["Processed Patient Data"]
subgraph PJSON["JSON"]
PDB(OSCE Summarized)
PDC(Recommended Diagnoses)
end
subgraph DiagnosticKeyWords["Key Words"]
end
end
subgraph ProcessedRedditData["Processed Reddit Data"]
subgraph JSON
RDA(Analyzed Posts)
RDB(Analyzed Comments)
end
end
end
subgraph EMR
CAC
end
subgraph Reddit
AE
AF
AG
end
```

#### API Overview
```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'lineColor': 'Blue'}}}%%
graph LR
    sub["/login"] --> sub3
    sub["/analyze_post"] --> sub1
    sub["/analyze_posts"] --> sub2
    sub["/analyze_comment"] --> sub9
    sub["/analyze_comments"] --> sub10
    sub["/get_sub_post"] --> sub4
    sub["/get_sub_posts"] --> sub5
    sub["/get_author_comments"] --> sub6
    sub["/get_authors_comments"] --> sub7
    sub["/get_and_analyze_post"] --> sub12
    sub["/join_new_subs"] --> sub11
    sub["CLIENT"] --> sub8
    sub1["GET: Analyze a single Reddit post"]
    sub2["GET: Analyze all Reddit posts in the database"]
    sub3["POST: Generate JWT"]
    sub4["GET: Get submission post content for a given post id"]
    sub5["GET: Get submission posts for a given subreddit"]
    sub6["GET: Get all comments for a given redditor"]
    sub7["GET: Get all comments for each redditor from a list of authors in the database"]
    sub8["GET: Join all new subreddits from post database"]
    sub9["GET: Chat prompt a given comment_id that's stored in DB"]
    sub10["GET: Chat prompt all comments that are stored in DB"]
    sub11["GET: Join all new subs from the post table in the database"]
    sub12["GET: Fetch post from Reddit, then Chat prompt a given post_id"]
```


**From EMR**: 
* It collects medical conversations in the format of Objective Structured Clinical Examinations (OSCE)
* Summarizes the medical conversation into a prompt
* Analyzes the summarized conversation through meditron, and medllama LLMs.
  - Picks out keywords
* Encrypts the analyzed text and stores it as part of searchable json document in PostgreSQL
  
**From Reddit**:
* Service collects
  - submissions
  - comments for each submission
  - author of each submission
  - author of each comment to each submission
  - and all comments for each author.
*  Subscribes to subreddit that a submission was posted to

** Deployed as WSGI **  
*  Uses Gunicorn WSGI

#### How-to Run this
* Install Python Modules:
    > pip3 install -r requirements.txt

* Get Reddit API key: https://www.reddit.com/wiki/api/

* Gen SSL key/cert for secure connection to the service
    > openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 3650

* Gen Symmetric encryption key for encrypting any text
   > ./tools/generate_keys.py
   > Encrption Key File text_encryption.key created

* Create Database and tables:
    See **reddit.sql**

### Install Ollama-gpt 

#### Linux
* https://github.com/ollama/ollama/blob/main/docs/linux.md

* Sample Debian Service config file: /etc/systemd/system/ollama.service
```shell
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
..
..
..

```

#### MacOS
* I installed Ollama-gpt on my MacMini M1 - using brew
```shell
> brew install ollama
```
* Start/Stop Service
```shell
> brew services start ollama
> brew services stop ollama
```

**Bind Ollama server to local IPV4 address**

* create a run shell script
  ```shell
  > /opt/homebrew/opt/ollama/bin
  ```
* Create a script named **ollama.sh** add the following
  ```shell
  #!/usr/bin/env bash
  export OLLAMA_HOST=0.0.0.0
  /opt/homebrew/bin/ollama $1
  ```
* Make script "executable"
  ```shell
  chmod +x ollama.sh
  ```
* Edit .plist file for the ollama homebrew service
  ```shell
    > cd /opt/homebrew/Cellar/ollama
    > cd 0.1.24 #this may be different for your system
    > vi homebrew.mxcl.ollama.plist
  ```
* Change original line
  > <string>/opt/homebrew/opt/ollama/bin/ollama</string>

    TO this:
  > <string>/opt/homebrew/opt/ollama/bin/ollama.sh</string>
* Save file
* stop/start service
  ```shell
  > brew services stop ollama && brew services start ollama
  ```
* Add following models to ollama-gpt: deepseek-llm,llama2,llama-pro 
  ```shell
  > for llm in deepseek-llm llama2 llama-pro gemma
    do
        ollama pull ${llm}
    done
  ```
* Update setup.config with pertinent information (see setup.config.template)
  ```text
     # update with required information and save it as
     #	setup.config file
    [psqldb]
    host=
    port=5432
    database=
    user=
    password=

    [reddit]
    client_id=
    client_secret=
    username=
    password=
    user_agent=

    [service]
    JWT_SECRET_KEY=
    SRVC_SHARED_SECRET=
    IDENTITY=
    APP_SECRET_KEY=
    ENDPOINT_URL=
    OLLAMA_API_URL=
    LLMS=
    MEDLLMS=
    ENCRYPTION_KEY=
  ```

* Run ZOllama-GPT Service:
    (see https://docs.gunicorn.org/en/stable/settings.html for config details)
```shell
    > gunicorn --certfile=cert.pem \
               --keyfile=key.pem \
               --bind 0.0.0.0:5000 \
               zollama:app \
               --timeout 2592000 \
               --threads 4 \
               --reload
```
* Customize it to your hearts content!


* **LICENSE**: The 3-Clause BSD License - license.txt


* **TODO**:
    - Add Swagger Docs
    - Add long running task queue
        - Queue: task_id, task_status, end_point
    - Revisit Endpoint logic add robust error handling
    - Add scheduler app - to schedule some of these events
        - scheduler checks whether or not a similar tasks exists
    - Add logic to handle list of lists with NUM_ELEMENTS_CHUNK elements
        - retry after 429
        - break down longer list of items into list of lists with small
            chunks

#### Example
* These examples assume that environment variable **API_KEY** is using a valid API_KEY


**Get All comments for all Redditors in the database**
```shell
> export api_key=<api_key>
>
> export AT=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"api_key":"'${api_key}'"}' \
  https://127.0.0.1:5000/login | jq -r .access_token) && curl -sk -X GET -H \
  "Authorization: Bearer ${AT}" 'https://127.0.0.1:5000/get_authors_comments'
```
**On Service Console**:
```shell
    INFO:root:Getting comments for Redditor
    INFO:root:Redditor 916 new comments
    INFO:root:Processing Author Redditor
    INFO:root:Processing Author Redditor
    INFO:root:Processing Author Redditor
    INFO:root:Processing Author Redditor
```
**Analyze a Post using Post ID that already exists in a post table in the database**
```shell
> export AT=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"api_key":"'${API_KEY}'"}' \
  https://127.0.0.1:5001/login | jq -r .access_token) && curl -sk -X GET -H \
  "Authorization: Bearer ${AT}" 'https://127.0.0.1:5001/analyze_post?post_id=<Reddit Post ID>'
```
**Get and Analyze a Post using Post ID that has not yet been added to the post table in the database**
```shell
> export AT=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"api_key":"'${API_KEY}'"}' \
  https://127.0.0.1:5001/login | jq -r .access_token) && curl -sk -X GET -H \
  "Authorization: Bearer ${AT}" 'https://127.0.0.1:5001/get_and_analyze_post?post_id=<Reddit Post ID>'
```

### General Workflow
```mermaid
flowchart TD
    A[Start] --> B[Read Configuration]
    B --> C[Connect to PostgreSQL]
    C --> D[Get new post IDs]
    D --> E{Any new post IDs?}
    E -- Yes --> F[Analyze Posts]
    F --> G[Get Post Details]
    G --> H[Process Author Information]
    H --> I[Get Post Comments]
    I --> J[Get Comment Details]
    J --> K[Insert Comment Data into Database]
    I --> L{More Comments?}
    L -- Yes --> I
    L -- No --> M[Sleep to Avoid Rate Limit]
    E -- No --> N[Sleep to Avoid Rate Limit]
    N --> D
    M --> D
    N --> O[Get New Subreddits]
    O --> P{Any new subreddits?}
    P -- Yes --> Q[Join New Subreddits]
    Q --> O
    P -- No --> R[End]
```

#### Database Schema
![Database Schema](database.png)

#### llama-gpt VM config 

*nVidia GTX-1070i 8GB in Passthrough Mode*

![llama-gpt-vm](llama-gpt-vm.png)

#### Reddit Data Scraper Service VM config
![service-vm](reddit-data-scrapper-vm.png)

#### PostgreSQL VM config
![postgresql-vm](postgresql-vm.png)
