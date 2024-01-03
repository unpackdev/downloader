pragma solidity ^0.7.4;

import "./PErc20.sol";
import "./RegistryInterface.sol";

/**
 * @title DeFiPie's PErc20Delegate Contract
 * @notice PTokens which wrap an EIP-20 underlying and are delegated to
 * @author DeFiPie
 */
contract PErc20Delegate is PErc20 {
    /**
     * @notice Construct an empty delegate
     */
    constructor() {}
}