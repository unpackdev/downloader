// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721Payable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";


contract EzRamen is ERC1155Supply, Ownable, ERC721Payable {
        
    uint256 private mintedTokens;
    uint256 public tokenPrice = 0.15 ether; 
    uint constant TOKEN_ID = 24;
    uint constant MAX_TOKENS = 5000;
    uint public constant MAX_PURCHASE = 21; // set 1 to high to avoid some gas
    
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant IRISH = 0x3C1e329ed707900a5D1590a0c929584649eCed9A;  

    bool public saleIsActive;

    event PriceChange(address _by, uint256 price);

    constructor() ERC1155("ipfs://QmbYA8WsqLuKo5uZTodxLsGUfwZfyfJLadzhEZPyFeQh7z") { 
        _mint(FRANK,TOKEN_ID,1, "");
        mintedTokens = 1;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit PriceChange(msg.sender, tokenPrice);
    }
    
    /**
     * @dev airdrop a specific token to a list of addresses
     */
    function airdrop(address[] calldata addresses, uint amount) public onlyOwner{
        require(mintedTokens + amount <= MAX_TOKENS, "2476: would exceed max supply of tokens!");
        for (uint i=0; i < addresses.length; i++) {
            mintedTokens+=amount;
            _mint(addresses[i], TOKEN_ID, amount, "");
        }
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        require(saleIsActive,"Sale NOT active yet");
        require(tokenPrice*numberOfTokens <= msg.value, "Ether value sent is not correct"); 
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 20 tokens at a time");
        require(msg.sender == tx.origin, "No Contracts allowed.");
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
    }

    function name() public pure returns (string memory) {
        return "EZ Ramen";
    }

    function symbol() public pure returns (string memory) {
        return "EZR";
    }
    
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(IRISH, balance/20);     
        _withdraw(owner(), address(this).balance);
    }
}