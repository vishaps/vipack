MODULE vpkConf;
IMPORT Out, Files, Strings, Platform,
       vpkSettings, vpkEnv, Json;

CONST
   open = '{"';
  close = '"}';
     is = '": "';
 newkey = '", "';

PROCEDURE mkConfContent(VAR path: ARRAY OF CHAR);
(* constructing the line like:
{"Path" : "https://github.com/vishaps/vipackTree"}, "Type" : "git"}
*)
BEGIN
  COPY("", path);
  Strings.Append(open,  path);
  Strings.Append(vpkSettings.rmtTreeKey, path);
  Strings.Append(is,    path);
  Strings.Append(vpkSettings.defTreeVal,   path);
  Strings.Append(newkey, path);
  Strings.Append(vpkSettings.rmtTypKey,   path);
  Strings.Append(is,    path);
  Strings.Append(vpkSettings.defTypVal,    path);
  Strings.Append(close, path);
END mkConfContent;

PROCEDURE mkDefConfig*;
VAR
  content: ARRAY 96 OF CHAR;
  f: Files.File;
  r: Files.Rider;
BEGIN
    vpkEnv.checkEnv;
    f := vpkEnv.getConfFile();
    Files.Set(r, f, 0);
    mkConfContent(content);
    Files.WriteBytes(r, content, Strings.Length(content));
    Files.Register(f);
    Files.Close(f);
END mkDefConfig;

PROCEDURE configured*(): BOOLEAN;
BEGIN
  RETURN vpkEnv.checkConfig()
END configured;
(*
PROCEDURE getConfigTreeVal*(VAR tree: vpkSettings.tree);
VAR
  f: Files.File; r: Files.Rider;
  dt: ARRAY 256 OF CHAR;
  i : INTEGER; ch: CHAR;
  jsonRecord : vpkJsonParser.JsonTypePointer;
  b: BOOLEAN;
  treeTyp: ARRAY 8 OF CHAR;
  branch: ARRAY 128 OF CHAR;
BEGIN
  COPY("", tree.branch);
  COPY("", tree.url);
  COPY("", branch);
  f := vpkEnv.getConfFile();
  Files.Set(r, f, 0);
  i := 0;
  WHILE ~ r.eof & (i < LEN(dt)) DO Files.Read(r, ch); dt[i] := ch; INC(i) END;
  Files.Close(f);
  jsonRecord := vpkJsonParser.Create(dt);
  b := vpkJsonParser.GetTerminal(jsonRecord, vpkSettings.rmtTreeKey, tree.url);
  IF ~b THEN Out.String("unable to read "); Out.String (vpkSettings.rmtTreeKey); Out.String(" from json"); Out.Ln; HALT(1); END;
  b := vpkJsonParser.GetTerminal(jsonRecord, vpkSettings.rmtTypKey, treeTyp);
  IF ~b THEN Out.String("unable to read "); Out.String (vpkSettings.rmtTypKey); Out.String(" from json"); Out.Ln; HALT(1); END;
  IF treeTyp = vpkSettings.rmtTypGitVal THEN
    tree.typ := vpkSettings.git;
    b := vpkJsonParser.GetTerminal(jsonRecord, vpkSettings.rmtTreeBranchKey, branch);
    IF ~b THEN COPY("", tree.branch) ELSE COPY(branch, tree.branch) END;
  ELSIF treeTyp = vpkSettings.rmtTypHttpVal THEN
    tree.typ := vpkSettings.http
  ELSE
    tree.typ := vpkSettings.unkn;
  END;
END getConfigTreeVal;
*)

PROCEDURE getConfigTreeVal*(VAR tree: vpkSettings.tree);
CONST
  defConfSize=512;
VAR
  f: Files.File; r: Files.Rider;
  jsonstr, errstr: Json.jString;
  jsonTree, pathValue, typeValue, branchValue: Json.Value;
  rootObj: Json.Obj;
  Path, Type, Git, HTTP: Json.jString;
  b: BOOLEAN;
  i: INTEGER;
BEGIN
  COPY("", tree.branch);
  COPY("", tree.url);

  f := vpkEnv.getConfFile();
  Files.Set(r, f, 0);
  NEW(jsonstr, defConfSize);
  NEW(errstr, 4096);  (* Adjust size as needed *)
  i := 0;
  REPEAT
    Files.Read(r, jsonstr^[i]);
    INC(i)
  UNTIL r.eof OR (i>=LEN(jsonstr^));
  Files.Close(f);
  b := Json.Parse(jsonTree, jsonstr^, errstr^);
  IF b THEN
    IF jsonTree IS Json.Obj THEN
      rootObj := jsonTree(Json.Obj);
      NEW(Path, Strings.Length(vpkSettings.rmtTreeKey)+1);
      COPY(vpkSettings.rmtTreeKey, Path^);

      IF Json.ObjSelect(pathValue, rootObj, Path) THEN
        IF pathValue IS Json.Str THEN
         (*this crashes voc *)
         (* tree.url := pathValue(Json.Str).str^;*)
         COPY(pathValue(Json.Str).str^, tree.url);
        END;
      END;


      NEW(Type, Strings.Length(vpkSettings.rmtTypKey)+1);
      COPY(vpkSettings.rmtTypKey, Type^);
      IF Json.ObjSelect(typeValue, rootObj, Type) THEN
        IF typeValue IS Json.Str THEN
          NEW(Git, Strings.Length(vpkSettings.rmtTypGitVal)+1);
          NEW(HTTP, Strings.Length(vpkSettings.rmtTypHttpVal)+1);
          IF typeValue(Json.Str).str^ = "git" THEN
            tree.typ := vpkSettings.git;
          ELSIF typeValue(Json.Str).str^ = "http" THEN
            tree.typ := vpkSettings.http;
          ELSE
            tree.typ := vpkSettings.unkn;
          END;
        END;
      END;

    ELSE
      Out.String("JSON root is not an object."); Out.Ln;
    END;
  ELSE
    Out.String("JSON parsing failed: "); Out.String(errstr^); Out.Ln;
  END;
END getConfigTreeVal;


PROCEDURE setTreeDir*(VAR a: ARRAY OF CHAR);
BEGIN
  vpkEnv.setTreeDir(a)
END setTreeDir;

END vpkConf.
