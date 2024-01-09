// SPDX-License-Identifier: UNLICENSED

/*

  _____     __             __ __          __       _______     __ 
 / ___/_ __/ /  ___ ____  / //_/__  ___ _/ /__ _  / ___/ /_ __/ / 
/ /__/ // / _ \/ -_) __/ / ,< / _ \/ _ `/ / _ `/ / /__/ / // / _ \
\___/\_, /_.__/\__/_/   /_/|_|\___/\_,_/_/\_,_/  \___/_/\_,_/_.__/
    /___/                                                                                                                                

*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";



contract CyberKoalaClub is ERC721,Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    
    uint public maxInTx = 10;

    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public contractURI;

    uint256 public constant FREE_SUPPLY = 1111;
    uint256 public constant PAID_SUPPLY = 3333;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY + PAID_SUPPLY;

    bool public paidSupply;


    constructor () 
    ERC721("Cyber Koala Collective", "CKC") {
        
        saleEnabled = false;
        paidSupply = false;
        price = 0 ether;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
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
        require(currentSupply < MAX_SUPPLY, "All supply claimed");
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
        require(_tokenIdTracker.current() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens > 0, "You must claim at least one.");
        require(numOfTokens <= maxInTx, "Can't claim more than 10 in a tx.");
        require((price * numOfTokens) <= msg.value, "Insufficient funds to claim.");
        

        for(uint256 i=0; i< numOfTokens; i++) {
            if((_tokenIdTracker.current() + 1 > FREE_SUPPLY) && !paidSupply) {
                paidSupply = true;
                price = 0.006 ether;
                require((price * (numOfTokens - i)) <= msg.value, "Insufficient funds to claim.");
            }

            _safeMint(msg.sender, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
        

    }

}