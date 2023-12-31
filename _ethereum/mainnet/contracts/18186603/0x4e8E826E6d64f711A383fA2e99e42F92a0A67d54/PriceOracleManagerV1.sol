// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControlEnumerable.sol";
import "./IPriceOracleManager.sol";
import "./IPriceConsumer.sol";

contract PriceOracleManagerV1 is IPriceOracleManager, AccessControlEnumerable {
    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    address[] public oracles;

    uint256 public validPriceDuration = 3 hours;

    mapping(address => uint256) private _tokenPrices;
    mapping(address => uint256) private _tokenTimestamps;
    mapping(address => uint256) private _tokenPriceDecimals;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addOracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracles.push(oracle);
    }

    function fetchPriceInUSD(address token) external override onlyRole(ORACLE_MANAGER_ROLE) {
        uint256 minTimestamp = block.timestamp - validPriceDuration;
        for (uint256 i = 0; i < oracles.length; i++) {
            IPriceConsumer oracle = IPriceConsumer(oracles[i]);
            try oracle.fetchPriceInUSD(token, minTimestamp) {
                (uint256 price, uint256 decimals, uint256 timestamp) = oracle.getPriceInUSD(token);
                if (block.timestamp - timestamp > validPriceDuration) {
                    // too old, look at the next oracle
                    continue;
                }
                // Consumers
                if (price == 0) continue;
                _tokenPrices[token] = price;
                _tokenTimestamps[token] = timestamp;
                _tokenPriceDecimals[token] = decimals;
                break;
            } catch {
                // oracle failed, look at the next oracle
                continue;
            }
        }
    }

    function getPriceInUSD(address token, uint256 expectedDecimals) external view override returns (uint256 price) {
        uint256 decimals = _tokenPriceDecimals[token];
        price = _tokenPrices[token];
        if (price == 0 || _tokenTimestamps[token] == 0 || block.timestamp - _tokenTimestamps[token] > validPriceDuration) {
            for (uint256 i = 0; i < oracles.length; i++) {
                IPriceConsumer oracle = IPriceConsumer(oracles[i]);
                (uint256 _price, uint256 _decimals, uint256 _timestamp) = oracle.getPriceInUSD(token);
                if (block.timestamp - _timestamp <= validPriceDuration) {
                    price = _price;
                    decimals = _decimals;
                    break;
                }
            }
            // no prices found
            if (price == 0) return 0;
        }
        if (decimals < expectedDecimals) {
            price = price * (10**(expectedDecimals - decimals));
        } else if (decimals > expectedDecimals) {
            price = price / (10**(decimals - expectedDecimals));
        }
    }

    function getOracles() external view returns (address[] memory) {
        return oracles;
    }

    function removeOracle(uint256 index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (index != oracles.length - 1) {
            oracles[index] = oracles[oracles.length - 1];
        }
        oracles.pop();
    }

    function setValidPriceDuration(uint256 duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validPriceDuration = duration;
    }
}
