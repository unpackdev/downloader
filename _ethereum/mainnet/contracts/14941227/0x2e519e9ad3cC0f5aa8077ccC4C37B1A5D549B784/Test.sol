// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract OutOfSpace is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix = "ipfs://QmbuusqBjDtJ9CYA7gnbA3ipwPXMXY291hnJxb3VzfTWmm/";
    string public uriSuffix = ".json";

    uint256 public nftPerAddressLimit = 2;

    uint256 public price = 0.02 ether;

    uint256 public maxSupply = 222;

    bool public paused = true;

    mapping(address => uint256) public mintedBalance;

    constructor() ERC721A("OutOfSpace", "OOS") {}

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _amount) external onlyOwner {
        maxSupply = _amount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function getMaxPerWallet() internal view returns (uint256) {
        return nftPerAddressLimit;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

     function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function mint(uint256 numOfTokens) external payable {
        require(!paused, "Minting is paused");
        require(totalSupply() + numOfTokens <= maxSupply, "Max supply reached");
        require(numOfTokens > 0, "You must mint at least one token");
        require(price * numOfTokens <= msg.value, "Not enough funds");
        require(
            mintedBalance[msg.sender] + numOfTokens <= nftPerAddressLimit,
            "Nft per adress limit exceeded"
        );

        for (uint256 i = 0; i < numOfTokens; i++) {
            mintedBalance[msg.sender]++;
        }

        _safeMint(msg.sender, numOfTokens);
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Error when trying to withdraw");
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}