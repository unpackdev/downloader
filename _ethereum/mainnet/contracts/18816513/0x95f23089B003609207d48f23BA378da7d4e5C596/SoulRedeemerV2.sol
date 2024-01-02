//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TransferrableOwnable.sol";
import "./Doug.sol";
import "./DougSoul.sol";
import "./console.sol";
import "./IERC721Receiver.sol";

contract SoulRedeemerV2 is TransferrableOwnable, IERC721Receiver {
    DougSoul _sbt;

    event DougRedeemed(uint256 indexed sbt);
        
    constructor(
        address sbtAddress) TransferrableOwnable(msg.sender)
    {
        _sbt = DougSoul(sbtAddress);
    }    

    function isRedeemed(uint256 token) public view returns(bool) {
        return _sbt.isRedeemed(token);
    }

    function redeem(uint256 tokenId) public isOwner {
        require(isRedeemed(tokenId) == false, "SBT already redeemed");

        _sbt.redeem(tokenId);
        emit DougRedeemed(tokenId);
    }

    function redeemMany(uint256[] memory tokenIds) public {
        for(uint i = 0; i < tokenIds.length; i++) {
            redeem(tokenIds[i]);
        }
    }

    receive() external payable {
        // Thank you
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}