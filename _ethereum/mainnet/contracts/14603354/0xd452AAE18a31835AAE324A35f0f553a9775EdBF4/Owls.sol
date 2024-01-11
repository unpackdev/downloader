// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Owls is ERC721Enumerable, Ownable {
    string baseURI;
    uint256 tokenId;
    uint256 public currentBatch;
    mapping(address => uint256) mintCounter;
    
    // Initializes the contract
    // @param { String } _name | Name of contract
    // @param { String } _symbol | Symbol of contract
    // @param { String } _baseURIData | The initial base uri for metatata, trailing slash (/) is obligatory
    // @param { uint256 } _amountToAdopt | The amount of owns to mint initially
    // @param { uint256 } _initialBatch | The initial amount of available tokens for minting
    constructor(string memory _name, string memory _symbol, string memory _baseURIData, uint256 _amountToAdopt, uint256 _initialBatch) ERC721(_name, _symbol) {
        baseURI = _baseURIData;
        currentBatch = _initialBatch;

        adoptOwl(_amountToAdopt);
    }
    
    // @notice Mints a given amount of tokens
    // @param { uint256 } _amount | The amount of tokens to mint
    function mint(uint256 _amount) external payable {
        require(tokenId < 10020, "Error: No more supply.");
        require(_amount <= 20, "Error: Can't mint more than 20 at a time.");
        require(mintCounter[msg.sender] + _amount <= 20, "Error: You've reached your mint limit.");
        require(msg.value >= _amount * 60000000000000000, "Error: Not enough ether");
        require(tokenId + _amount <= currentBatch, "Error: Batch is not yet released");

        for (uint256 index = 0; index < _amount; index++) {
            mintCounter[msg.sender]++;

            _mint(msg.sender, ++tokenId);
        }
    }

    // Function to mint initial tokens.
    // @param { uint256 } _amount | The amount of tokens to mint initially
    function adoptOwl(uint256 _amount) private {
        for (uint256 index = 0; index < _amount; index++) {
            _mint(address(this), ++tokenId);
        }
    }

    // Transfers initially minted owls.
    // Restricted to contract owner
    // @param { address } _to | The address to transfer the token to
    // @param { uint256 } _tokenId | The token id to transfer
    function transferAdoptedOwl(address _to, uint256 _tokenId) external onlyOwner {
        require(_tokenId <= tokenId, "Error: Token doesn't exist!");

        Owls(address(this)).approve(_to, _tokenId);

        Owls(address(this)).safeTransferFrom(address(this), _to, _tokenId);
    }
    
    // Withdraws the current amount of ETH 
    // stored in the contract
    // Restricted to contract owner
    function withdraw() external onlyOwner payable {
        payable(owner()).transfer(address(this).balance);
    }

    // Release a batch of tokens
    // Current batch doesn't get added on top 
    // of the current ones, it changes
    // the maximum amount of tokens available
    // @param { uint256 } _currentBatch | The new batch
    function releaseBatch(uint256 _currentBatch) external onlyOwner {
        require(_currentBatch > currentBatch, "Error: Can't set batch to be lower than the current one!");

        currentBatch = _currentBatch;
    }

    // Set the new baseURIData
    // Used for revealing the NFTs
    // @param { String } _baseURIData | The new URL containing the metadata. Trailing slash (/) is required
    function setBaseURI(string memory _baseURIData) onlyOwner external {
        baseURI = _baseURIData;
    }

    // Override @openzeppelin _baseURI function
    // @returns { String } The base URL to the metadata
    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }
}
