//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ITokensApprover.sol";

contract TokensApprover is ITokensApprover, Ownable {
    // Contains data for issuing permissions for the token
    mapping(uint256 => ApproveConfig) private _configs;
    uint256 private _configsLength = 0;
    // Contains methods for issuing permissions for tokens
    mapping(address => uint256) private _tokens;

    constructor(ApproveConfig[] memory configs) {
        for (uint256 i = 0; i < configs.length; i++) {
            _addConfig(configs[i]);
        }
    }

    function addConfig(ApproveConfig calldata config) external onlyOwner returns (uint256) {
        return _addConfig(config);
    }

    function setConfig(uint256 id, ApproveConfig calldata config) external onlyOwner returns (uint256) {
        return _setConfig(id, config);
    }

    function setToken(uint256 id, address token) external onlyOwner {
        _setToken(id, token);
    }

    function getConfig(address token) view external returns (ApproveConfig memory) {
        return _getConfig(token);
    }

    function getConfigById(uint256 id) view external returns (ApproveConfig memory) {
        require(id < _configsLength, "Approve config not found");
        return _configs[id];
    }

    function configsLength() view external returns (uint256) {
        return _configsLength;
    }

    function hasConfigured(address token) view external returns (bool) {
        return _tokens[token] > 0;
    }

    function callPermit(address token, bytes calldata permitCallData) external returns (bool, bytes memory) {
        ApproveConfig storage config = _getConfig(token);
        bytes4 selector = _getSelector(permitCallData);

        require(config.permitMethodSelector == selector, "Wrong permit method");

        return token.call(permitCallData);
    }

    function _addConfig(ApproveConfig memory config) internal returns (uint256) {
        _configs[_configsLength++] = config;
        return _configsLength;
    }

    function _setConfig(uint256 id, ApproveConfig memory config) internal returns (uint256) {
        require(id <= _configsLength, "Approve config not found");
        _configs[id] = config;
        return _configsLength;
    }

    function _setToken(uint256 id, address token) internal {
        require(token != address(0), "Invalid token address");
        require(id <= _configsLength, "Approve config not found");

        _tokens[token] = id + 1;
    }

    function _getConfig(address token) view internal returns (ApproveConfig storage) {
        require(_tokens[token] > 0, "Approve config not found");
        return _configs[_tokens[token] - 1];
    }

    function _getSelector(bytes memory data) pure private returns (bytes4 selector) {
        require(data.length >= 4, "Data to short");

        assembly {
            selector := mload(add(data, add(0, 32)))
            // Clean the trailing bytes.
            selector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
    }
}
