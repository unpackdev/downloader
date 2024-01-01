// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

abstract contract LimitPerWallet {
    mapping(address => uint256) public mintsPerWallet;

    /**
     * @dev Checks if the given wallet address can mint more tokens.
     * If the desired amount to be minted exceeds the amount of tokens left allowed to be minted by the given address
     * it will return the maximum amount of tokens that address can mint.
     *
     * If the given address can not mint more tokens it will revert the transaction.
     */
    function getAvailableForWallet(
        uint256 _amount,
        uint256 _maxPerWallet
    ) internal returns (uint256) {
        // If maxPerWallet is 0 it means that there is no limit per wallet.
        if (_maxPerWallet == 0) {
            return _amount;
        }

        if (mintsPerWallet[msg.sender] + _amount > _maxPerWallet) {
            _amount = _maxPerWallet - mintsPerWallet[msg.sender];
        }

        require(
            _amount > 0,
            "LimitPerWallet: The caller address can not mint more tokens"
        );

        mintsPerWallet[msg.sender] += _amount;

        return _amount;
    }
}
