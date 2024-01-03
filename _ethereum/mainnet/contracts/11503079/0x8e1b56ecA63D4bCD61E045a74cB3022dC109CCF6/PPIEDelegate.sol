pragma solidity ^0.7.4;

import "./PPIE.sol";
import "./RegistryInterface.sol";

/**
 * @title DeFiPie's PPIEDelegate Contract
 * @notice PTokens which wrap an EIP-20 underlying and are delegated to
 * @author DeFiPie
 */
contract PPIEDelegate is PPIE {
    /**
     * @notice Construct an empty delegate
     */
    constructor() {}
}