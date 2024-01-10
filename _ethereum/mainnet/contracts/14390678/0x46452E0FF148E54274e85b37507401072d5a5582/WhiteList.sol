// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Ownable.sol";
import "./Strings.sol";


contract WhiteList is Ownable {
    using Strings for string;
    uint8 public constant MAX_MINT = 7;

    mapping(address => bool) public whiteList;

    function setWhitelist(address[] calldata addresses) external onlyOwner {
        require(addresses.length <= 2000,"Long WhiteList");
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = true;
            initQouta(addresses[i]);
        }
    }
    mapping(address => bool) public whiteListSecond;

    function setWhitelistSecond(address[] calldata addresses) external onlyOwner {
        require(addresses.length <= 2000,"Long WhiteList");
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteListSecond[addresses[i]] = true;
            initQouta(addresses[i]);
        }
    }

    uint8 public constant WHITELIST_FREE_MAX = 1;

    mapping(address => uint) public whiteListFreeQouta;

    function setWhitelistFree(address[] calldata addresses) external onlyOwner {
        require(addresses.length <= 2000,"Long WhiteList");
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteListFreeQouta[addresses[i]] = WHITELIST_FREE_MAX;
        }
    }



    

    mapping(address => bool)  public qoutaInited;
    mapping(address => uint) public publicQouta;

    function initQouta(address _address) internal {
        if(!qoutaInited[_address])
        {
            qoutaInited[_address] = true;
            publicQouta[_address] = MAX_MINT;
        }

    }
}