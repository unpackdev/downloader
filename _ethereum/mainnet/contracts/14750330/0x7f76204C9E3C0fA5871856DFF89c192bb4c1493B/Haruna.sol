// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Psi.sol";

contract HARUNA is ERC721Psi, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    bool public _isSaleActive = false;
    bool public _isWLSaleActive = false;
    bool public _revealed = false;

    
    uint256 public MAX_SUPPLY = 777;
    uint256 public mintPrice = 0.088 ether;
    uint256 public WL_mintPrice = 0.055 ether;
    uint256 public maxBalance = 10;


    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    //tokenURI
    mapping(uint256 => string) private _tokenURIs;

    //signer
    address private _signer;

    //core-F
    address core_F;

    //funds
    address funds;

    //connect
    address connect;

    //whiteList counter
    mapping(address=>uint256) whitelist_counter;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721Psi("Haruna","Future")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    //modifier
    modifier callerIsContract(){
        require(msg.sender == connect || tx.origin == msg.sender,"caller is mot human!");
        _;
        }
    modifier notExceedMax_Supply(uint256 tokenQuantity){
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY,"Sale would exceed max supply");
        _;
        }
    modifier saleTime(){
        require(_isSaleActive, "Sale must be active to mint HARUNA Metas");
        _;
        }
    modifier balance(uint256 tokenQuantity){
        require(balanceOf(msg.sender) + tokenQuantity <= maxBalance,"Sale would exceed max balance");
        _;
        }
    //mintFunction
    function mintHARUNA(uint256 tokenQuantity) 
    public payable nonReentrant 
    callerIsContract 
    notExceedMax_Supply(tokenQuantity)
    saleTime
    balance(tokenQuantity)
    {
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        _mintHARUNA(tokenQuantity);
    }
    function mintHARUNA_Owner(uint256 tokenQuantity) 
    public payable 
    onlyOwner 
    callerIsContract
    notExceedMax_Supply(tokenQuantity)
    {
        _mintHARUNA(tokenQuantity);
    }
    //WL
    function isWhitelisted(bytes memory signature) internal view returns(bool){
        bytes32 messagehash = keccak256(
             abi.encodePacked(address(this), msg.sender)
         );
         address signer = messagehash.toEthSignedMessageHash().recover(
             signature
         ); 
            return((_signer == signer));
  }
    function mintHARUNA_WL(uint256 tokenQuantity, bytes memory signature) 
    public payable 
    nonReentrant 
    callerIsContract
    notExceedMax_Supply(tokenQuantity)
    balance(tokenQuantity)
    {
        require(_isWLSaleActive,"Sale must be active to mint HARUNA Metas");
        require(isWhitelisted(signature), "Must be whitelisted");
        require(
            tokenQuantity * WL_mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(whitelist_counter[msg.sender] + tokenQuantity < 3,"");
        whitelist_counter[msg.sender] = whitelist_counter[msg.sender] + tokenQuantity;
        if(tokenQuantity == 2){
            tokenQuantity = tokenQuantity + 1;
        }
        _mintHARUNA(tokenQuantity);
    }
    function _mintHARUNA(uint256 tokenQuantity) internal  {
        if (totalSupply()+tokenQuantity < MAX_SUPPLY) {
            _safeMint(msg.sender, tokenQuantity);
        }
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_revealed == false) {
            return notRevealedUri;
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }
    function flipWLSaleActive() public onlyOwner {
        _isWLSaleActive = !_isWLSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance_core = address(this).balance * 2560 / 10000;
        uint256 balance_fund = address(this).balance * 7440 / 10000;
        payable(core_F).transfer(balance_core);
        payable(funds).transfer(balance_fund);
    }

    function setCore_F(address core_F_) public onlyOwner {
        core_F = core_F_;
    }
    function setfunds(address funds_) public onlyOwner {
        funds = funds_;
    }
    function setSigner(address signer)public onlyOwner
    {
        _signer = signer;
    }
    function set_WL_mint(address WL, uint256 numb) public onlyOwner{
        whitelist_counter[WL] = numb;
    }
    function set_connect(address _connect) public onlyOwner{
        connect = _connect;
    }
    function set_MAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner{
        MAX_SUPPLY = _MAX_SUPPLY;
    }
    function check_WL(address WL) public view onlyOwner returns(uint256 times){
        times = whitelist_counter[WL];
    }
}