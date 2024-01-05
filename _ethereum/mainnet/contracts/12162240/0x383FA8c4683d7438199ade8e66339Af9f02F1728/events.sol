pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogCreateAndMigrate(
        address indexed currentDsa,
        address indexed newData,
        string[] targets,
        bytes[] calldatas
    );

    event LogMigrate(
        address indexed currentDsa,
        address indexed newData,
        string[] targets,
        bytes[] calldatas
    );
}