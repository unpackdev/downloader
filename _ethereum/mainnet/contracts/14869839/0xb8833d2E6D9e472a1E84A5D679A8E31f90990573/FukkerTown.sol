// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FukkerTown is ERC721A, Ownable {
    using Strings for uint256;

    string public metadataUrl;

    bool public active = false;
    uint256 public supply = 8888;
    uint256 public mintLimit = 40;
    uint256 public price = 0.005 ether;

    constructor(string memory _metadataUrl) ERC721A("FukkerTown.wtf", "FUKKERTOWN.WTF") Ownable() {
        metadataUrl = _metadataUrl;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint256 amount) external payable {
        require(active, "Not active");
        require(totalSupply() < supply, "Sold out");
        require(msg.value >= amount * price, "Incorrect amount");
        require(amount <= mintLimit, "Limit reached");

        _mint(msg.sender, amount);
    }

    function ownerMint(uint256 amount) external onlyOwner {
        require(totalSupply() < supply, "Sold out");
        _mint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(metadataUrl, tokenId.toString(), ".json"));     
    }

    function setMetadataUrl(string memory _url) external onlyOwner {
        metadataUrl = _url;
    }

    function configureMint(uint256 _supply, uint256 _limit, uint256 _price, bool _active) external onlyOwner {
        supply = _supply;
        mintLimit = _limit;
        price = _price;
        active = _active;
    }

    function setMintActive(bool _active) external onlyOwner {
        active = _active;
    }

    function withdraw(address to) external onlyOwner {
       payable(to).transfer(address(this).balance);
    }

    receive() external payable {}
}