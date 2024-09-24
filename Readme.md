# These are the things I did
```
docker build --tag 'rjramos/vscode-macrosystems' ./
docker run -it --init -p 3000:3000 rjramos/vscode-macrosystems
docker image push rjramos/vscode-macrosystems:latest
```

# How to set this up as a tool on cyverse
1. Set working directory to `/home/workspace/data-store/`
2. Set UID to `1000`

# Some important notes
1. Cyverse data-store home is located `/home/workspace/data-store/home/$IPLANT_USER`