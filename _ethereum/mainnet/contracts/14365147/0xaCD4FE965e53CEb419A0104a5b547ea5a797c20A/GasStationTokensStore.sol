//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IGasStationTokensStore.sol";

contract GasStationTokensStore is IGasStationTokensStore, Ownable {
    // Fee Tokens Storage
    mapping(address => bool) private feeAllowedTokens;
    address[] private feeTokensAddresses;
    mapping(address => uint256) private feeTokensAddressesIndexes;

    constructor(address[] memory _feeTokens) {
        for (uint256 i = 0; i < _feeTokens.length; i++) {
            _addFeeToken(_feeTokens[i]);
        }
    }

    function feeTokens() external view returns (address[] memory) {
        return feeTokensAddresses;
    }

    function isAllowedToken(address _token) external view returns (bool) {
        return feeAllowedTokens[_token];
    }

    function addFeeToken(address _token) external onlyOwner {
        require(_token != address(0), 'Cannot use zero address');
        require(!feeAllowedTokens[_token], 'Token already allowed');

        _addFeeToken(_token);
    }

    function removeFeeToken(address _token) external onlyOwner {
        require(_token != address(0), 'Cannot use zero address');
        require(feeAllowedTokens[_token], 'Token already deny');

        _removeFeeToken(_token);
    }

    function _addFeeToken(address _token) internal {
        if (_token != address(0) && !feeAllowedTokens[_token]) {
            feeAllowedTokens[_token] = true;
            feeTokensAddresses.push(_token);
            feeTokensAddressesIndexes[_token] = feeTokensAddresses.length;
        }
    }

    function _removeFeeToken(address _token) internal {
        if (_token != address(0) && feeAllowedTokens[_token]) {
            feeAllowedTokens[_token] = false;

            // Search indexes
            uint256 feeTokenIndex = feeTokensAddressesIndexes[_token];
            uint256 toDeleteIndex = feeTokenIndex - 1;
            uint256 lastIndex = feeTokensAddresses.length - 1;

            // Swapping the last and deleted token address
            address lastFeeTokenAddress = feeTokensAddresses[lastIndex];
            feeTokensAddresses[toDeleteIndex] = lastFeeTokenAddress;
            feeTokensAddressesIndexes[lastFeeTokenAddress] = toDeleteIndex + 1;

            // Remove last token address
            feeTokensAddresses.pop();
            delete feeTokensAddressesIndexes[_token];
        }
    }
}
