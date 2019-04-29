_         = require("lodash")
fs        = require("fs")
niv       = require("npm-install-version")
auth      = require("basic-auth")
bodyParser = require("body-parser")
express   = require("express")
http      = require("http")
path      = require("path")
Promise   = require("bluebird")
coffee    = require("@packages/coffee")

args = require("minimist")(process.argv.slice(2))

## make sure we have both versions of react
niv.install("react@16.0.0")
niv.install("react-dom@16.0.0")
niv.install("react@15.6.1")
niv.install("react-dom@15.6.1")

[3500, 3501].forEach (port) ->
  app = express()
  server = http.Server(app)

  app.set("port", port)

  app.set("view engine", "html")

  app.use(require("morgan")({ format: "dev" }))

  app.use(require("cors")())
  app.use(require("compression")())
  app.use(bodyParser.urlencoded({ extended: false }))
  app.use(bodyParser.json())
  app.use(require("method-override")())

  app.head "/", (req, res) ->
    res.sendStatus(200)

  app.get "/timeout", (req, res) ->
    Promise
    .delay(req.query.ms ? 0)
    .then ->
      res.send "<html><body>timeout</body></html>"

  app.get "/node_modules/*", (req, res) ->
    res.sendFile(path.join("node_modules", req.params[0]), {
      root: path.join(__dirname, "../..")
    })

  app.get "/xml", (req, res) ->
    res.type("xml").send("<foo>bar</foo>")

  app.get "/buffer", (req, res) ->
    fs.readFile path.join(__dirname, "../cypress/fixtures/sample.pdf"), (err, bytes) ->
      res.type("pdf")
      res.send(bytes)

  app.get "/basic_auth", (req, res) ->
    user = auth(req)

    if user and (user.name is "cypress" and user.pass is "password123")
      res.send("<html><body>basic auth worked</body></html>")
    else
      res
      .set("WWW-Authenticate", "Basic")
      .sendStatus(401)

  app.get '/json-content-type', (req, res) ->
    res.send({})

  app.get '/invalid-content-type', (req, res) ->
    res.setHeader('Content-Type', 'text/html; charset=utf-8,text/html')
    res.end("<html><head><title>Test</title></head><body><center>Hello</center></body></html>")

  app.all '/dump-method', (req, res) ->
    res.send("<html><body>request method: #{req.method}</body></html>")

  app.post '/post-only', (req, res) ->
    res.send("<html><body>it worked!<br>request body:<br>#{JSON.stringify(req.body)}</body></html>")

  app.get '/dump-headers', (req, res) ->
    res.send("<html><body>request headers:<br>#{JSON.stringify(req.headers)}</body></html>")

  app.get "/status-404", (req, res) ->
    res
    .status(404)
    .send("<html><body>not found</body></html>")

  app.get "/status-500", (req, res) ->
    res
    .status(500)
    .send("<html><body>server error</body></html>")

  cachedCssRules = {}

  ## <link href="/dynamically-sized-css-file/:ruleCount.css" /> will include a stylesheet with 1000 rules
  app.get "/dynamically-sized-css-file/:ruleCount.css", (req, res) ->
    ruleCount = parseInt(req.params.ruleCount, 10);

    if !cachedCssRules[ruleCount]
      ## cache dynamically generated css rules, so they don't slow down any tests
      cachedCssRules[ruleCount] = _.range(1, ruleCount + 1).map((n) -> ".c#{n} { font-size: #{1 + Math.round n/10}px; }").join("\n");

    res.setHeader('Content-Type', 'text/css')
    res.status(200).send(cachedCssRules[ruleCount])

  app.use(express.static(path.join(__dirname, "..", "cypress")))

  app.use(require("errorhandler")())

  server.listen app.get("port"), ->
    console.log("Express server listening on port", app.get("port"))
