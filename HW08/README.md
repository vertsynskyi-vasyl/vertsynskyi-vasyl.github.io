## Завдання

1. Setup your Jenkins instance
2. Configure a connected agent
3. Create a pipeline that builds Docker image from the homework #6
4. Provide your screenshots that demonstrates console output of Jenkins

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
_* важливий момент: контейнер Jenkins має знаходитись в мережі відмінній від мережі за замовчуванням, яка не дозволяє автоматично розв’язку DNS; у моєму випадку я створюю окрему мережу `dev_net`

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


На наступному кроці я зміню значення `Jenkins URL` з _http://localhost:8989/_ на _http://10.17.3.1:8989/_, використавши таким чином локальну мережеву адресу, я зробив доступним Jenkins з локальної мережі, що може знадобиться у майбутньому для використання тригерів.
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


## Створення агента для Jenkins
### Розгортання агента
Розгорнемо додаткову віртуальну машину `dev-worker01` за допомогою Terraform, використовуючи конфігурацію із [четвертої роботи](../HW04/README.md).
Вона буде доступна в мережі за ім’ям dev-worker01.dev.local.

### Налаштування агента
Використовуючи налаштування Ansible із [п’ятої роботи](../HW05/README.md), створимо нову роль `worker`, яка буде задіювати необхідну конфігурацію машини для наших збірок.

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
Збирати будемо Docker образ nginx із власним конфігом _([шоста робота](../HW06/README.md))_.
Створимо підкаталог `git` та скопіюємо туди файли `test.conf`, `Dockerfile`, а також створимо файл пайплайну `Jenkinsfile`:
```bash
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
Ці файли потрібно розмістити у вашому Git репозиторії, щоб їх можна було завантажити за посиланням.
Я буду використовувати локальний Git сервер за адресою: http://10.17.3.1:9000/hw08.git
_* Також можна за допомогою плагіну підняти Git сервер у Jenkins_


## Pipline

Створимо простий сценарій (Pipeline), який повинен:
* завантажити код із [Git репозиторію](README.md#git);
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

### Pipeline Job
#### Створення завдання у Jenkins (Job)
Створюємо [нову Job'у](http://localhost:8989/view/all/newJob)
![](./images/img_301.png)

У діалозі створення задаємо ім’я `BuildDockerImage`, та обираємо тип `Pipeline`
![](./images/img_302.png)

На наступному кроці скролимо до розділу _Pipeline_.
За замовчанням визначення Pipeline виставлено для використання скрипта. В принципі ми могли просто скопіювати сюди вміст нашого [Jenkinsfile](README.md#jenkinsfile), але зручніше, коли цей скрипт знаходиться в нашому Git репозиторії, де ми можемо з ним працювати.
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

### Registry
Переглянемо тепер вміст нашого Docker Registry:
```bash
curl -s -X GET http://10.17.3.1:5000/v2/_catalog
{"repositories":["nginx-test"]}
```
Як бачимо у нас з’явився новий репозиторій `nginx-test`.

Переглянемо його вміст:
```bash
curl -s -X GET http://10.17.3.1:5000/v2/nginx-test/tags/list
{"name":"nginx-test","tags":["latest","1"]}
```
Репозиторі містить збірку із тегами "latest" та "1".

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
