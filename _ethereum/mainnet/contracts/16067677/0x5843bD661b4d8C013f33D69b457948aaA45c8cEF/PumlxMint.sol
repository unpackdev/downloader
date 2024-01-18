// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

///@dev
// Dependencies:
// npm i --save-dev erc721a
// npm i @openzeppelin/contracts
// import "./ERC721A.sol";
// import "./ERC20.sol";
// created by: Xaikyō <> Mpdigitald
// copyright: PUML Better Health 2022

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC20.sol";


contract PumlxMint is ERC721A, Ownable, ReentrancyGuard, Pausable{

    // token-sale mint variables
    uint256 public pumlxMaxMint = 20;
    uint256 public pumlPrice = 2000 * (10**18);
    uint256 public maxSupply = 5000;
    uint256 public supply;

    IERC20 public tokenAddress;

    // booleans for reveal/all mint toggles
    bool public pumlxEnabled = false;

    // keep track of # of minted tokens per user
    mapping(address => uint256) totalTokenMint;

    constructor (
        address _tokenAddress
        ) ERC721A("PumlxMint", "PUML") {
            tokenAddress = IERC20(_tokenAddress);
    }

    // PUMLx token mint 
    function handlePumlx(uint256 _quantity) external payable whenNotPaused nonReentrant {    
        require(pumlxEnabled, "token mint is currently paused");
        require(supply <= maxSupply, "Max supply reached, Wearx watches sold out");
        require((totalTokenMint[msg.sender] + _quantity) <= pumlxMaxMint, "Error: Max per wallet reached");
        
        tokenAddress.transferFrom(msg.sender, address(this), (_quantity * pumlPrice));
        totalTokenMint[msg.sender] += _quantity;
        supply += _quantity;
        // mint will be handled off chain through ether js
    }

    // turn on/off mint phases
    function togglePumlxMint() external onlyOwner {
        pumlxEnabled = !pumlxEnabled;
    }

    // set prices and toggle functions

    function setPumlPrice(uint256 _mintPrice) external onlyOwner {
        pumlPrice = _mintPrice;
    }

    function setPumlMax(uint256 _pumlxMaxMint) external onlyOwner {
        pumlxMaxMint = _pumlxMaxMint;
    }

    function setStartingSupply(uint256 _totalSupply) external onlyOwner {
        supply = _totalSupply;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
  
    function pause() public onlyOwner { 
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTokenAddress(IERC20 _tokenAddress) external onlyOwner nonReentrant {
        tokenAddress = IERC20(_tokenAddress);
    }

    // withdraw to owner(), i.e only if msg.sender is owner
    function withdraw(address _to) external onlyOwner nonReentrant {
        payable(_to).transfer(address(this).balance);
    }

    // withdraw ERC20 using tokenAddress 
    function withdrawToken(address _to) external onlyOwner nonReentrant {
        tokenAddress.transfer(_to, tokenAddress.balanceOf(address(this)));
    }

}
