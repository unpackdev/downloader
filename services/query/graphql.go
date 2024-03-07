package query

import (
	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/go-chi/chi/v5"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
	"github.com/unpackdev/inspector/pkg/graph"
	"github.com/unpackdev/inspector/pkg/options"
	"go.uber.org/zap"
	"net/http"
	"time"
)

func (s *Service) serveGraphQL() error {
	zap.L().Info(
		"Starting up query service graphql server...",
		zap.String("addr", ":8084"),
	)

	router := chi.NewRouter()
	opts := options.G().Graphql

	cache, err := graph.NewCache(s.ctx, s.cache.GetClient(), opts.Cache.QueryCacheDuration)
	if err != nil {
		zap.L().Info(
			"failure to instantiate new APQ cache instance",
			zap.Error(err),
		)
		return err
	}

	corsManager := cors.New(cors.Options{
		AllowedOrigins:     opts.Cors.AllowedOrigins,
		AllowCredentials:   opts.Cors.AllowCredentials,
		Debug:              opts.Cors.Debug,
		AllowedMethods:     opts.Cors.AllowedMethods,
		MaxAge:             opts.Cors.MaxAge,
		OptionsPassthrough: opts.Cors.OptionsPassthrough,
		AllowedHeaders:     opts.Cors.AllowedHeaders,
	})

	gqlHandler := handler.New(graph.NewExecutableSchema(graph.Config{Resolvers: &graph.Resolver{
		Db:   s.db,
		Nats: s.nats,
	}}))

	if opts.TransportEnabled("ws") {
		gqlHandler.AddTransport(transport.Websocket{
			KeepAlivePingInterval: 10 * time.Second,
			Upgrader: websocket.Upgrader{
				CheckOrigin: func(r *http.Request) bool {
					return true
				},
			},
			/* 		InitFunc: func(ctx context.Context, initPayload transport.InitPayload) (context.Context, error) {
				return webSocketInit(ctx, initPayload)
			}, */
		})
	}

	gqlHandler.AddTransport(transport.Options{})
	gqlHandler.AddTransport(transport.GET{})
	gqlHandler.AddTransport(transport.POST{})
	gqlHandler.Use(extension.AutomaticPersistedQuery{Cache: cache})
	//gqlHandler.AddTransport(transport.MultipartForm{})
	//gqlHandler.SetQueryCache(lru.New(1000))

	gqlHandler.Use(extension.Introspection{})
	//gqlHandler.Use(extension.AutomaticPersistedQuery{
	//	Cache: lru.New(100),
	//})

	//gqlHandler.Use(extension.FixedComplexityLimit(5))

	//router.Use(middlewares.DatabaseMiddleware(s.dbAdapter, gqlHandler))

	router.Handle("/", playground.Handler("(Un)pack Inspector GraphQL Playground", "/query"))
	router.Handle("/query", corsManager.Handler(gqlHandler))

	zap.L().Sugar().Infof("Connect to http://localhost:%s/ for GraphQL playground", opts.Addr)
	return http.ListenAndServe(opts.Addr, router)
}
