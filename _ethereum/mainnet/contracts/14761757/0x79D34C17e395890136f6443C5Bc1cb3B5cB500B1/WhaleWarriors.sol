// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ECDSA.sol";

// @author: olive

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                             ///
///                                                                                             ///
///  __          __ _             _        __          __                 _                     ///
///  \ \        / /| |           | |       \ \        / /                (_)                    ///
///   \ \  /\  / / | |__    __ _ | |  ___   \ \  /\  / /__ _  _ __  _ __  _   ___   _ __  ___   ///
///    \ \/  \/ /  | '_ \  / _` || | / _ \   \ \/  \/ // _` || '__|| '__|| | / _ \ | '__|/ __|  ///
///     \  /\  /   | | | || (_| || ||  __/    \  /\  /| (_| || |   | |   | || (_) || |   \__ \  ///
///      \/  \/    |_| |_| \__,_||_| \___|     \/  \/  \__,_||_|   |_|   |_| \___/ |_|   |___/  ///
///                                                                                             ///
///                                                                                             ///
///                                                                                             ///
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

contract WhaleWarriors is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 120;
    uint256 public constant START_AT = 1;
    uint256 public MAX_PER_WALLET = 1;
    bool private PAUSE = true;
    uint256 public timeLimit = 60;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;

    bool public META_REVEAL = true;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 120;
    string public sampleTokenURI;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokens;
    
    event PauseEvent(bool pause);
    event welcomeToWhaleWarriors(uint256 indexed id);
    event NewMaxElement(uint256 max);
    event NewMaxPerWallet(uint256 max);

    constructor(string memory baseURI) ERC721("Whale Warriors", "WW"){
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalToken() <= MAX_ELEMENTS, "WW Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'Caller is not the admin');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSampleURI(string memory sampleURI) public onlyOwner {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO) 
            return sampleTokenURI;
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function mintTokensOfWallet(address _wallet) public view returns (uint256) {
        return mintTokens[_wallet];
    }

    function freemint(uint256 _timestamp, bytes memory _signature) public saleIsOpen {

        uint256 total = totalToken();
        require(total + 1 <= MAX_ELEMENTS, "Max limit");

        address wallet = _msgSender();

        address signerOwner = signatureWallet(wallet,1,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        require(block.timestamp >= _timestamp - timeLimit, "Out of time");

        require(mintTokens[wallet] < MAX_PER_WALLET, "Out of max mint");

        mintTokens[wallet] = mintTokens[wallet] + 1;

        _mintAnElement(wallet, total + 1);
    }

    function signatureWallet(address wallet, uint256 _tokenAmount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _tokenAmount, _timestamp)), _signature);

    }

    function _mintAnElement(address _to, uint256 _tokenId) private {

        _tokenIdTracker.increment();
        
        _safeMint(_to, _tokenId);

        emit welcomeToWhaleWarriors(_tokenId);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyOwner{
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setMaxElement(uint256 _max) public onlyOwner{
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }

    function setMAX_PER_WALLET(uint256 _max) public onlyOwner{
        MAX_PER_WALLET = _max;
        emit NewMaxPerWallet(MAX_PER_WALLET);
    }

    function setMetaReveal(bool _reveal, uint256 _from, uint256 _to) public onlyOwner{
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function giftMint(address[] memory _addrs, uint[] memory _tokenAmounts) public onlyOwner {
        uint totalQuantity = 0;
        uint256 total = totalToken();
        for(uint i = 0; i < _addrs.length; i ++) {
            totalQuantity += _tokenAmounts[i];
        }
        require( total + totalQuantity <= MAX_ELEMENTS, "Max limit" );
        for(uint i = 0; i < _addrs.length; i ++){
            for(uint j = 0; j < _tokenAmounts[i]; j ++){
                total ++;
                _mintAnElement(_addrs[i], total);
            }
        }
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner {

        require(PAUSE, "Pause is disable");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            if(rawOwnerOf(_tokensId[i]) == address(0)){
                _mintAnElement(owner(), _tokensId[i]);
            }
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function updateTimeLimit(uint256 _timeLimit) public onlyOwner {
      timeLimit = _timeLimit;
    }
}