// SPDX-License-Identifier: MIT
// ForTube2.0 Contracts v1.2

pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IForTube3Token.sol";

contract ForTubePromoterPass is ERC721Enumerable, ERC2981, Ownable {
    
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private deedId;

    string private baseURI;
    uint256 private _mintingValue;
    uint256 private _maxLimitedSupply;
    uint256 private _maxRegularSupply;
    uint256 private _maxOwndLimited;
    uint256 private _maxOwndRegular;
    uint256 private _mintDelay;
    bool private _preMintPause;
    bool private _publicMintPause;
    address private _fortube3Token;

    mapping(address => uint256) private _ownedLimitedTokens;
    mapping(address => uint256) private _ownedRegularTokens;
    mapping(address => uint256) private _mintedBlock;
    mapping(address => bool) private _whitelist;
    mapping(uint256 => bool) private _mintedIds;

    constructor(address address_)
    ERC721("ForTube Promoter Pass NFT", "FORTUBEPP")
    {

        baseURI = "https://api.fortube.io/promoterpass/token/";
        _mintingValue = 1 ether;
        _maxLimitedSupply = 1000;
        _maxRegularSupply = 10000;
        _maxOwndLimited = 2;
        _maxOwndRegular = 10;
        _mintDelay = 15;
        _preMintPause = false;
        _publicMintPause = true;
        _setDefaultRoyalty(owners(0), 750);
        _fortube3Token = address_;

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function preMint() public payable {
        
        uint256 newTokenId = _incrementId();

        require(msg.value == _mintingValue, "PP : unmatched the value required to mint");
        require(newTokenId <= _maxLimitedSupply, "PP : Exceeded max supply");
        require(!_preMintPause, "PP : paused pre-minting");
        require(_ownedLimitedTokens[msg.sender] < _maxOwndLimited, "PP : exceeded max owned volume for the Limited Edition");
        require(_whitelist[msg.sender], "not whitelisted or already minted");
        require(block.number > _mintedBlock[msg.sender]+_mintDelay, "PP : delay to prevent bots");
        require(_fortube3Token != address(0), "PP : ForTube3.0 Token is not ready");

        _mintedIds[newTokenId] = true;
        _safeMint(msg.sender,newTokenId);
        _whitelist[msg.sender] = false;
        IForTube3Token(_fortube3Token).addMining(newTokenId, msg.sender);
        _transferToOfficalWallet(msg.value);
    }

    function publicMint() public payable {

        uint256 newTokenId = _incrementId();

        require(msg.value == _mintingValue, "PP : unmatched the value required to mint");
        require(newTokenId <= _maxRegularSupply, "PP : exceeded max supply");
        require(!_publicMintPause, "PP : paused public minting");
        require(block.number > _mintedBlock[msg.sender]+_mintDelay, "PP : delay to prevent bots");
        require(_fortube3Token != address(0), "PP : ForTube3.0 Token is not ready");
        
        if(newTokenId <= _maxLimitedSupply){
            require(_ownedLimitedTokens[msg.sender] < _maxOwndLimited, "PP : exceeded max owned volume for the Limited Edition");
        }else{
            require(_ownedRegularTokens[msg.sender] < _maxOwndRegular, "PP : exceeded max owned volume for the Regular Edition");
        }                                

        _mintedIds[newTokenId] = true;
        _safeMint(msg.sender,newTokenId);
        IForTube3Token(_fortube3Token).addMining(newTokenId, msg.sender);
        _transferToOfficalWallet(msg.value);

    }

    function airdrops(address[] memory owners, uint256[] memory ids) public onlyOwners {

        require( ids.length == owners.length, "PP : array size mismatch" );

        for (uint256 i = 0; i < owners.length; i++) {
            require( !_mintedIds[ids[i]] && ids[i] <= _maxRegularSupply, "PP : invalid ID" );
            _mintedIds[ids[i]] = true;
            _safeMint(owners[i],ids[i]);
            IForTube3Token(_fortube3Token).addMining(ids[i], owners[i]);
        }
    }

    function addWhiteList(address[] memory lists) public onlyOwners {
        require(lists.length <= _maxLimitedSupply, "PP : out of size");
        for(uint256 i = 0; i < lists.length; i++){
            if( lists[i] != address(0) )    _whitelist[lists[i]] = true;
        }
    }

    function setMintingValue(uint256 value) public onlyOwner {
        _mintingValue = value;
    }

    function setPreMintPaused(bool paused) public onlyOwners {
        _preMintPause = paused;
    }

    function setPublicMintPaused(bool paused) public onlyOwners {
        _publicMintPause = paused;
    }

    function setFortube3Token(address fot) public onlyOwner {
        _fortube3Token = fot;
    }
    
    function whitelist(address sender) public view returns (bool){
        return _whitelist[sender];
    }

    function mintingValue() public view returns (uint256){
        return _mintingValue;
    }

    function fortube3Token() public view returns (address){
        return _fortube3Token;
    }

    function burn(uint256 tokenId) public {
        require( msg.sender == ownerOf(tokenId) || msg.sender == owners(0) , "PP : caller is not owner");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,tokenId.toString())) : ''; 
    }

    function _incrementId() private returns (uint256){
        deedId.increment();
        while( _mintedIds[deedId.current()] ){
            deedId.increment();
        }
        return deedId.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if(from == address(0)){
            _ownedLimitedTokens[to]++;
        }else if(to == address(0)){
            _ownedLimitedTokens[from]--;
        }else{
            _ownedLimitedTokens[to]++;
            _ownedLimitedTokens[from]--;
            IForTube3Token(_fortube3Token).mintByTransferring(tokenId);
        }
    }

}


