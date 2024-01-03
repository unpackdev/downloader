pragma solidity ^0.7.4;

import "./PEther.sol";
import "./RegistryInterface.sol";

/**
 * @title DeFiPie's PEtherDelegate Contract
 * @notice PTokens which wrap are delegated to
 * @author DeFiPie
 */
contract PEtherDelegate is PEther {
    /**
     * @notice Construct an empty delegate
     */
    constructor() {}
}