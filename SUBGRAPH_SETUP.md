# Subgraph Setup Guide

## Tách riêng Subgraph Repository

Subgraph đã được setup như một **separate git repository** để tránh conflicts với main contracts repo.

### Current Setup

1. **Subgraph Directory**: `/subgraph/` đã được add vào `.gitignore` của main repo
2. **Separate Repo**: https://github.com/Debt-Purchasing/debt-purchasing-subgraph.git
3. **Local Access**: Vẫn có thể develop locally trong `/subgraph/` folder

### Working with Subgraph

#### 1. Local Development

```bash
# Làm việc trong subgraph directory
cd subgraph

# Install dependencies (nếu cần)
npm install

# Code changes vào subgraph files
# ...

# Commit và push vào separate repo
git add .
git commit -m "Your changes"
git push origin main
```

#### 2. Fresh Clone

```bash
# Clone main contracts repo
git clone https://github.com/Debt-Purchasing/debt-purchasing-contracts.git
cd debt-purchasing-contracts

# Clone subgraph vào đúng vị trí
git clone https://github.com/Debt-Purchasing/debt-purchasing-subgraph.git subgraph
```

#### 3. Sync Changes

```bash
# In subgraph directory
cd subgraph
git pull origin main

# Main repo sẽ không track subgraph changes
cd ..
git status # Sẽ không hiện subgraph changes
```

### Benefits

✅ **No Conflicts**: Subgraph changes không làm "dirty" main repo  
✅ **Separate History**: Subgraph có commit history riêng  
✅ **Easy Management**: Có thể deploy subgraph độc lập  
✅ **Local Testing**: Vẫn có thể test integration locally

### Structure

```
debt-purchasing-contracts/
├── src/              # Smart contracts
├── script/           # Deployment scripts
├── subgraph/         # -> Separate git repo (ignored by main)
│   ├── .git/         # -> Points to debt-purchasing-subgraph
│   ├── src/          # Subgraph source
│   ├── schema.graphql
│   └── subgraph.yaml
└── .gitignore        # Contains "subgraph/"
```

### Notes

- Subgraph directory `subgraph/` is ignored in main repo's `.gitignore`
- Changes in `/subgraph/` will not appear in main repo's `git status`
- Each repo can be developed and deployed independently
- For full project setup, clone both repositories
