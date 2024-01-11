//      /\  \         /\__\         /\  \         /\  \         /\  \                  /\  \         /\  \         /\  \
//     /::\  \       /::|  |       /::\  \       /::\  \       /::\  \                /::\  \       /::\  \        \:\  \
//    /:/\:\  \     /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\:\  \              /:/\:\  \     /:/\:\  \        \:\  \
//   /:/  \:\  \   /:/|:|__|__   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \            /::\~\:\  \   /::\~\:\  \       /::\  \
//  /:/__/ \:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/__/_\:\__\ /:/\:\ \:\__\          /:/\:\ \:\__\ /:/\:\ \:\__\     /:/\:\__\
//  \:\  \ /:/  / \/__/~~/:/  / \:\~\:\ \/__/ \:\  /\ \/__/ \/__\:\/:/  /          \/__\:\/:/  / \/_|::\/:/  /    /:/  \/__/
//   \:\  /:/  /        /:/  /   \:\ \:\__\    \:\ \:\__\        \::/  /                \::/  /     |:|::/  /    /:/  /
//    \:\/:/  /        /:/  /     \:\ \/__/     \:\/:/  /        /:/  /                 /:/  /      |:|\/__/    /:/  /
//     \::/  /        /:/  /       \:\__\        \::/  /        /:/  /                 /:/  /       |:|  |     /:/  /
//      \/__/         \/__/         \/__/         \/__/         \/__/                  \/__/         \|__|     \/__/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OMEGA_ART is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public totalSupply = 11111;
    string private baseURI;
    Counters.Counter private tokenId;

    constructor(string memory baseURI_) ERC721("OMEGA ART", "OART") {
        baseURI = baseURI_;
    }

    // mint is free, but payments are accepted
    function mint() external payable {
        require(balanceOf(msg.sender) < 1, "Only one free NFT per wallet");
        require(tokenId.current() + 1 <= totalSupply, "Mint exceeds supply");
        tokenId.increment();
        _safeMint(msg.sender, tokenId.current());
    }

    function getActualSupply() public view returns (uint256) {
        return tokenId.current();
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Set some OMEGA aside for team, charity, growth and giveaways
    function reserveOMEGA() public onlyOwner {
        uint256 i;
        for (i = 0; i < 25; i++) {
            if (tokenId.current() + 1 <= totalSupply) {
                tokenId.increment();
                _safeMint(owner(), tokenId.current());
            }
        }
    }

    function donate() external payable {
        // Time to build the future together. Thanks you for supporting OMEGA ART Foundation in its actions and ambitions
    }

    // This allows OMEGA ART Foundation to receive kind donations
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
