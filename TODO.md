# Things To Do - Thoughts Drop

List of the things that will become issues in downloader unless they are fixed before including questions
that I should not forget.

- [ ] Getting solgo branch merged into main... This will be painful :joy: It's project on its own...
- [ ] Potential to be more than downloader, should the name of the project be kept like this or perhaps 'unpack-lite'?
- [ ] Keep the downloading state and ability to resume from the latest downloaded state.
- [ ] Dockerization of the service
- [ ] Documentation on how to manage and configure service
- [ ] Do I want to have here rpc client? It's faster but is it necessary if we have graphql client package?
- [ ] How to do E2E, regression, unit tests? Currently none of them are done...
- [ ] Benchmarking? 
- [x] Data compression endpoints and solutions? Z7 has ability to append to the archive, should we use that? Sounds like a way to go...
- [ ] Query service. Perhaps we don't want to have all the service started at once and instead separate them by the job type?
- [ ] For querying service, ability to do authentication? Sounds like a good thing to do as it can be exposed to public without fear of illegal access.
- [ ] On above note, CORS, RateLimiter, etc...
- [ ] Graphana, Prometheus, etc... Basically observability solution for production environments.
- [x] Pprof...

## Project Name Ideas

Not sure if I want to change the name of this project but it looks like we could. It's not only downloading the data
but parses, provides information about functions, constructor, events, tokens, etc...

With that in mind, here's a list of potential repo name ideas:

- [x] Inspector
- [ ]UnpackLite (it's probably the best name but it sucks...)

**It's now inspector and will stay like that.**