pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract AccessToken is ERC1155Supply, Ownable  {
    bool public saleIsActive = true;
    uint constant TOKEN_ID = 0;
    uint constant MAX_TOKENS_PER_PURCHASE = 2;
    uint public MAX_PUBLIC_TOKENS = 500;
    uint public MINTED_PUBLIC_TOKENS = 0;
    uint constant MAX_WHITELIST_TOKENS = 1500;
    uint public MINTED_WHITELIST_TOKENS = 0;
    uint public TOKEN_PRICE = 0.1 ether;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistPurchases;
    
    constructor(string memory uri) ERC1155(uri) {
    }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!whitelist[entry], "DUPLICATE_ENTRY");

            whitelist[entry] = true;
        }   
    }

    function reserve(uint numberOfTokens) public onlyOwner {
        MINTED_PUBLIC_TOKENS = MINTED_PUBLIC_TOKENS + numberOfTokens;
       _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function setPrice(uint newPrice) public onlyOwner {
        TOKEN_PRICE = newPrice;
    }
    
    function increaseSupply(uint increaseAmount) public onlyOwner {
        MAX_PUBLIC_TOKENS = MAX_PUBLIC_TOKENS + increaseAmount;
    }
    
    function claim() public payable {
        require(saleIsActive, "Sale must be active to claim Tokens");
        require(whitelist[msg.sender], "NOT_QUALIFIED");
        require(whitelistPurchases[msg.sender] + 1 <= 1, "EXCEED_ALLOC");
        require(MINTED_WHITELIST_TOKENS + 1 <= MAX_WHITELIST_TOKENS, "Purchase would exceed max supply of tokens");
        MINTED_WHITELIST_TOKENS++;
        whitelistPurchases[msg.sender]++;
        _mint(msg.sender, TOKEN_ID, 1, "");
    }
    
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase");
        require(MINTED_PUBLIC_TOKENS + numberOfTokens <= MAX_PUBLIC_TOKENS, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        MINTED_PUBLIC_TOKENS++;
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}