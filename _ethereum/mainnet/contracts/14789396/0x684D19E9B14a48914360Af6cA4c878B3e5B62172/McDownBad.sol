//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Owned.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";

//  /$$      /$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$      /$$ /$$   /$$ /$$$$$$$   /$$$$$$  /$$$$$$$
// | $$$    /$$$ /$$__  $$| $$__  $$ /$$__  $$| $$  /$ | $$| $$$ | $$| $$__  $$ /$$__  $$| $$__  $$
// | $$$$  /$$$$| $$  \__/| $$  \ $$| $$  \ $$| $$ /$$$| $$| $$$$| $$| $$  \ $$| $$  \ $$| $$  \ $$
// | $$ $$/$$ $$| $$      | $$  | $$| $$  | $$| $$/$$ $$ $$| $$ $$ $$| $$$$$$$ | $$$$$$$$| $$  | $$
// | $$  $$$| $$| $$      | $$  | $$| $$  | $$| $$$$_  $$$$| $$  $$$$| $$__  $$| $$__  $$| $$  | $$
// | $$\  $ | $$| $$    $$| $$  | $$| $$  | $$| $$$/ \  $$$| $$\  $$$| $$  \ $$| $$  | $$| $$  | $$
// | $$ \/  | $$|  $$$$$$/| $$$$$$$/|  $$$$$$/| $$/   \  $$| $$ \  $$| $$$$$$$/| $$  | $$| $$$$$$$/
// |__/     |__/ \______/ |_______/  \______/ |__/     \__/|__/  \__/|_______/ |__/  |__/|_______/

contract McDownBad is ERC721AQueryable, ReentrancyGuard, Owned(msg.sender) {
    using Strings for uint256;
    address private devWallet;
    string private baseURIExtended;
    string private _unrevealedURI;
    bool public saleActive = false;
    bool public revealed = false;
    uint256 public constant tokenPrice = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 4445; //Real max is 4444
    uint256 public constant MAX_MINT = 11; //Real max is 20
    uint256 public constant FREE_SUPPLY = 2222;

    constructor (address _devWallet, string memory _initBaseURI) ERC721A ("McDownBad", "MCDB"){
        _unrevealedURI = _initBaseURI;
        devWallet = _devWallet;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "NO_CONTRACTS");
        _;
    }

    //function to claim the shapeshifter NFT
    function mcDownBaddddddd(uint256 _numberOfTokens) 
        external 
        payable 
        nonReentrant 
        callerIsUser 
    {
        //validation before minting
        require(saleActive, "PAUSED");
        require(MAX_SUPPLY > _currentIndex + _numberOfTokens, "MAX_SUPPLY");
        require(calcPrice(_numberOfTokens) * _numberOfTokens == msg.value, "NOT_ENOUGH_ETH");
        require(MAX_MINT > _numberOfTokens, "EXCEED_MAX");

        _mint(msg.sender, _numberOfTokens);
    }

    function calcPrice(uint _numberOfTokens) 
        internal 
        view 
        returns(uint)
    {
        if(_currentIndex + _numberOfTokens > FREE_SUPPLY) {
            return tokenPrice;
        } else {
            return 0;
        }
    }

    //Override the baseURI to show only the new value
    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
        return baseURIExtended;
    }

    //function to set the new baseURI for the NFT
    function setBaseURI(string memory _baseURIExtended) 
        public 
        onlyOwner
    {
        baseURIExtended = _baseURIExtended;
    }

    //function to set the new baseURI for the NFT
    function setUnrevealedURI(string memory _unrevealed) 
        public 
        onlyOwner
    {
        _unrevealedURI = _unrevealed;
    }

    //Withdraw function to the dev wallet.
    function withdrawETH() 
        public 
        onlyOwner 
    {
        Address.sendValue(payable(devWallet), address(this).balance);
    }

    //function to unpause the smart contract
    function flipSaleActive() 
        public 
        onlyOwner
    {
        saleActive = !saleActive;
    }

    function flipReveal() 
        public 
        onlyOwner 
    {
        revealed = !revealed;
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override(ERC721A, IERC721Metadata) 
        returns (string memory) 
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        
        if (!revealed) {
            return _unrevealedURI;
        }

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}