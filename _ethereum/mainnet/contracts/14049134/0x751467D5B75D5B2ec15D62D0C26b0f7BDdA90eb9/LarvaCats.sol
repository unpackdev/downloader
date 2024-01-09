// SPDX-License-Identifier: UNLICENSED

/*

                                            
 __                       _____     _       
|  |   ___ ___ _ _ ___   |     |___| |_ ___ 
|  |__| .'|  _| | | .'|  |   --| .'|  _|_ -|
|_____|__,|_|  \_/|__,|  |_____|__,|_| |___|
                                            

*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";



contract LarvaCats is ERC721,Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    
    uint public maxInTx = 10;

    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public constant FREE_SUPPLY = 1111;
    uint256 public constant PAID_SUPPLY = 3333;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY + PAID_SUPPLY;


    constructor () 
    ERC721("Larva Cats", "LCATS") {    
        saleEnabled = false;
        price = 0.015 ether;
    }

    function setBaseURI(string memory baseURL) public onlyOwner {
        metadataBaseURL = baseURL;
    }

    function setMaxInTx(uint num) public onlyOwner {
        maxInTx = num;
    }

    function toggleSaleStatus() public onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function mintToAddress(address to) private onlyOwner {
        uint256 currentSupply = _tokenIdTracker.current();
        require((currentSupply + 1) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(to, currentSupply + 1);
        _tokenIdTracker.increment();
    }

    function reserve(uint num) public onlyOwner {
        uint256 i;
        for (i=0; i<num; i++)
            mintToAddress(msg.sender);
            
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint(uint256 numOfTokens) public payable {
        require(saleEnabled, "Sale must be active.");
        require(_tokenIdTracker.current() + numOfTokens <= MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= maxInTx, "Can't claim more than 10.");
        require((price * numOfTokens) <= msg.value, "Insufficient funds to claim.");
        

        for(uint256 i=0; i< numOfTokens; i++) {
            _safeMint(msg.sender, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
        

    }

    function freeMint(uint256 numOfTokens) public payable {
        require(saleEnabled, "Sale must be active.");
        require(_tokenIdTracker.current() + numOfTokens <= FREE_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= maxInTx, "Can't claim more than 10.");
        

        for(uint256 i=0; i< numOfTokens; i++) {
            _safeMint(msg.sender, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
        

    }

}