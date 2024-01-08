//SPDX-License-Identifier: GPL-3.0
//Created by BaiJiFeiLong@gmail.com at 2021/10/14 15:29
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SnakeVerse is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => uint256) private _segmentMints;
    string private _theBaseURI = "ipfs://QmePiT2aVx7K52nd9jeWAW6uYE7YpWbg3Er98ghQ3nbaH6/";

    constructor() ERC721("SnakeVerse", "SNAKE") {
        _mintOne();
    }

    function maxSupply() public pure returns (uint256) {
        return 10000;
    }

    function _baseURI() internal view override returns (string memory) {
        return _theBaseURI;
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply())));
    }

    function _mintOne() private {
        uint256 newTokenId = totalSupply();
        _mint(_msgSender(), newTokenId);
    }

    function luckyMint(uint256 count) public payable {
        require(totalSupply() + count <= maxSupply(), "No more tokens to mint");

        uint256 mintPrice = (totalSupply() / 2000 + 1) * 0.01 ether;
        require(msg.value >= mintPrice * count, "Provided ethers not enough");

        uint256 luckyTokenId = tokenByIndex(_random() % totalSupply());
        address luckyAddress = ownerOf(luckyTokenId);
        payable(luckyAddress).transfer(msg.value / 2);

        for (uint256 i = 0; i < count; ++i) {
            _mintOne();
        }
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        require(totalSupply() < maxSupply(), "All tokens minted, metadata locked");
        _theBaseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}