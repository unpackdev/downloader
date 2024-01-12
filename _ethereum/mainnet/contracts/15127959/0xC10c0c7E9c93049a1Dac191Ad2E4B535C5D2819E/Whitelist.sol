// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Maintanable.sol";
import "./IWhitelist.sol";

contract Whitelist is Maintanable, IWhitelist {
    // Mapping address to _whitelist index starting from 1, 0 means that address is not whitelisted
    mapping(address => uint256) internal whitelistIdx;
    address[] public whitelist;
    bool public whitelistActive;
    bool public whitelistInitialized;

    function initializeWhitelist() public onlyOwner {
        require(!whitelistInitialized, 'Whitelist: already initialized');
        whitelistInitialized = true;
        setWhitelistActive(true);
    }

    function addToWhitelist(address[] memory wallets) external override onlyMaintainer {
        for (uint i=0; i < wallets.length; i++) addAddress(wallets[i]);
        emit WhitelistChanged();
    }

    function deleteFromWhitelist(address[] memory wallets) external override onlyMaintainer {
        for(uint i=0; i < wallets.length; i++) removeAddress(wallets[i]);
        emit WhitelistChanged();
    }

    function setWhitelistActive(bool active) public override onlyOwner {
        whitelistActive = active;
        emit WhitelistSet(active);
    }

    function isWhitelistActive() public view override returns (bool) {
        return whitelistInitialized && whitelistActive;
    }

    function isWhitelisted(address wallet) public view override returns (bool) {
        return whitelistIdx[wallet] > 0;
    }

    function queryWhitelist(uint256 _cursor, uint256 _limit) external view override returns (address[] memory) {
        uint len = whitelist.length;
        uint min = _cursor >= len ? len : _cursor;
        uint max = min+_limit >= len ? len : min+_limit;

        address[] memory addrList = new address[](max-min);

        uint j = 0;
        for (uint i=min; i<max; i++) {
            j = i-min;
            addrList[j] = whitelist[i];
        }
        return addrList;
    }

    function removeAddress(address wallet) internal {
        if (isWhitelisted(wallet)) {
            uint256 currentIdx = whitelistIdx[wallet] - 1;
            uint256 lastIndex = whitelist.length - 1;
            address walletToMove = whitelist[lastIndex];
            
            if (wallet != walletToMove) {
                whitelistIdx[walletToMove] = currentIdx+1;
                whitelist[currentIdx] = walletToMove;
            }

            delete whitelistIdx[wallet];
            whitelist.pop();
        }
    }

    function addAddress(address wallet) internal {
        if (!isWhitelisted(wallet)) {
            whitelistIdx[wallet] = whitelist.length + 1;
            whitelist.push(wallet);
        }
    }
}