// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IPepper.sol";

contract EthClone {
    event Clone(uint256[] nftIds);

    IPepper public pepperContract;

    constructor(IPepper pepperAddress) {
        pepperContract = pepperAddress;
    }

    function clone(uint256[] calldata nftIds) external {
        for (uint16 i = 0; i < nftIds.length; i++) {
            require(
                pepperContract.ownerOf(nftIds[i]) == msg.sender,
                "The sender doesn't own the tokens"
            );
        }

        emit Clone(nftIds);
    }

    function tokensOf(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 numPeppers = pepperContract.balanceOf(_address);
        uint256[] memory tokens = new uint256[](numPeppers);
        for (uint256 i = 0; i < numPeppers; i++) {
            uint256 token = pepperContract.tokenOfOwnerByIndex(_address, i);
            tokens[i] = token;
        }

        return tokens;
    }
}
