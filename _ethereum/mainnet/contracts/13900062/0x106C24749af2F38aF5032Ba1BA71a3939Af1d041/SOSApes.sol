// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/*
   _____ ____  _____    ___                   
  / ___// __ \/ ___/   /   |  ____  ___  _____
  \__ \/ / / /\__ \   / /| | / __ \/ _ \/ ___/
 ___/ / /_/ /___/ /  / ___ |/ /_/ /  __(__  ) 
/____/\____//____/  /_/  |_/ .___/\___/____/  
                          /_/                 
*/

contract SOSApes is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 10000000;

    bool public saleIsActive = false;

    string public baseURI;

    IERC20 public sosTokenContractInstance;

    uint256[3] public winnerTokens;

    uint256 currentWinner = 0;

    constructor(string memory name, string memory symbol, uint256 maxSosGameSupply, address sosTokenAddress) ERC721(name, symbol) {
        maxTokenSupply = maxSosGameSupply;

        sosTokenContractInstance = IERC20(sosTokenAddress);
    }

    function setTokenAddress(address sosTokenAddress) public onlyOwner {
        sosTokenContractInstance = IERC20(sosTokenAddress);
    }

    function setMaxTokenSupply(uint256 maxSosGameSupply) public onlyOwner {
        maxTokenSupply = maxSosGameSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw(uint256 tokenAmount) public onlyOwner {
        sosTokenContractInstance.transfer(msg.sender, tokenAmount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "Max 15 mints per txn");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Purchase would exceed supply");

        sosTokenContractInstance.transferFrom(msg.sender, address(this), mintPrice * numberOfTokens * 10 ** 18);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function selectWinner(uint256 min, uint256 max) public onlyOwner {
        require(currentWinner < 3, "Winners have already been picked");

        uint256 randomWinner = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        randomWinner = randomWinner % (max - min + 1) + min;

        winnerTokens[currentWinner] = randomWinner;
        currentWinner++;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}
