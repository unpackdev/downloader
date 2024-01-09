// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";

contract WhiteList is Ownable{
    mapping(address => bool) whitelist;
    mapping(address => uint256) public whitelistTotals;
    event AddedToWhitelist(address indexed account);

    IERC721[] public nfts;

    /**
     * @dev Add ERC721s to whitelist
    */
    function addWhitelistNft(address[] memory _nfts) public onlyOwner {
        for (uint256 i = 0; i < _nfts.length; i++) {
            nfts.push(IERC721(_nfts[i]));
        }
    }

    /**
     * @dev Add Wallets to whitelist
    */
    function addWhitelisters(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
            whitelistTotals[_addresses[i]] = 0;
            emit AddedToWhitelist(_addresses[i]);
        }
    }

    /**
     * @dev If on whitelist or holder of NFT on whitelist
    */
    function isOnAWhitelist(address _address) public view returns (bool) {
        if(whitelist[_address]) {
            return true;
        }

        for (uint256 i = 0; i < nfts.length; i++) {
            if(nfts[i].balanceOf(_address) > 0) {
                return true;
            }
        }

        return false;
    }

}