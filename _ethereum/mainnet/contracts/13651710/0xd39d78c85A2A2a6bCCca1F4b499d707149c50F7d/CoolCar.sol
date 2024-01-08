// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CoolCars is ERC721Enumerable, Ownable {
    
    uint256 public constant MAX_TOKENS = 3000;
    uint256 public constant TOKEN_PRICE = 0.05 ether;
    uint256 public constant PRESALE_PRICE = 0.03 ether;

    mapping(address => uint256) private _presaleList;

    bool public isSaleActive = false;
    bool public isPresaleActive = false;

    string public baseURI;
    string public PROVENANCE;

    constructor(string memory genericBaseURI) ERC721("Cool Cars", "CCAR") {
        isPresaleActive = true;
        baseURI = genericBaseURI;
    }

    //Internals
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _mintTokens(uint256 numTokens) private {
        for (uint256 i = 0; i < numTokens ; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    //Only owner
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setSaleStatus(bool saleActive, bool presaleActive) public onlyOwner {
        isSaleActive = saleActive;
        isPresaleActive = presaleActive;
    }

    function setPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleList[addresses[i]] = 3;
        }
    }

    function reserveTokens(uint256 numTokens) external onlyOwner {
        require(totalSupply() + numTokens <= MAX_TOKENS, 'Exceeds maximum CoolCars supply!');

        _mintTokens(numTokens);
    }

    function mintToWinners(address[] calldata winners) external onlyOwner {
        require(totalSupply() + winners.length <= MAX_TOKENS, 'Exceeds maximum CoolCars supply!');
        for (uint256 i = 0; i < winners.length; i++) {
            _safeMint(winners[i], totalSupply() + 1);
        }
    }

    function setProvenance(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    //Public
    function mintTokens(uint256 numTokens) external payable {
        require(isSaleActive, "Sale is not active!");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Exceeds maximum CoolCars supply!");
        require(numTokens <= 5, "Maximum 5 tokens per transaction!");
        require(numTokens * TOKEN_PRICE == msg.value, "Ether value incorrect!");
        
        _mintTokens(numTokens);
    }

    function mintTokensPresale(uint256 numTokens) external payable {
        require(isPresaleActive, "Presale is not active!");
        require(numTokens <= _presaleList[msg.sender], "Exceeds maximum tokens available!");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Exceeds maximum CoolCars supply!");
        require(numTokens <= 3, "Maximum 3 tokens per transaction!");
        require(numTokens * PRESALE_PRICE == msg.value, "Ether value incorrect!");
        
        _presaleList[msg.sender] -= numTokens;
        _mintTokens(numTokens);
    }

}
