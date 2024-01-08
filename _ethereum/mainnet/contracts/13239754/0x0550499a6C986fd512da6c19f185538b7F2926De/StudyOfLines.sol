// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

contract StudyOfLines is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;

    address private constant _owner =
        0x48A7f7bd80F8a8026e66e164086dc03e148bF899;

    event Bought(address walletAddress, uint256 tokenId);

    constructor() ERC721("Study of Lines", "SOL") {
        _baseTokenURI = "https://www.studyoflines.art/api/token/";
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.studyoflines.art/api/contract_metadata";
    }

    function buy(uint256 amount) external payable {
        require(amount <= 1000 - _tokenIdTracker.current(), "Not enough left");
        require(
            msg.value >= amount * 50000000000000000,
            "Invalid ether amount sent "
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = mint(msg.sender);
            emit Bought(msg.sender, tokenId);
        }
        payable(_owner).transfer(msg.value);
    }

    function giveaway(address receiver, uint256 amount) external {
        require(msg.sender == _owner, "must be owner");
        require(
            amount <= 100 - _givedAmountTracker.current(),
            "Not enough left to give"
        );

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = give(receiver);
            emit Bought(receiver, tokenId);
        }
    }

    function mint(address to) internal returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
        return _tokenIdTracker.current();
    }

    function give(address to) internal returns (uint256) {
        // increment tracker then mint
        _givedAmountTracker.increment();
        return mint(to);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
