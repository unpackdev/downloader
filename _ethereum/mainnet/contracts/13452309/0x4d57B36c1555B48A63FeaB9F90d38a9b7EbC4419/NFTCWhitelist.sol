// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

/**
 * @title NFTC Whitelist Implementation
 * @author @NiftyMike, NFT Culture
 * @dev Plain vanilla implementation to support minting from a whitelist.
 * Works fine with whitelists < 100 addresses or so, but will get expensive beyond that.
 *
 * Please report bugs or security issues to @author
 * Please credit @author if you re-use this code
 */
contract NFTCWhitelist is Ownable {
    mapping(address => uint256) private _whitelist;

    function whitelistWallets(address[] memory wallets) external onlyOwner {
        require(wallets.length > 0, 'Empty list');

        uint256 idx;
        for (idx = 0; idx < wallets.length; idx++) {
            _whitelist[wallets[idx]]++;
        }
    }

    function getWhitelistAmount(address wallet)
        external
        view
        returns (uint256)
    {
        return _getWhitelistAmount(wallet);
    }

    function _getWhitelistAmount(address wallet)
        internal
        view
        returns (uint256)
    {
        return _whitelist[wallet];
    }

    function _decrementWhitelistAmount(address wallet, uint256 count) internal {
        _whitelist[wallet] -= count;
    }
}
