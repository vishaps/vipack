MODULE vpkSyncer;
IMPORT Strings, Out,
       strUtils, List,
       vpkSettings, vpkEnv, vpkConf, vpkGit, vpkdepTree, vpkTools, vpkHttps;

PROCEDURE mkTreePath(VAR path: ARRAY OF CHAR);
BEGIN
  vpkEnv.getConfDir(path);
  Strings.Append('/', path);
  Strings.Append(vpkSettings.vpkTreeDir, path);
END mkTreePath;

PROCEDURE sync*;
VAR
  tree: vpkSettings.tree;
BEGIN
  (* Syncing *)
  vpkConf.getConfigTreeVal(tree);
    IF tree.typ = vpkSettings.git THEN
      vpkGit.syncTree(tree.url, tree.branch)
    ELSE
      Out.String("TODO: not a git url"); Out.Ln
    END;
END sync;

PROCEDURE fetch*(VAR dep: vpkdepTree.Tdep; dst: ARRAY OF CHAR);
VAR domain: ARRAY 64 OF CHAR;
BEGIN
  IF dep^.rmt # NIL THEN
    IF dep^.rmt IS vpkdepTree.RemoteGit THEN
      vpkTools.extractDomainFromUrl(dep^.rmt^.URI, domain);
      (* dst is changed by mkdefPkgDirPath and mkPkgdirPath *)
      IF dst = "" THEN
        vpkEnv.mkdefPkgDirPath(domain, dep^.name^, dst);
      ELSE
        vpkEnv.mkPkgDirPath(domain, dep^.name^, dst);
      END;
      vpkGit.fetchRepo(dep^.rmt^.URI, dst, dep^.rmt(vpkdepTree.RemoteGit).branch);
    ELSIF dep^.rmt IS vpkdepTree.RemoteHttps THEN
      (* full dst will be determined in vpkHttps.fetchFiles for each file *)
      vpkHttps.fetchFiles(dep, dst);
    ELSE
      Out.String("TODO: neither git nor https url"); Out.Ln;
      Out.String("not handled");
      Out.Ln;
    END
  ELSE
    Out.String("deps remote is not set, this should not happen"); Out.Ln;
    HALT(5);
  END;
END fetch;

END vpkSyncer.
