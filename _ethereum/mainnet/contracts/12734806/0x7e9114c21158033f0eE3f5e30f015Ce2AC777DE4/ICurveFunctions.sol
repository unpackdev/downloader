pragma solidity ^0.8.0;

interface ICurveFunctions {
    function get_registry() external view returns (address);

    function get_address(uint256) external view returns (address);

    function get_n_coins(address) external view returns (uint256[2] calldata);

    function get_coins(address) external view returns (address[8] calldata);

    // Address IDs
    // 0: The main registry contract. Used to locate pools and query information about them.

    // 1: Aggregate getter methods for querying large data sets about a single pool. Designed for off-chain use.

    // 2: Generalized swap contract. Used for finding rates and performing exchanges.

    // 3: The metapool factory.

    // 4: The fee distributor. Used to distribute collected fees to veCRV holders.
}
