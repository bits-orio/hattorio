# Wiki source

These pages are the source for the GitHub wiki. The wiki is a separate git
repository. GitHub creates it only when the first page exists.

**To publish**, first create any page in the web UI at
<https://github.com/vetkat/hattorio/wiki>. Then run:

```bash
make wiki
```

This command clones the wiki repository, copies these files into it and
pushes. Edit the pages here and run the command again. Do not edit them in the
browser. That way the pages get the same review as everything else.
