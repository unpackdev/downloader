// SPDX-License-Identifier: UNLICENSED

/*

 __   __  _______    ______   _______  _______ 
|  | |  ||       |  |      | |   _   ||       |
|  |_|  ||    ___|  |  _    ||  |_|  ||   _   |
|       ||   |___   | | |   ||       ||  | |  |
|_     _||    ___|  | |_|   ||       ||  |_|  |
  |   |  |   |___   |       ||   _   ||       |
  |___|  |_______|  |______| |__| |__||_______|

*/

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";



contract YeDAO is ERC721,Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    uint public maxInTx = 1;
    bool public saleEnabled;
    string public metadataBaseURL;
    uint256 public constant MAX_SUPPLY = 444;

    constructor ()
    ERC721("Ye DAO", "YD") {
        saleEnabled = false;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }


    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint(uint256 numOfTokens) public payable {
        require(saleEnabled, "Sale must be active.");
        require(_tokenIdTracker.current() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= maxInTx, "Can't claim more than 10 in a tx.");        

        for(uint256 i=0; i< numOfTokens; i++) {
            _safeMint(msg.sender, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
        

    }

}