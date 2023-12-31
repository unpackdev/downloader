// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./INieuxCollective.sol";
import "./Ownable.sol";

contract NieuxCollectiveProxy is Ownable {
    INieuxCollective public immutable NieuxCollective;

    constructor(address NC) {
        NieuxCollective = INieuxCollective(NC);
    }

    /**
     * @dev Airdrops a token to a given address
     * @param to address to receive the token
     */
    function airdropOne(address to) external onlyOwner {
        NieuxCollective.airdropOne(to);
    }

    /**
     * @dev Airdrops multiple tokens to multiple addresses
     * @param to array of addresses to receive the tokens
     */
    function airdropMany(address[] calldata to) external onlyOwner {
        for (uint i = 0; i < to.length; ) {
            NieuxCollective.airdropOne(to[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Sets the default royalty for the contract
     * @param receiver address to receive the royalty
     * @param feeNumerator the royalty fee numerator
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public payable onlyOwner {
        NieuxCollective.setDefaultRoyalty{value: msg.value}(
            receiver,
            feeNumerator
        );
    }

    /**
     * @dev Withdraws the contract balance to the receiver address
     */
    function withdraw() public payable {
        NieuxCollective.withdraw();
        (bool sent, bytes memory data) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function renounceNCOwnership() external onlyOwner {
        NieuxCollective.renounceOwnership();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        NieuxCollective.setBaseURI(uri);
    }

    function transferNCOwnership(address newOwner) external onlyOwner {
        NieuxCollective.transferOwnership(newOwner);
    }
}
