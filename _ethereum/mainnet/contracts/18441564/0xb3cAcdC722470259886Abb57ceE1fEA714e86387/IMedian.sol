pragma solidity 0.8.17;

interface IMedian {
    function age() external view returns (uint32); // Last update timestamp

    function read() external view returns (uint256); // Latest price feed value (reverted if not valid)

    function peek() external view returns (uint256, bool); // Latest price feed value and validity

    // Other Median functions we don't need.
    // function wards(address) external view returns (uint256); // Authorized owners

    // function rely(address) external; // Add authorized owner

    // function deny(address) external; // Remove authorized owner

    // function wat() external view returns (bytes32); // Price feed identifier

    // function bar() external view returns (uint256); // Minimum number of oracles

    // function orcl(address) external view returns (uint256); // Authorized oracles

    // function bud(address) external view returns (uint256); // Whitelisted contracts to read price feed

    // function slot(uint8) external view returns (address); // Mapping for at most 256 oracles

    // function poke(
    //     uint256[] calldata,
    //     uint256[] calldata,
    //     uint8[] calldata,
    //     bytes32[] calldata,
    //     bytes32[] calldata
    // ) external; // Update price feed values

    // function lift(address[] calldata) external; // Add oracles

    // function drop(address[] calldata) external; // Remove oracles

    // function setBar(uint256) external; // Set minimum number of oracles

    function kiss(address) external; // Add contract to whitelist

    // function diss(address) external; // Remove contract from whitelist

    // function kiss(address[] calldata) external; // Add contracts to whitelist

    // function diss(address[] calldata) external; // Remove contracts from whitelist
}
