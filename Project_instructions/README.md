# Project Red Cross
This repository provides a basic structure for collaborating with your teammates on project Red Cross. Read the following content carefully to understand the file structure as well as how to work with git and PostgreSQL. 

I strongly suggest you consult the provided tutorials on Python, Pandas, PostgreSQL, and psycopg2. Most of what you need to get started with the project are covered [here](https://version.aalto.fi/gitlab/databases_projects/cs_a1155-summer-2024/python-tutorials).

We do not enforce the use of Git for collaboration in this course. 

## How to work with git

Here's a list of recommended next steps to make it easy for you to get started with the project. However, understanding the concept of git workflow and git fork is necessary and essential. 

-   [Create a fork of this official repository](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
-   [Add a SSH key to your gitlab account](https://docs.gitlab.com/ee/user/ssh.html#add-an-ssh-key-to-your-gitlab-account)
-   Clone the fork to your local repository
```
git clone git@version.aalto.fi<your-teammate-name>/<project-repo-name>.git
```
-   [Add a remote to keep your fork synced with the official repository](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#repository-mirroring)
```
git remote add upstream git@version.aalto.fi:databases_projects/cs_a1155-summer-2024/project-red-cross.git
git pull upstream main                                  # if the official repository is updated you must pull the upstream
git push origin main                                    # Update your public repository
```

### Git guideline
-   [Feature branch workflow](https://docs.gitlab.com/ee/gitlab-basics/feature_branch_workflow.html)
-   [Feature branch development](https://docs.gitlab.com/ee/topics/git/feature_branch_development.html)
-   [Add files to git repository](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line)
 
## **Postgre SQL database**

In this course, A+ exercises are given and done in PostgreSQL and it will also be the choice of database for the project. PostgreSQL, like most other practical database system, is a client/server-based database. To understand more about working with PostgreSQL, it is advisable to browse thorugh the [documentation](https://www.postgresql.org/docs/) or watch this [tutorial](https://www.youtube.com/watch?v=qw--VYLpxG4). 
    
In order to avoid git conflicts when multiple team members write to a shared database, it is advisable that each team member creates their own project database on local machine for testing. You can skip pushing the PostgreSQL database to group repository by adding ```project_database.db``` file to ```.gitignore```. In development phase, you only need to push the code for creating and querying the database. The code updates will only affect your local database.

Once there are no need to edit the database file, you can push it to group repository, under database folder. 
    


