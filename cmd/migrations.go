package cmd

import (
	"github.com/rubenv/sql-migrate"
	"github.com/unpackdev/inspector/pkg/db"
	"github.com/unpackdev/inspector/pkg/options"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
)

func GetMigrationCommands() []*cli.Command {
	return []*cli.Command{
		&cli.Command{
			Name:  "migrations",
			Usage: "Dataset (database) migration related commands",
			Subcommands: []*cli.Command{
				{
					Name:  "up",
					Usage: "Do the database migrations",
					Action: func(context *cli.Context) error {
						dba, err := db.NewDB(context.Context, options.G())
						if err != nil {
							return err
						}

						migrations := &migrate.FileMigrationSource{
							Dir: options.G().Db.MigrationDir,
						}

						n, err := migrate.Exec(dba.GetDB(), dba.GetDialect(), migrations, migrate.Up)
						if err != nil {
							zap.L().Error(
								"failure to execute database migrations",
								zap.Error(err),
								zap.String("dialect", dba.GetDialect()),
								zap.String("datasource", dba.GetDatasource()),
							)
							return err
						}

						zap.L().Info(
							"Applied new migrations",
							zap.Int("count", n),
							zap.String("dialect", dba.GetDialect()),
							zap.String("datasource", dba.GetDatasource()),
						)

						return nil
					},
				},
				{
					Name:  "down",
					Usage: "Rollback the database migrations",
					Action: func(context *cli.Context) error {
						dba, err := db.NewDB(context.Context, options.G())
						if err != nil {
							return err
						}

						migrations := &migrate.FileMigrationSource{
							Dir: options.G().Db.MigrationDir,
						}

						n, err := migrate.Exec(dba.GetDB(), dba.GetDialect(), migrations, migrate.Down)
						if err != nil {
							zap.L().Error(
								"failure to rollback database migrations",
								zap.Error(err),
								zap.String("dialect", dba.GetDialect()),
								zap.String("datasource", dba.GetDatasource()),
							)
							return err
						}

						zap.L().Info(
							"Database migration rollback successful",
							zap.Int("count", n),
							zap.String("dialect", dba.GetDialect()),
							zap.String("datasource", dba.GetDatasource()),
						)

						return nil
					},
				},
			},
		},
	}
}
