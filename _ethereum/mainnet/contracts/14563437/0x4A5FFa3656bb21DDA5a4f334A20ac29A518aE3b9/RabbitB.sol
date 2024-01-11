//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract RabbitB is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 8400;
    uint public constant MAX_PER_MINT = 20;
    uint private price = 0.025 ether;
    bool public isMintActive = false;
    string public provenanceHash = "";

    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("RabbitB", "RABB") {
        setBaseURI(baseURI);
        _tokenIds.increment();
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function reserveRabB(uint256 _reserveAmount) public onlyOwner {
        uint totalMinted = totalSupply();

        require(totalMinted.add(_reserveAmount) < MAX_SUPPLY, "Not enough RABB left to reserve");

        for (uint i = 0; i < _reserveAmount; i++) {
            _mintSingleRabB();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function flipMintStatus() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function mintRabBs(uint _count) public payable {
        uint totalMinted = totalSupply();

        require(isMintActive, "Minting is not available yet" );
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Exceeds maximum tokens available for purchase");
        require(_count >0 && _count <= MAX_PER_MINT, "Exceeds maximum tokens you can purchase in a single transaction");
        require(msg.value >= price.mul(_count), "Did not send enough ether to purchase NFTs");

        for (uint i = 0; i < _count; i++) {
            _mintSingleRabB();
        }
    }

    function _mintSingleRabB() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if(tokenCount == 0){
            return new uint256[](0);
        } else {
            uint[] memory tokensId = new uint256[](tokenCount);

            for (uint i = 0; i < tokenCount; i++) {
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}