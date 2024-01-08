// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "AccessControl.sol";
import "AggregatorV3Interface.sol";


contract GasPriceConsumer is AccessControl {
    // roles
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");

    address public gasPriceFeed;
    int public defaultGasPrice;

    /**e
     * Network: Ethereum Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */

    // Mainnet fast ags
     // Address: 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C

    constructor(address owner, address manager) {
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
    }

    function setChainLinkGasPriceFeed(address _gasPriceFeed) external onlyRole(ROLE_MANAGER) {
        gasPriceFeed = _gasPriceFeed;
    }

    function setDefaultGasPrice(int _gasPrice) external onlyRole(ROLE_MANAGER) {
        defaultGasPrice = _gasPrice;
    }

    function getLatestGasPriceFromPriceFeed() internal view returns (int) {
        (
            uint80 roundID,
            int gasPrice,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(gasPriceFeed).latestRoundData();
        return gasPrice;
    }

    function getDefaultGasPrice() internal view returns (int) {
        return defaultGasPrice;
    }

    function getLatestGasPrice() public view returns (int) {
        if (gasPriceFeed != address(0)) {
            return getLatestGasPriceFromPriceFeed();
        } else {
            int gasPrice = getDefaultGasPrice();
            require(gasPrice > 0, "ERR_DEFAULT_GAS_PRICE_NOT_SET");
            return gasPrice;
        }
    }
}
