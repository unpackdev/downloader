// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


/**
 * @title Shrumies contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankPoncelet
 * 
 */

contract RealPunk is Ownable, ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenSupply;
    
    uint256 public tokenPrice = 0.1 ether; 
    uint256 public preTokenPrice = 0.08 ether; 
    uint256 public constant MAX_TOKENS=5555;
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    // Base URI for Meta data
    string private _baseTokenURI;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    mapping(address => bool) private whitelist;
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);
    
    constructor() ERC721("RealPunk", "RPK") {
        _baseTokenURI = "https://metadata.realpunksnft.io/"; 
        _tokenSupply.increment();
        _safeMint( FRANK, 0);
    }


    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
            _tokenSupply.increment();
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     */   
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
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
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    /**
    * add an address to the WL
    */
    function addWL(address _address) public onlyOwner {
        whitelist[_address] = true;
    }
    /**
    * add an array of address to the WL
    */
    function addAdresses(address[] memory _address) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addWL(_address[i]);
         }
    }
    /**
    * remove an address off the WL
    */
    function removeWL(address _address) external onlyOwner {
        whitelist[_address] = false;
    }
    /**
    * returns true if the wallet is Whitelisted.
    */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }


    function mint(uint256 numberOfTokens) external payable{
        if(preSaleIsActive){
            require(isWhitelisted(msg.sender),"sender is NOT Whitelisted ");
            require(preTokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct"); 
        }else{
            require(saleIsActive,"Sale NOT active yet");
            require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct"); 
        }
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
 
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
            _tokenSupply.increment();
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
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
