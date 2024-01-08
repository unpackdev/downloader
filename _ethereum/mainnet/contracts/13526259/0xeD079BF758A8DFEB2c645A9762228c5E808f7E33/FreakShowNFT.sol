//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";

contract FreakShowNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private tokenIdCounter;

    constructor() public ERC721("FreakshowNFT", "FREAKSHOW") {}

    bool public isSaleActive = false;
    uint256 public constant maxSupply = 10310;
    uint256 public max_per_purchase = 100;
    string public baseURI;

    address firstWallet = 0x7431ac593d117BC3A28fa4025a39BCcCCAcf89AA;
    address secondWallet = 0x7b845ED4979b27C49045E1A7eF6e96DF43ef8EC2;
    address thirdWallet = 0x042a7172069e878b527b5c7BCce4B01353217399;
    address fourthWallet = 0x7c4D3401e167c0699feb6319b5118c60088e60E9;
    
    // uint256 private price = 10000000000000000; // 0.01 Ether
    uint256 private price = 90000000000000000; // 0.09 ETHER

    // Variables defined to keep track of stages and thresholds
    mapping(uint => uint) public stages;
    uint256 public stage = 1;


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMaxPerPurchase(uint256 _max) public onlyOwner {
        max_per_purchase = _max;
    }

    // steStage is used to set the stage of the contract
    function setStage(uint256 _stage, uint256 _threshold) public onlyOwner {
        stages[_stage] = _threshold;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function internalMint(address to) internal {
        require(totalSupply() < maxSupply, 'supply depleted');
        _safeMint(to, tokenIdCounter.current());
        tokenIdCounter.increment();

        // Checking if totalSupply() has reached the next stage,
        // if so, we set the stage to the next one and pause the contract
        if (totalSupply() == stages[stage]) {
            stopContract();
        }
    }

    function safeMint(address to) public onlyOwner {
        internalMint(to);
    }

    // Function that allows only owner to mint for free
    // even on sale inactive
    function mintNFTReserve(uint256 amount)
        public onlyOwner
    {
        require(amount <= max_per_purchase, 'excedeed number of items per transaction');
        for (uint256 i = 0; i < amount; i++) internalMint(msg.sender);
    }

    function mintNFT(uint256 amount)
        public payable
    {
        require(isSaleActive, "Sale is not active" );
        require(msg.value >= price * amount, "Ether value sent is not correct");

        require(amount <= max_per_purchase, 'excedeed number of items per transaction');
        for (uint256 i = 0; i < amount; i++) internalMint(msg.sender);
    }

    // Helper functions

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(firstWallet).transfer((balance * 250) / 1000);
        payable(secondWallet).transfer((balance * 100) / 1000);
        payable(thirdWallet).transfer((balance * 625) / 1000);
        payable(fourthWallet).transfer((balance * 25) / 1000);
    }

    function stopContract() public onlyOwner {
        require(isSaleActive, "Sale is not active" );
        stage = stage + 1;
        isSaleActive = false;
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
