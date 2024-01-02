// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./console2.sol";

interface I721Owner {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// #RAWR
contract TinyDinoCoin is ERC20 {
    error AlreadyClaimed();
    error NotOwner();

    address tinyDinos = 0xd9b78A2F1dAFc8Bb9c60961790d2beefEBEE56f4;

    mapping(uint256 => bool) public claimed;

    constructor() ERC20("Tiny Dino Coin", "TDC", 18) {
        uint256 amount = 8_000_000 ether;
        _mint(msg.sender, amount);
        bytes memory data = abi.encodeWithSignature("RAWR(string)", "Tiny Dino Coin - TD Holders can claim. RAWR");
        (bool success,) = 0xd9b78A2F1dAFc8Bb9c60961790d2beefEBEE56f4.call(data);
    }

    function claimOne(uint256 tinyId) public {
        if (claimed[tinyId] == true) {
            revert AlreadyClaimed();
        }
        if (I721Owner(0xd9b78A2F1dAFc8Bb9c60961790d2beefEBEE56f4).ownerOf(tinyId) != msg.sender) {
            revert NotOwner();
        }
        claimed[tinyId] = true;
        _mint(msg.sender, 200 ether);
    }

    function claimMany(uint256[] memory tinyIds) public {
        for (uint256 i; i < tinyIds.length;) {
            claimOne(tinyIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function image() public pure returns (string memory) {
        return
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAMAAAAp4XiDAAAASFBMVEX////vtADvtADvtADvtADvtADvtADvtADvtADwvgDy3R6xbwDx1gqwcgvx1gTxxQDwuwDwwQDwywDy2RTvuACwdBmwcxizdyl4TFEzAAAACHRSTlMALZMW9lH4tyrMTFQAAAEASURBVHja3dbbCsJADITh1nrIpq2Htur7v6lgwKH+GNYrwbnwxnxMltbF5t/T2jO1450pVSzmzid3H4pQDpbL7JEXy0UZNC+0+SQEiHLBHAsNBYty0fd9fMJAkMgEgSBRUGMWAoSrqUTz62A1laSEq3W2eEpYY3ZxBerukTWZa0ixrYh5SrhZa2fnPImLmJ2+J15Hiu3eCJWvM9m+lqjlwGefEzO+YT3zRmSqyFBN+F7qMGQ8Cg5Dgr1QA8K9WMMfMktUQ8IS1pCwROaor8dxdPfb9Zrel5vkeoXA5ZcKmlzQCOWChkAiRQIQMKE0T0AUbIpxgTRb/FGoym5/aH6bB4Y8OTODfoeUAAAAAElFTkSuQmCC";
    }
}
