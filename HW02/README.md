# Git/GitHub

## 1. Create new ~~public~~ repository ~~on GitHub~~ and name it as "DevOps-CrashCourse"
Трохи ускладнимо задачу та виконаємо її без відвідування GitHub'у, тобто повністю із командної строки

Тому спочатку ми створимо локальний репозиторій, а потім опублікуємо його на GitHub'і за допомогою [REST API](https://docs.github.com/en/rest?apiVersion=2022-11-28)

### Задамо змінні:
```bash
# Токен, який можна згененрувати за посиланням: https://github.com/settings/tokens:
GITHUB_TOKEN=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

# Ім’я користувача Github:
GITHUB_USER=vertsynskyi-vasyl

# Назва проєкту:
PROJECT=DevOps-CrashCourse
```

### Створимо проєкт:
```bash
mkdir $PROJECT
cd $PROJECT/
git init
```

## 2. In the README.md file add the following information:
        DevOps Crash Course Lab
        Your Name and Surname
```bash
cat << EOF > README.md
# DevOps Crash Course Lab
Vasyl Vertsynskyi
EOF
git add README.md
git commit -m "Initial commit"
```
## 3. ~~Clone the repository locally~~
Наш репозиторій і так локальний, тому зробимо його публічним.

### Пов’язуємо наш репозиторій із Github
```bash
git remote add origin https://github.com/$GITHUB_USER/$PROJECT
git remote set-url origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$PROJECT.git
```

### Створюємо репозиторій на Github, використовуючи Github's API:
```bash
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos -d '{"name": "'$PROJECT'", "public": "true"}'
```

### Синхронізуємо наш локальний проект із Github
```bash
git push -u origin master
```

## 4. Create a branch named develop
```bash
git branch develop
git checkout develop
```

## 5. Take some template (one you like) from https://html5up.net/ and add it as code into your branch develop
```bash
SITE_PKG=~/Downloads/html5up-forty.zip
unzip $SITE_PKG
```

## 6. Commit changes
```bash
# Додаємо нові файли
git add -A

# Створюємо комміт
git commit -m "Додавання шаблону сайту"
```

## 7. Make some changes into the code to provide your name on the main page and commit changes
Змінимо ім’я на головній сторінці сайту та закоммітимо зміни:
```bash
sed -i 's/my name is Forty/my name is Vasyl/g' index.html
git add index.html
git commit -m "Зміна імені на головній сторінці"
```

## 8. Push the branch 'develop' into remote repository
```bash
git push -u origin develop
```

## 9. Create pull request to merge the develop branch into main
Не дуже розумію для чого робити pull request коли я тут єдиний учасник проєкту, можливо було зробити все локально:
```bash
git checkout master
git pull
git merge develop
git push
```

Проте, якщо стоїть таке завдання, зробимо.

### Створюємо pull request
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_USER/$PROJECT/pulls \
  -d '{"title":"Site is ready","body":"Lets publish it","head":"develop","base":"master"}'
```
### Мержимо:
```bash
PULL_NUMBER=1
curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_USER/$PROJECT/pulls/$PULL_NUMBER/merge \
  -d '{"commit_title":"Site is ready","commit_message":"The first release of our site"}'
```


Успіх!
```yaml
{
  "sha": "50d507b589241ecdcfd5e90a4bafe50174adcb2f",
  "merged": true,
  "message": "Pull Request successfully merged"
}
```

## 10. Using GitHub Pages publish your site

Для публікації сайту за допомогою GitHub Pages потрібно створити публічний репозиторій username.github.io та покласти туди наш сайт


```bash
PROJECT2=$GITHUB_USER.github.io
git remote add pages https://github.com/$GITHUB_USER/$PROJECT2
git remote set-url pages https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$PROJECT2.git
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos -d '{"name": "'$PROJECT2'", "public": "true"}'
git checkout master
git pull origin master
git push pages master
```


Через кілька хвилин можемо перевірити наш сайт за адресою: https://vertsynskyi-vasyl.github.io/

![](./images/img_001.png)


## 11. Make sure everything works, then create a zip-archive of your site and publish it as a release

### Підготовка для створення релізу
Для гарної картинки можемо зробити імітацію роботи над релізом: створимо окрему гілку release-1.0, зробимо в ній певні зміни, з’єднаємо їх згодом із основними гілками і врешті видалимо.

#### Створюємо гілку `release-1.0`
```bash
git checkout -b release-1.0 develop
```
#### Вносимо деякі зміни та фіксуємо їх
```bash
sed -i "s/Forty by HTML5 UP/Vasyl's website/g" index.html
git add index.html
git commit -m "Зміна заголовку головної сторінки"

LOGIN_LINE=`grep -Fn "Log In" index.html | cut --delimiter=":" --fields=1`
sed -i $LOGIN_LINE"d" index.html
git add index.html
git commit -m "Прибираємо кнопку **Log In**"
```
#### Зливаємо гілки та видаляємо гілку `release-1.0`
```bash
git checkout master
git merge --no-edit release-1.0
git push
git checkout develop
git merge --no-edit release-1.0
git push 
git branch -d release-1.0
```
#### Створюємо тег
```bash
TAG="v1.0"
MESSAGE="Перший реліз"
git tag -a $TAG -m $MESSAGE master
git push --tags
```

### Публікуємо реліз на GitHub'і
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_USER/$PROJECT/releases \
  -d '{"tag_name":"'$TAG'","target_commitish":"master","name":"'$TAG'","body":"'$MESSAGE'","draft":false,"prerelease":false,"generate_release_notes":false}'
```

Успіх!
```yaml
{
  "url": "https://api.github.com/repos/vertsynskyi-vasyl/DevOps-CrashCourse/releases/97018321",
  "assets_url": "https://api.github.com/repos/vertsynskyi-vasyl/DevOps-CrashCourse/releases/97018321/assets",
  "upload_url": "https://uploads.github.com/repos/vertsynskyi-vasyl/DevOps-CrashCourse/releases/97018321/assets{?name,label}",
  "html_url": "https://github.com/vertsynskyi-vasyl/DevOps-CrashCourse/releases/tag/v1.0",
  "id": 97018321,
  "author": {
    "login": "vertsynskyi-vasyl",
    "id": 114148088,
    "node_id": "U_kgDOBs3C-A",
    "avatar_url": "https://avatars.githubusercontent.com/u/114148088?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/vertsynskyi-vasyl",
    "html_url": "https://github.com/vertsynskyi-vasyl",
    "followers_url": "https://api.github.com/users/vertsynskyi-vasyl/followers",
    "following_url": "https://api.github.com/users/vertsynskyi-vasyl/following{/other_user}",
    "gists_url": "https://api.github.com/users/vertsynskyi-vasyl/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/vertsynskyi-vasyl/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/vertsynskyi-vasyl/subscriptions",
    "organizations_url": "https://api.github.com/users/vertsynskyi-vasyl/orgs",
    "repos_url": "https://api.github.com/users/vertsynskyi-vasyl/repos",
    "events_url": "https://api.github.com/users/vertsynskyi-vasyl/events{/privacy}",
    "received_events_url": "https://api.github.com/users/vertsynskyi-vasyl/received_events",
    "type": "User",
    "site_admin": false
  },
  "node_id": "RE_kwDOJOj9WM4FyGHR",
  "tag_name": "v1.0",
  "target_commitish": "master",
  "name": "v1.0",
  "draft": false,
  "prerelease": false,
  "created_at": "2023-03-27T11:49:19Z",
  "published_at": "2023-03-27T12:04:11Z",
  "assets": [

  ],
  "tarball_url": "https://api.github.com/repos/vertsynskyi-vasyl/DevOps-CrashCourse/tarball/v1.0",
  "zipball_url": "https://api.github.com/repos/vertsynskyi-vasyl/DevOps-CrashCourse/zipball/v1.0",
  "body": "Перший реліз"
}
```


## 12. Provide your links on your GitHub repository and published site
* https://github.com/vertsynskyi-vasyl/DevOps-CrashCourse
* https://vertsynskyi-vasyl.github.io/
