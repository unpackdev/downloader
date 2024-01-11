//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Owned.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

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
    using ECDSA for bytes32;

    address private devWallet;
    address private privateMintingAddress;
    string private baseURIExtended;
    string private _unrevealedURI;
    bool private saleActive = false;
    bool private whitelistActive = false;
    bool private revealed = false;
    uint256 public tokenPrice = 0.0069 ether;
    uint256 public constant MAX_SUPPLY = 4445; //Real max is 4444
    uint256 public constant MAX_MINT = 11; //Real max is 10
    uint256 public constant FREE_SUPPLY = 2222;
    uint256 private constant WHITELIST_MAX_SUPPLY = 991;

    mapping(address => bool) private whitelist;

    constructor (address _devWallet, address _privateMint, string memory _initBaseURI) ERC721A ("McDownBad", "MCDB"){
        _unrevealedURI = _initBaseURI;
        devWallet = _devWallet;
        privateMintingAddress = _privateMint;
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

    //function to claim the shapeshifter NFT
    function assistantToTheRegionalManager(uint256 _numberOfTokens, bytes calldata _sig) 
        external 
        nonReentrant 
        callerIsUser 
    {
        //validation before minting
        require(whitelistActive, "WHITELIST_PAUSED");
        require(privateMintingAddress == _verifySignature(_sig), "NOT_WHITELISTED");
        require(WHITELIST_MAX_SUPPLY > _currentIndex + _numberOfTokens, "WHITELIST_MAX_SUPPLY");
        require(MAX_MINT > _numberMinted(msg.sender) + _numberOfTokens, "EXCEED_MAX");

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

    function _verifySignature(bytes calldata signature)
        internal
        view
        returns(address)
    {
        return keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature);
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
        external 
        onlyOwner
    {
        baseURIExtended = _baseURIExtended;
    }

    //function to set the new baseURI for the NFT
    function setUnrevealedURI(string memory _unrevealed) 
        external 
        onlyOwner
    {
        _unrevealedURI = _unrevealed;
    }

    //Withdraw function to the dev wallet.
    function withdrawETH() 
        external 
        onlyOwner 
    {
        Address.sendValue(payable(devWallet), address(this).balance);
    }

    function changePrice(uint256 _newPrice) 
        external 
        onlyOwner 
    {
        tokenPrice = _newPrice;
    }

    //function to unpause the smart contract
    function flipSaleActive() 
        external 
        onlyOwner
    {
        saleActive = !saleActive;
    }

    function flipWhitelistActive() 
        external 
        onlyOwner
    {
        whitelistActive = !whitelistActive;
    }

    function flipReveal() 
        external 
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