MODULE vpkResolver;
IMPORT Out, StringList, vpkdepTree;

TYPE
   pstr = StringList.pstring;
   Tdep = vpkdepTree.Tdep;
  Tdeps = vpkdepTree.Tdeps;

  TdepTree = vpkdepTree.TdepTree;

VAR rtvr: vpkdepTree.retriever;

PROCEDURE treeContains(VAR d: Tdep; VAR depTree: TdepTree): BOOLEAN;
VAR
  res: BOOLEAN;
  i: INTEGER;
  d2: Tdep;
BEGIN
  res := FALSE;
  i := 0;
  REPEAT
    d2 := depTree.Get(depTree, i);
    IF d2 # NIL THEN
      IF d = d2 THEN res := TRUE END;
      (*IF d.name^ = d2.name^ THEN res := TRUE END *)
    END;
    INC(i)
  UNTIL res OR (i >= depTree.Count);
  RETURN res;
END treeContains;

PROCEDURE treeContainsByName(VAR d: Tdep; VAR depTree: TdepTree): BOOLEAN;
VAR
  res: BOOLEAN;
  i: INTEGER;
  d2: Tdep;
BEGIN
  res := FALSE;
  i := 0;
  REPEAT
    d2 := depTree.Get(depTree, i);
    IF d2 # NIL THEN
      IF d.name^ = d2.name^ THEN res := TRUE END;
      (*IF d.name^ = d2.name^ THEN res := TRUE END *)
    END;
    INC(i)
  UNTIL res OR (i >= depTree.Count);
  RETURN res;
END treeContainsByName;


PROCEDURE mkDepTree(VAR d: Tdep; VAR depTree, met: TdepTree);
VAR
  depStrs: StringList.TStringList;
  t: Tdep;
  deps: Tdeps;
  p: pstr;
  i: INTEGER;
  rtrvRes: LONGINT;
BEGIN
  vpkdepTree.Add(met, d);
    IF d.RetrieveDeps = NIL THEN Out.String("dep retriever method not installed"); Out.Ln; HALT(1) END;
    rtrvRes := d.RetrieveDeps(d, depStrs);
    IF rtrvRes = -1 THEN
      Out.Ln; Out.String("package named "); Out.String(d.name^); Out.String(" not found in the tree"); Out.Ln; HALT(61);
    END;
    IF rtrvRes = -2 THEN
      Out.Ln; Out.String(d.name^); Out.String(".json malformed: no 'Package' section."); Out.Ln;
      HALT(62);
    END;
    IF depStrs # NIL THEN
    (*IF rtrvRes > 0 THEN*)
      NEW (deps, depStrs.Count);
      i := 0;
      REPEAT
        p := depStrs.GetString(depStrs, i);
        IF p # NIL THEN
          t := NIL;
          t := met.GetByName(met, p^);
          IF t = NIL THEN
            t := vpkdepTree.CreateDep(p^);
            t.InstallRetriever(t, rtvr);
          END;
          deps[i] := t;
          IF ~treeContainsByName(t, depTree) THEN
            IF treeContainsByName(t, met) THEN
              Out.Ln; Out.String("curcular dependency: ");
              Out.String(d.name^); Out.String(" requires "); Out.String(t.name^); Out.Ln;
              Out.String("unable to continue."); Out.Ln;
              HALT(60)
            ELSE
              mkDepTree(t, depTree, met);
            END;
          END;
        END;
        INC(i);
      UNTIL i = depStrs.Count;
      d.AssignDeps(d, deps);
    END;
  vpkdepTree.AddCopy(depTree, d);
END mkDepTree;

PROCEDURE resolve*(first: ARRAY OF CHAR; r: vpkdepTree.retriever): TdepTree;
VAR
  depTree: TdepTree;
  met: TdepTree;
  dep:  Tdep;
BEGIN
  rtvr := r;
  depTree := vpkdepTree.Create();
  met := vpkdepTree.Create(); (* for deps that we already met *)
  dep := vpkdepTree.CreateDep(first);
  dep.InstallRetriever(dep, rtvr);
  mkDepTree(dep, depTree, met);
  RETURN depTree
END resolve;

END vpkResolver.
