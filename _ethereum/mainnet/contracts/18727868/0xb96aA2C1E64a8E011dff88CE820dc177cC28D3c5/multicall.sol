// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITargetNFT {
    function burn(uint256 tokenId) external;
}

contract BatchBurner {
    address public owner;
    ITargetNFT public targetNFTContract;

    constructor(address _targetNFTContract) {
        owner = msg.sender;
        targetNFTContract = ITargetNFT(_targetNFTContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function batchBurn(uint256[] calldata tokenIds) external onlyOwner {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            targetNFTContract.burn(tokenIds[i]);
        }
    }
}
