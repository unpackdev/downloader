pragma solidity ^0.7.0;

import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Polygon POS Bridge ERC20 Predicate
     */
    address internal constant erc20Predicate = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    /**
     * @dev Polygon POS Bridge Manager
     */
    RootChainManagerInterface internal constant migrator = RootChainManagerInterface(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
}