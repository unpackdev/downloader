// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract LostInThought is ERC721A, Ownable {
    string public metadataBaseURL = "ipfs://hidden/";

    uint256 public nftPerAddressLimit = 1;

    uint256 public price = 0.02 ether;

    uint256 public maxSupply = 217;

    bool public paused = true;

    mapping(address => uint256) public mintedBalance;

    constructor() ERC721A("LostInThought", "LIT") {}

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _baseURL) external onlyOwner {
        metadataBaseURL = _baseURL;
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

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURL;
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
}