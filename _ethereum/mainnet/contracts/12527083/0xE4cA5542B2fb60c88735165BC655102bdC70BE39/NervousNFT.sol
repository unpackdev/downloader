// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";

//        nervous.eth
//
//         ███▄    █ ▓█████  ██▀███   ██▒   █▓ ▒█████   █    ██   ██████ 
//         ██ ▀█   █ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▒██▒  ██▒ ██  ▓██▒▒██    ▒ 
//        ▓██  ▀█ ██▒▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██░  ██▒▓██  ▒██░░ ▓██▄   
//        ▓██▒  ▐▌██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░▒██   ██░▓▓█  ░██░  ▒   ██▒
//        ▒██░   ▓██░░▒████▒░██▓ ▒██▒   ▒▀█░  ░ ████▓▒░▒▒█████▓ ▒██████▒▒
//        ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ▐░  ░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░
//        ░ ░░   ░ ▒░ ░ ░  ░  ░▒ ░ ▒░   ░ ░░    ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░▒  ░ ░
//           ░   ░ ░    ░     ░░   ░      ░░  ░ ░ ░ ▒   ░░░ ░ ░ ░  ░  ░  
//                 ░    ░  ░   ░           ░      ░ ░     ░           ░  
//                                        ░       
//                       
//        work with us: nervous.net // dylan@nervous.net


contract NervousNFT is ERC721, PaymentSplitter, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public MAX_TOKENS = 2500;
    uint public tokenPrice = 100000000000000000;

    bool public hasSaleStarted = true;
    string public constant R = "We are Nervous. Are you? Let us help you with your next NFT Project -> dylan@nervous.net";
    
    constructor(string memory name, string memory symbol, string memory baseURI, uint maxTokens, uint256 price, address[] memory payees, uint256[] memory shares) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        MAX_TOKENS = maxTokens;
        tokenPrice = price;
        _setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_TOKENS, "No more tokens");
        return tokenPrice;  // 0.1 ETH
    }
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    function mint(uint256 numTokens) public payable {
        require(SafeMath.add(totalSupply(), 1) <= MAX_TOKENS, "Exceeds maximum token supply.");
        require(numTokens > 0 && numTokens <= 10, "Machine can dispense a minimum of 1, maximum of 10 tokens");
        require(msg.value >= SafeMath.mul(calculatePrice(), numTokens), "Amount of Ether sent is not correct.");
        
        for (uint i = 0; i < numTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        
    }
}