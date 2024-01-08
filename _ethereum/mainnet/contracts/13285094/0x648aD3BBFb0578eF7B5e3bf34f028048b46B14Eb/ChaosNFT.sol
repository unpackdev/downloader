// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

contract ChaosNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;
    uint256 public saleStartTimestamp = 1632441600;

    address private constant _owner =
        0x631fc1b7fc847976f2568c1ff712f4b7c33A9b3B;

    event Bought(address walletAddress, uint256 tokenId);

    constructor() ERC721("Chaos Blocks", "CHAOS") {
        _baseTokenURI = "https://www.chaosblocks.art/api/token/";
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.chaosblocks.art/api/contract_metadata";
    }

    function buy(uint256 amount) external payable {
        require(
            block.timestamp >= saleStartTimestamp,
            "Sale has not started yet"
        );
        require(amount <= amountLeft(), "Not enough left");
        require(
            msg.value >= amount * 70000000000000000,
            "Invalid ether amount sent "
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = mint(msg.sender);
            emit Bought(msg.sender, tokenId);
        }
        payable(_owner).transfer(msg.value);
    }

    function amountLeft() public view returns (uint256) {
        return
            10000 -
            _tokenIdTracker.current() -
            (block.timestamp - saleStartTimestamp) /
            30;
    }

    function giveaway(address receiver, uint256 amount) external {
        require(msg.sender == _owner, "must be owner");
        require(
            amount <= 250 - _givedAmountTracker.current(),
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
