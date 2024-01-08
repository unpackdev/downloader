// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


/**
 * @title Dragonz contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankPoncelet
 * 
 */

contract Dragonz is Ownable, ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenSupply;
    
    uint256 public tokenPrice = 0.03 ether; 
    uint256 public tokens;
    uint public constant MAX_PURCHASE = 25;
    uint public constant MAX_RESERVE = 25;
    
    bool public saleIsActive;
    // Base URI for Meta data
    string private _baseTokenURI;
    
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);
    
    constructor() ERC721("Dinky Dragonz", "DDZ") {
        tokens = 1000;
        _baseTokenURI = "ipfs://Qmda1qTu9Hr87tBuBYndkqWpUj8CqTdqh2cPrf1z3p2RqL/";
        _tokenSupply.increment();
        _safeMint( FRANK, 0);
    }
    
    /**
     * Used to mint Tokens to the teamMembers
     */
    function reserveTokens(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= tokens, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens <= MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
            _tokenSupply.increment();
        }
    }
    
    function reserveTokens() external onlyOwner {    
        reserveTokens(msg.sender,MAX_RESERVE);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    /**     
    * Set price 
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    /**    
    * increase the supply
    */
    function addTokens(uint256 tokensToAdd) public onlyOwner {
        tokens += tokensToAdd;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= tokens, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");  
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
            _tokenSupply.increment();
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FRANK, ((balance * 20) / 100));
        _withdraw(owner(), address(this).balance);
        emit PaymentReleased(owner(), balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }
    
    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}