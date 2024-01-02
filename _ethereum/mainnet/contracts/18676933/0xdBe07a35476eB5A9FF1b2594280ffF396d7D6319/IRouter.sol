pragma solidity ^0.8.0;

import "./IRouterConfig.sol";

interface IRouter {
    function strategies(address addr) external view returns (bool);
    // project is keccak256(STRATEGY_NAME)
    function projectWhiteList(bytes32 project, address addr) external view returns (bool);

    function config() external view returns (IRouterConfig);
}
