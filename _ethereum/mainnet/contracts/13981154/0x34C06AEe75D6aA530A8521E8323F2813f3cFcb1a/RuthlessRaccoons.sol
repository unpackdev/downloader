// SPDX-License-Identifier: UNLICENSED

/*                                                                                        
  _____       _   _     _                 _____                                     
 |  __ \     | | | |   | |               |  __ \                                    
 | |__) |   _| |_| |__ | | ___  ___ ___  | |__) |__ _  ___ ___ ___   ___  _ __  ___ 
 |  _  / | | | __| '_ \| |/ _ \/ __/ __| |  _  // _` |/ __/ __/ _ \ / _ \| '_ \/ __|
 | | \ \ |_| | |_| | | | |  __/\__ \__ \ | | \ \ (_| | (_| (_| (_) | (_) | | | \__ \
 |_|  \_\__,_|\__|_| |_|_|\___||___/___/ |_|  \_\__,_|\___\___\___/ \___/|_| |_|___/

*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract RuthlessRaccoons is ERC721,Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint public maxInTx = 10;

    uint256 public price;
    string public metadataBaseURL;

    uint256 public constant FREE_SUPPLY = 1000;
    uint256 public constant PAID_SUPPLY = 3999;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY + PAID_SUPPLY;

    bool public paidSupply;

    constructor () 
    ERC721("Ruthless Raccoons", "RAKU") {
        paidSupply = false;
        price = 0 ether;
        metadataBaseURL = "ipfs://QmZCLv63yPvzP7drEcsBVBivdbaVdQDKRHYKrrmpK4YKMT/";
    }

    function setBaseURI(string memory baseURL) public onlyOwner {
        metadataBaseURL = baseURL;
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
        require(_tokenIdTracker.current() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens > 0, "You must claim at least one.");
        require(numOfTokens <= maxInTx, "Can't claim more than 10 in a tx.");
        require((price * numOfTokens) <= msg.value, "Insufficient funds to claim.");
        

        for(uint256 i=0; i< numOfTokens; i++) {
            if((_tokenIdTracker.current() + 1 > FREE_SUPPLY) && !paidSupply) {
                paidSupply = true;
                price = 0.015 ether;
                require((price * (numOfTokens - i)) <= msg.value, "Insufficient funds to claim.");
            }

            _safeMint(msg.sender, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
        

    }

}