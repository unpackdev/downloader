-- +migrate Up
CREATE TABLE contracts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    network_id INTEGER NOT NULL,
    block_number INTEGER NOT NULL,
    block_hash TEXT NOT NULL,
    transaction_hash TEXT NOT NULL,
    address TEXT NOT NULL,
    name TEXT NOT NULL,
    standards TEXT NOT NULL,
    proxy BOOLEAN NOT NULL DEFAULT FALSE,
    license TEXT NOT NULL,
    compiler_version TEXT NOT NULL,
    solgo_version TEXT NOT NULL,
    optimized BOOLEAN NOT NULL,
    optimization_runs INTEGER NOT NULL,
    evm_version TEXT NOT NULL,
    abi TEXT NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    sources_provider TEXT,
    verification_provider TEXT,
    execution_bytecode TEXT,
    bytecode TEXT,
    source_available BOOLEAN NOT NULL DEFAULT FALSE,
    safety_state TEXT NOT NULL,
    self_destructed BOOLEAN NOT NULL DEFAULT FALSE,
    proxy_implementations TEXT,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    partial BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(network_id, block_number, address)
);


-- +migrate Down
DROP TABLE contracts;