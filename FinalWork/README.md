# Final work

## Завдання

Це більш просунута версія восьмої роботи.

Вона містить майже усі технології, які були розглянуті у попередніх роботах і створює автономну CI/CD систему з нуля.


Інфраструктура виглядає таким чином:

**1. Build Server** (VM, що підіймається за допомогою Terraform/libvirt та налаштовується Ansible)
**2. Git server** (який підіймається Docker compose)
**3. Docker registry** (Docker контейнер)
**4. Jenkins** (Docker контейнер)


***Завдання:*** _при внесенні змін у репозиторій на Git-сервері (git push) із свіжого коду збирається Docker образ, який по завершенню збірки завантажується у Docker registry._

***Нотатка:*** _якщо маєте бажання відтворити цей код на своєму хості, майте на увазі, що всі дії у консолі починаються із директорії цієї роботи!_


![](./images/Infrastructure.png)


## Jenkins
### Встановлення Jenkins
```bash
docker pull jenkins/jenkins:lts
docker network create dev_net
docker run -d -p 8989:8080 -p 50000:50000 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --network dev_net \
  --name jenkins jenkins/jenkins:lts
```

_* я для підключення до Jenkins обираю порт 8989, так як 8080 у мене зайнятий, ви можете залишити 8080, або обрати свій, проте я рекомендую використовувати запропонований мною, тоді можна буде користуватися прямими посиланнями на Jenkins у цьому документі_
_* важливий момент: контейнер Jenkins має знаходитись в мережі відмінній від мережі за замовчуванням, яка не дозволяє автоматично розв’язку DNS; у моєму випадку я створюю окрему мережу `dev_net`_


### Налаштування Jenkins
Відкриваємо в браузері адресу http://localhost:8989 і трохи чекаємо, поки Jenkins розігріється.

![](./images/img_001.png)


Щоб здобути початковий пароль адміністратора, буде достатньо виконати команду:
```bash
docker exec -it jenkins \
bash -c "cat /var/jenkins_home/secrets/initialAdminPassword"
9892467f4b924b60a6da047e87b27126
```

Далі копіюємо отримане значення, та вставляємо у Jenkins.
Або якщо ви лінивий та працюєте на Linux, то можна спростити, отримавши пароль одразу у буфер обміну однією командою:
```bash
docker exec -it jenkins \
bash -c "cat /var/jenkins_home/secrets/initialAdminPassword" | xclip -i -r
```
Далі залишається лише вставити за призначенням.

![](./images/img_002.png)


У наступному вікні натискаємо ***Install suggested plugins*** і терпляче чекаємо завершення встановлення.

![](./images/img_003.png)
![](./images/img_004.png)


Далі вводимо всі необхідні дані для створення користувача (рекомендовано), або можна обрати варіант _Skip and continue as admin_ (не рекомендовано).

![](./images/img_005.png)


На наступному кроці я зміню значення `Jenkins URL` з _http://localhost:8989/_ на _http://10.17.3.1:8989/_, використавши таким чином локальну мережеву адресу, я зробив доступним Jenkins з локальної мережі, що знадобиться для використання тригерів.

![](./images/img_006.png)


Тепер тиснемо _Start using Jenkins_

![](./images/img_007.png)


І потрапляємо на стартову сторінку

![](./images/img_008.png)


### Docker Pipeline plugin
Docker Pipeline plugin забезпечує механізм збірки образів Docker.

Переходимо у [Manage Jenkins / Plugin Manager / Available plugins](http://localhost:8989/manage/pluginManager/available).
* у строчці пошуку набираємо ***«Docker»***
* в результатах пошуку відмічаємо ***Docker Pipeline***
* потім тиснемо ***Install without restart***
* на наступному етапі ***Restart Jenkins when installation is complete and no jobs are running***
і чекаємо на перезапуск

![](./images/img_051.png)
![](./images/img_052.png)
![](./images/img_053.png)


### Credentials
#### Створення ключа
Для доступу до агентів нам необхідно додати у Jenkins SSH ключ.

Спочатку створимо його.

_Для підвищення безпеки використаємо шифрування приватного ключа, підставивши пароль під час створення ключа.
Пароль можна згенерувати, наприклад, командою `pwgen -y 16`. Цей пароль рекомендую зберегти у вашому сховищі паролів, він може знадобитися у майбутньому._
```bash
mkdir -p ~/.ssh/keys && cd ~/.ssh/keys
ssh-keygen -t ed25519 -C "Jenkins" -f JENKINS
```

![](./images/img_009.png)
<!--
```
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in JENKINS
Your public key has been saved in JENKINS.pub
The key fingerprint is:
SHA256:26LBBJL/Xo5P+Try40OoMZW58aUdhifuDQnBsvLOgxo Jenkins
The key's randomart image is:
+--[ED25519 256]--+
|     .           |
|   .. o          |
|  o .o + .       |
|  .o..* o =      |
|   o...BSO .     |
|    ++o B+.      |
|E  + ++o*o.      |
| .. =..B=o.      |
|..   .+=*=.      |
+----[SHA256]-----+
```
-->


#### Додаємо ключ у Jenkins
Переходимо у _[Manage Jenkins / Credential](http://localhost:8989/manage/credentials/)_

![](./images/img_010.png)


Та обираємо у _Stores scoped to Jenkins / Domains / (global)_ опцію _[Add credentials](http://localhost:8989/manage/credentials/store/system/domain/_/)_

![](./images/img_011.png)


де натискаємо ***+ Add Credentials***

![](./images/img_012.png)


У діалогу із додавання даних робимо такі дії:
* `Kind` обираємо як _SSH Username with private key_
* `Username` вказуємо ім’я користувача, який ми створювали у тераформі (в нашому випадку це — _terraform_)
* `Private key` вмикаємо _Enter directly_ та вставляємо вміст приватного ключа, який можна отримати або:
  ```bash
  cat ~/.ssh/keys/JENKINS
  ```
  або одразу в буфер:
  ```bash
  xclip -i -r ~/.ssh/keys/JENKINS
  ```
* `Passphrase` - вводимо пароль, який ми використовували при створенні ключа

Далі тиснемо _Create_.

![](./images/img_013.png)
![](./images/img_014.png)


Наші дані для доступу готові.

![](./images/img_015.png)


### Створення API токену
_Цей розділ є необов’язковим, якщо не плануєте використання автоматичного запуску Jenkins Pipeline при змінах у Git_


Цей токен знадобиться на [етапі створення скрипту](README.md#змінні-.var), який буде запускати сценарій Jenkins.

Переходимо до _Dashboard > Jenkins Admin > Configure_ ("Jenkins Admin" — це ім’я нашого користувача) і знаходимо розділ _API Token_.
Натискаємо ***Add new Tocken***, вводимо назву токену (її слід запам’ятати, ми будемо використовувати при створенні конвеєра Jenkins).

![](./images/img_020.png)


Копіюємо значення токену і десь тимчасово його зберігаємо.

![](./images/img_021.png)


---

## Створення агента для Jenkins
### Розгортання агента
Розгорнемо додаткову віртуальну машину `dev-worker01` за допомогою Terraform, використовуючи конфігурацію із [четвертої роботи](../HW04/README.md).
Вона буде доступна в мережі за ім’ям dev-worker01.dev.local.


### Налаштування агента
Використовуючи налаштування Ansible із [п’ятої роботи](../HW05/README.md), створимо нову роль `worker`, яка буде імплементувати необхідну конфігурацію машини для наших збірок.

![](./images/img_101.png)
<!--
```
.
└── playbooks
    ├── deploy_worker.yml
    └── roles
        └── worker
            ├── defaults
            ├── handlers
            ├── tasks
            │   ├── docker.yml
            │   └── main.yml
            ├── templates
            └── vars
                └── main.yml

8 directories, 4 files
```
-->


#### tasks/main.yml

Основне завдання ролі встановлює середовище Java, необхідне для функціонування Jenkins, створює робочий каталог, а також інсталює публічний ключ, створений нами на попередніх етапах, для доступу Jenkins до агентів.
```yaml
# playbooks/roles/worker/tasks/main.yml
- name: Install docker
  import_tasks: docker.yml

- name: Install OpenJDK JDK 17
  ansible.builtin.apt:
    name: openjdk-17-jdk
    state: present

- name: Create a directory for Jenkins
  ansible.builtin.file:
    path: /home/jenkins
    state: directory
    owner: terraform
    group: src
    mode: '0770'

- name: Set Jenkins authorized key
  ansible.posix.authorized_key:
    user: terraform
    state: present
    key: "{{ lookup('file', '{{ jenkins_key }}' ) }}"
```


#### tasks/docker.yml

Окреме підзавдання docker.yml інсталює та налаштовує docker
```yaml
# playbooks/roles/worker/tasks/docker.yml
- name: install packages required by docker
  apt:
    update_cache: yes
    state: latest
    name:
    - apt-transport-https
    - ca-certificates
    - curl
    - gpg-agent
    - software-properties-common

- name: add docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: add docker apt repo
  apt_repository:
    repo: deb https://download.docker.com/linux/ubuntu "{{ ansible_distribution_release }}" stable
    state: present

- name: install docker
  apt:
    update_cache: yes
    state: latest
    name:
    - docker-ce
    - docker-ce-cli
    - containerd.io

- name: allow insecure registries in 10.17.3.1:5000
  ansible.builtin.lineinfile:
    path: /etc/docker/daemon.json
    line: "{ \"insecure-registries\":[\"10.17.3.1:5000\"] }"
    create: yes

- name: add a build user to the docker group
  ansible.builtin.user:
    name: "{{ build_user }}"
    groups: docker
    append: yes

- service: name=docker state=restarted
```
_* про завдання `allow insecure registries` докладніше у розділі [Docker Registry](README.md#docker-registry)._


#### vars/main.yml
```yaml
# playbooks/roles/worker/vars/main.yml
jenkins_key: ~/.ssh/keys/JENKINS.pub
build_user: terraform
```

Як видно у файлі змінних, тут вказаний шлях до публічного ключа.

#### playbooks/deploy_worker.yml

Це сценарій, якій має задіяти створену роль `worker`:
```yaml
# playbooks/deploy_worker.yml
---
- hosts: dev_workers
  roles:
    - { role: worker, become: yes }
```

Запускаємо його командою:
```bash
ansible-playbook playbooks/deploy_worker.yml
```

![](./images/img_102.png)
<!--
```
PLAY [dev_workers] ***********************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [dev-worker01]

TASK [worker : install packages required by docker] **************************************************************
ok: [dev-worker01]

TASK [worker : add docker GPG key] *******************************************************************************
ok: [dev-worker01]

TASK [worker : add docker apt repo] ******************************************************************************
ok: [dev-worker01]

TASK [worker : install docker] ***********************************************************************************
ok: [dev-worker01]

TASK [worker : add a build user to the docker group] *************************************************************
ok: [dev-worker01]

TASK [worker : service] ******************************************************************************************
changed: [dev-worker01]

TASK [worker : Install OpenJDK JDK 17] ***************************************************************************
ok: [dev-worker01]

TASK [worker : Create a directory for Jenkins] *******************************************************************
ok: [dev-worker01]

TASK [worker : Set Jenkins authorized key] ***********************************************************************
ok: [dev-worker01]

PLAY RECAP *******************************************************************************************************
dev-worker01               : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
-->

### Додавання агента у Jenkins

Переходимо у _[Manage Jenkins / Manage Nodes and Clouds](http://localhost:8989/manage/computer/)_

![](./images/img_201.png)


де натискаємо ***+ New Node***

![](./images/img_202.png)

Даємо назву нашому агенту, та натискаємо ***Create***.

![](./images/img_203.png)


Налаштовуємо далі:
* **Number of executors:** `2` (я обрав по кількості ядер на агенті)
* **Remote root directory:** `/home/jenkins` (директорія, яку ми налаштували через роль Ansible)
* **Labels:** `dev libvirt` (це дві мітки із назвами _dev_ та _libvirt_, які потім можна використати при створенні piplines)
* **Launch method:** `Launch agent via SSH` (ми завбачливо додали SSH ключ до агенту через роль Ansible)
  * **Host:** `dev-worker01.dev.local` (ім’я нашого агенту, за яким він доступний у мережі)
  * **Credentials:** `terraform` (які ми створили у Jenkins [раніше](README.md#credentials))
  * **Host Key Verification Strategy:** `Known host file Verification Strategy` (для "полегшення" життя можна встановити _Non verifying_, але насправді обрана стратегія додасть лише один додатковий крок і при цьому не знизить нашу безпеку)

![](./images/img_204.png)
![](./images/img_205.png)


Після натискання кнопки ***Save*** ми повертаємось до списку вузлів, де з’явився наш агент.
![](./images/img_206.png)


Зліва можемо побачити що агент знаходиться у статусі запуску (_launching…_)
![](./images/img_207.png)


Заглянемо в логи нашого агента, щоб дізнатися як у нього справи
![](./images/img_208.png)
![](./images/img_209.png)


Тут ми одразу бачимо причину затримки запуску нашого агенту:
```
/var/jenkins_home/.ssh/known_hosts [SSH] No Known Hosts file was found at /var/jenkins_home/.ssh/known_hosts. Please ensure one is created at this path and that Jenkins can read it.
Key exchange was not finished, connection is closed.
SSH Connection failed with IOException: "Key exchange was not finished, connection is closed.", retrying in 15 seconds. There are 9 more retries left.
```

Це викликано саме нашою `Known host file Verification Strategy`, яка блокує підключення до хостів, інформація про які відсутня у файлі `known_hosts`.


Додати такий запис нескладно:
```bash
docker exec -it jenkins \
    bash -c "umask 077 && mkdir -p ~jenkins/.ssh && \
    ssh-keyscan -H -t ecdsa dev-worker01.dev.local \
    > ~jenkins/.ssh/known_hosts"
```


Після цієї процедури ми побачимо, що наш агент тепер має робочий статус

![](./images/img_210.png)


## Docker Registry

Оскільки ми плануємо збирати образи Docker, то нам потрібна кінцева точка, куди вони будуть зберігатися. Зазвичай для таких цілей використовується публічне сховище на кшталт DockerHub, проте я для експериментів надаю перевагу локальним ресурсам.

Запустити власне сховище для образів Docker можна командою:
```bash
docker run -d -p 5000:5000 --name docker_registry registry:latest
```

Перевірити, що Docker Registry працює можна за допомогою `curl`:
```bash
curl -s -X GET http://10.17.3.1:5000/v2/_catalog
{"repositories":[]}
```

Як ми бачимо наш каталог поки що порожній.


Оскільки наше Registry працює по незахищеному протоколу http, нам потрібно додати його адресу до параметру `insecure-registries` конфігурації Docker, що ми зробили для нашого агенту завданням _allow insecure registries…_ [ролі Ansible](README.md#tasks/docker.yml).


## Git

### Git server

Запуск локального Git серверу — завдання не складне. Для його функціонування потрібен веб-сервер та встановлений Git.
За основу ми візьмемо Docker образ nginx, встановимо туди Git, та виконаємо деякі налаштування.
Формувати образ будемо за допомогою docker-compose.


Структура файлів виглядає таким чином:
```bash
tree -a ./git-server
.
├── docker-compose.yml
├── .env
└── nginx
    ├── default.conf
    ├── Dockerfile
    └── fcgiwrap
```


#### Docker compose
```yaml
# --- docker-compose.yml ---
version: '3.9'
services:
  git:
    build:
      context: ./nginx
      args:
        - JENKINS_URL=${JENKINS_URL}
        - JENKINS_USER=${JENKINS_USER}
        - TOKEN=${TOKEN}
        - PROJECT=${PROJECT}
    ports:
      - 9000:80
```

#### Додаткові конфігураційні файли

* `nginx/default.conf` - конфігураційний файл nginx
* `nginx/fcgiwrap` — файл із невеличкими налаштуваннями, які виправляють права доступу до сокету `/var/run/fcgiwrap.socket`

#### Dockerfile
```dockerfile
# --- nginx/Dockerfile ---
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
```
_* насправді перша версія як docker-compose.yml так і Dockerfile виглядала не так монструозно до того як я перевів створення скрипту post-receive через змінні. До того він був окремим файлом і був представлений лише однією строчкою COPY…_


#### Змінні .var
Файл `.var` містить необхідні данні для створення post-receive хука. Це той самий хук, який буде запускати сценарій Jenkins при зміні у Git-репозиторії.
```ini
JENKINS_URL=10.17.3.1:8989
JENKINS_USER=jenkins
TOKEN=1135052db8b7084d600219b7722529eaac
PROJECT=BuildDockerImage
```

* **JENKINS_URL** — Адреса нашого сервера Jenkins
* **PROJECT** — Назва проєкту. Має співпадати із [назвою завдання](README.md#створення-завдання-у-jenkins) (Job) у Jenkins
* **JENKINS_USER** — Ім’я користувача, яке ми створювали при [початковому налаштуванні](README.md#налаштування-jenkins) Jenkins
* **TOKEN** — токен для доступу до Jenkins, який ми створили [раніше](README.md#створення-api-токену).


#### Запуск
```bash
cd git-server
docker-compose up -d                    
[+] Building 0.7s (10/10) FINISHED                                                
 => [internal] load .dockerignore                                            0.0s
 => => transferring context: 2B                                              0.0s
 => [internal] load build definition from Dockerfile                         0.0s
 => => transferring dockerfile: 962B                                         0.0s
 => [internal] load metadata for docker.io/library/nginx:latest              0.5s
 => [1/5] FROM docker.io/library/nginx@sha256:480868e8c8c797794257e2abd88d0  0.0s
 => [internal] load build context                                            0.0s
 => => transferring context: 61B                                             0.0s
 => CACHED [2/5] COPY default.conf /etc/nginx/conf.d/default.conf            0.0s
 => CACHED [3/5] COPY fcgiwrap /etc/default/fcgiwrap                         0.0s
 => CACHED [4/5] RUN apt update && apt install git fcgiwrap -y     && mkdir  0.0s
 => CACHED [5/5] RUN echo "#!/bin/bash" > /srv/git/hw08.git/hooks/post-rece  0.0s
 => exporting to image                                                       0.0s
 => => exporting layers                                                      0.0s
 => => writing image sha256:c57987205e64ade59696b0fc268171272fc3c8759667906  0.0s
 => => naming to docker.io/library/git-server-git                            0.0s
[+] Running 2/2
 ✔ Network git-server_default  Created                                       0.1s 
 ✔ Container git-server-git-1  Started                                       0.5s
```

Git сервер запущено, переходимо до створення репозиторія.


### Git repo

Збирати будемо Docker образ nginx із власним конфігом _([шоста робота](../HW06/README.md))_.

Створимо підкаталог `git` та скопіюємо туди файли `test.conf`, `Dockerfile`, а також створимо файл сценарію — `Jenkinsfile`:
```bash
mkdir ./git
cp ../HW06/{test.conf,Dockerfile} ./git/
touch ./git/Jenkinsfile
```


В результаті у нас має вийде ось така структура:
```bash
tree ./git
./git
├── Dockerfile
├── Jenkinsfile
└── test.conf
```


Створимо Git репозиторій та синхронізуємо його із нашим локальним Git сервером за адресою: http://10.17.3.1:9000/hw08.git
```bash
cd ./git
git init
git add .
git commit -m "Initial commit"
git remote add origin "http://10.17.3.1:9000/hw08.git"
git push -u origin master
```

_* Існує також можливість за допомогою плагіну підняти Git сервер у Jenkins_


## Pipline

Створимо простий сценарій (Pipeline), який повинен:
* завантажити код із [Git репозиторію](README.md#git-repo);
* зібрати Docker образ;
* завантажити його у наше [сховище](README.md#docker-registry).


### Jenkinsfile 

Це вміст нашого `./git/Jenkinsfile`, який має бути залитий разом із іншими файлами у Git репозиторій (URL на який потрібно вказати у самому файлі).
```groovy
pipeline {
    environment {
    dockerRegistry = "http://10.17.3.1:5000"
    gitURL = "http://10.17.3.1:9000/hw08.git"
    imageName = "nginx-test"
    dockerImage = ''
    }
    agent { label 'dev' }
    stages {
        stage('Cloning our Git') {
            steps {
                git "${env.gitURL}"
            }
        }

        stage('Build and Push Docker Image...') {
            steps {
                script {
                  // CUSTOM REGISTRY
                    docker.withRegistry("${env.dockerRegistry}") {

                        /* Build the container image */
                        def dockerImage = docker.build("${env.imageName}:${env.BUILD_ID}")

                        /* Push the container to the custom Registry */
                        dockerImage.push()
                        dockerImage.push("latest")

                    }
                    /* Remove docker image*/
                    sh "docker rmi -f ${env.imageName}:${env.BUILD_ID}"
                }
            }
        }
    }
}

```
Зверніть увагу, що в налаштуваннях `agent`, вказана мітка `dev`, це означає, що для збірки будуть задіяні вузли (агенти), які мають таку мітку. Тобто в нашому випадку буде використаний наш `Worker01`.


Також, якщо ви додали вміст файлу щойно, а не використали одразу готовий, не забудьте зафіксувати зміни:
```bash
git add Jenkinsfile
git commit -m "Update Jenkinsfile"
git push
```


### Pipeline Job
#### Створення завдання у Jenkins
Створюємо [нову Job'у](http://localhost:8989/view/all/newJob)

![](./images/img_301.png)


У діалозі створення задаємо ім’я `BuildDockerImage`, та обираємо тип `Pipeline`

![](./images/img_302.png)


На наступному кроці ставимо відмітку _Trigger builds remotely…_, а в полі _Authentication Token_ пишемо ***GitServer*** (це назва токену, який ми згенерували [раніше](README.md#створення-api-токену)).

![](./images/img_401.png)


Далі скролимо до розділу _Pipeline_.
За замовчанням визначення Pipeline виставлено для використання скрипту. В принципі ми могли просто скопіювати сюди вміст нашого [Jenkinsfile](README.md#jenkinsfile), але зручніше, коли цей скрипт знаходиться в нашому Git репозиторії, де ми можемо з ним працювати.
Тому ми обираємо ***Pipeline script from SCM*** (тобто для виконання Pipeline'у буде використаний скрипт, який розташований у нашому Git (Source code management)).
Власне там де `SCM` обираємо ***Git***.

В `Repository URL` вказуємо посилання на наш репозиторій.

![](./images/img_303.png)


Ще слід звернути увагу, щоб гілка Git співпадала з вашою назвою: за замовчанням стоїть ***master***, а у вас може бути ***main***.
Також `Script Path` має вказувати на наш Jenkinsfile. Оскільки він у нас знаходиться у корені репозиторію, то значення за замовчанням нас влаштовує.

![](./images/img_304.png)


Зберігаємо наші налаштування, натиснувши _Save_.

#### Запуск завдання (Job)
Для запуску завдання натискаємо ***Build Now*** і спостерігаємо за процесом.

![](./images/img_305.png)
![](./images/img_306.png)
![](./images/img_307.png)


Якщо щось пішло не так, або ви просто хочете детальніше ознайомитись із тим, як пройшов весь процес, ви можете переглянути [вивід консолі](http://localhost:8989/job/BuildDockerImage/1/console)

![](./images/img_308.png)
![](./images/img_309.png)
![](./images/img_310.png)


## Тестування

### Build Trigger
Спочатку перевіримо наочним способом чи працює наш тригер для запуску сценарію Jenkins.
Як ви могли помітити, коли ми налаштовували тригер, там з’явилась підказка:
_Use the following URL to trigger build remotely: JENKINS_URL/job/BuildDockerImage/build?token=TOKEN_NAME or /buildWithParameters?token=TOKEN_NAME_

Власне оцей URL можна представити у такому вигляді: `"http://$JENKINS_USER:$TOKEN@$JENKINS_URL/job/$PROJECT/build"`.
Значення змінних наводилось раніше. Ми зараз завантажимо ці змінні та виконаємо запит:
```bash
source ./git-server/.env
curl -X POST "http://$JENKINS_USER:$TOKEN@$JENKINS_URL/job/$PROJECT/build"
```

Повернувшись до Jenkins ми побачимо, що сценарій був відпрацьований ще один раз, а отже наш тригер спрацював.

![](./images/img_402.png)


Перед тим як перевірити автоматичне спрацювання, протестуємо спочатку Docker Registry.


### Registry
Переглянемо вміст нашого Docker Registry:
```bash
curl -s -X GET http://10.17.3.1:5000/v2/_catalog
{"repositories":["nginx-test"]}
```
Як бачимо у нас з’явився новий репозиторій `nginx-test`.


Переглянемо його вміст:
```bash
curl -s -X GET http://10.17.3.1:5000/v2/nginx-test/tags/list
{"name":"nginx-test","tags":["2","latest","1"]}
```
Репозиторій містить збірку із тегами "latest", "1" та "2".


### Створення контейнеру

Спробуємо використати цей образ:
```bash
docker run -d -p 8182:80 --name nginx-test localhost:5000/nginx-test
Unable to find image 'localhost:5000/nginx-test:latest' locally
latest: Pulling from nginx-test
9e3ea8720c6d: Already exists
bf36b6466679: Already exists
15a97cf85bb8: Already exists
9c2d6be5a61d: Already exists
6b7e4a5c7c7a: Already exists
8db4caa19df8: Already exists
e8e342871c60: Pull complete
34c71746f22b: Pull complete
Digest: sha256:62fded933be28c9192c6515bbc43a02e9fe5e2d228f4a1d404fb38d25ef24d1b
Status: Downloaded newer image for localhost:5000/nginx-test:latest
951c65713803a012434550ac782a807da9b3ca41a0759aba178d273cfbca8176
```

### Тест nginx

Тепер запустимо вже знайому нам перевірку:
```bash
for i in {"/","temp_redir","proxy","forbidden","login"}; do                      
      echo "Response for $i :  "`curl -s -I localhost:8182/$i |head -1`
    done

Response for / :  HTTP/1.1 308 Permanent Redirect
Response for temp_redir :  HTTP/1.1 307 Temporary Redirect
Response for proxy :  HTTP/1.1 200 OK
Response for forbidden :  HTTP/1.1 403 Forbidden
Response for login :  HTTP/1.1 401 Unauthorized

curl -s -I -u testuser:test1234 localhost:8182/login |head -1
HTTP/1.1 404 Not Found
```

Результати тесту ідентичні до результатів у _([шостій роботі](../HW06/README.md#тестування))_, тобто ми зібрали той самий образ, використовуючи Jenkins Pipeline.


### Automatic Build Trigger

Настав час одкровення. Ми маємо перевірити чи буде відбуватися збірка автоматично після внесення змін до репозиторію на Git-сервері.

Тож перейдемо до нашого каталогу із Git та змінимо, наприклад конфігураційний файл nginx так, щоб на запит по шляху _temp_redir_ він видавав не 307, а 301:
```
cd git
sed -i 's/return 307/return 301/' test.conf
```

Зафіксуємо зміни:
```bash
git commit -am "Set Return code 301 for temp_redir location"
[master bb5e8a2] Set Return code 301 for temp_redir location
 1 file changed, 1 insertion(+), 1 deletion(-)
```


Та відправимо їх на сервер:

```bash
git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 303 bytes | 303.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote:   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
remote:                                  Dload  Upload   Total   Spent    Left  Speed
remote:   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
To http://10.17.3.1:9000/hw08.git
   ae61d2b..bb5e8a2  master -> master
```


Після цього ми можемо спостерігати у Jenkins, як збірка запустилася втретє.

![](./images/img_403.png)


Отже наш автоматичний тригер працює!


Можемо заглянути у консольний вивід, і переконатися, що наші зміни були задіяні:


![](./images/img_404.png)


Проте залишилась ще одна перевірка.

Нам потрібно зібрати наш тестовий образ nginx наново та перевірити, чи потрапили туди наші зміни.

Спочатку зупинимо контейнер та видалимо його:
```bash
docker stop nginx-test
docker rm nginx-test
```

Тепер смикнемо останній зібраний образ із нашого Registry та запустимо новий контейнер:
```bash
docker pull localhost:5000/nginx-test
docker run -d -p 8182:80 --name nginx-test localhost:5000/nginx-test
```

Запускаємо ще раз наш тест:
```bash
for i in {"/","temp_redir","proxy","forbidden","login"}; do
      echo "Response for $i :  "`curl -s -I localhost:8182/$i |head -1`
    done
Response for / :  HTTP/1.1 308 Permanent Redirect
Response for temp_redir :  HTTP/1.1 301 Moved Permanently
Response for proxy :  HTTP/1.1 200 OK
Response for forbidden :  HTTP/1.1 403 Forbidden
Response for login :  HTTP/1.1 401 Unauthorized
```

І отримуємо відповідь _301 Moved Permanently_ — що відповідає нашим змінам у Git!


ПЕРЕМОГА!

