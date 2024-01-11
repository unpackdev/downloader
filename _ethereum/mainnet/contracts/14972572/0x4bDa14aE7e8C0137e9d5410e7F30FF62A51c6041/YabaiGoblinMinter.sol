// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IYabaiGoblinMinter.sol";
import "./YabaiGoblin.sol";

contract YabaiGoblinMinter is Ownable, IYabaiGoblinMinter {

    address public immutable nft;
    uint256 public limit = 3000;
    uint256 public max = 5;

    mapping(address => bool) private blacklist;

    constructor(address _nft) {
        nft = _nft;
    }

    function addBlacklist(address[] memory blackuser) external onlyOwner {
        uint256 length = blackuser.length;
        for (uint256 i = 0; i < length; i += 1) {
            blacklist[blackuser[i]] = true;
        }
    }

    function removeBlacklist(address[] memory blackuser) external onlyOwner {
        uint256 length = blackuser.length;
        for (uint256 i = 0; i < length; i += 1) {
            blacklist[blackuser[i]] = false;
        }
    }

    function setLimit(uint256 _limit) external onlyOwner {
        limit = _limit;
        emit SetLimit(_limit);
    }

    function setMax(uint256 _max) external onlyOwner {
        max = _max;
        emit SetMax(_max);
    }

    function mint(uint256 count) public {
        require(count < max);
        require(YabaiGoblin(nft).totalSupply() <= limit - count, "Limit exceeded");
        require(blacklist[msg.sender] != true);
        YabaiGoblin(nft).mint(msg.sender, count);
    }
}
