-- +migrate Up
CREATE TABLE functions (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   network_id INTEGER NOT NULL,
   contract_id INTEGER NOT NULL,
   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   UNIQUE(network_id, contract_id)
);


-- +migrate Down
DROP TABLE functions;