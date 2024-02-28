-- +migrate Up
CREATE TABLE contracts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    network_id INTEGER NOT NULL,
    block_number INTEGER NOT NULL,
    transaction_hash TEXT NOT NULL,
    address TEXT NOT NULL,
    name TEXT NOT NULL,
    license TEXT NOT NULL,
    compiler_version TEXT NOT NULL,
    solgo_version TEXT NOT NULL,
    optimized BOOLEAN NOT NULL,
    optimization_runs INTEGER NOT NULL,
    evm_version TEXT NOT NULL,
    abi TEXT NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    verification_provider TEXT,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    partial BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(network_id, block_number, address)
);


-- +migrate Down
DROP TABLE contracts;