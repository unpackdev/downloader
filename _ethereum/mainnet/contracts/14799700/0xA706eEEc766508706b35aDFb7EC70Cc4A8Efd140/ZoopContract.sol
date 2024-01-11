

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";



contract ZPPONE is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    uint256 private _currentTokenId = 0;
    uint256 private _mintQuantity = 0;
    uint256 private _totalSupply = 0;  //change later 

    bool public isSaleActive;


    // mint price 
    uint256 public MINT_PRICE = 0.074 ether;

    uint256 public maxMintPerAddress = 5;



    mapping(uint256 => string) private _tokenURIs;
    mapping(string => uint8) existingURIs;
    mapping(address => uint256) walletMintCount;

    constructor() ERC721("Zoop Priority Pass", "ZPPONE") {

        _totalSupply = 7500;
    }


    
    function _baseURI() override internal pure returns (string memory){
        return "https://gateway.pinata.cloud/ipfs/QmTshumWBt6ULnkBd4HYxgC4cy3S3qWEM6PTZuv1WrEkFw/";
    }

    

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721 Metadata: URI query for nonexistence token!" );
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }


    function isNftOwned(string memory uri) public view returns (bool){
        return existingURIs[uri] == 1;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function saleStatus() public view returns (bool){
        if(_currentTokenId == _totalSupply){
            return false;
        }
        return true;
    }

    function toggleSaleStatus() external onlyOwner{
        isSaleActive = !isSaleActive;
    }

    function verifyMessage(bytes32 _hashMessage, uint8 _v, bytes32 _r, bytes32 _s, address _wallet) public view returns (bool){

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        
        if(signer == _wallet){
            return true;
        }

        return false; 

    }


    function mint(address recipient, uint256 quantity, bytes32 _hashMessage, uint8 _v, bytes32 _r, bytes32 _s) public virtual payable returns (uint256) {
        require(quantity <= 5, "Too Much Amount");
        require(msg.value == MINT_PRICE * quantity,   "Invalid Payment Amount");
        require(_currentTokenId <= _totalSupply, "Minting Sale Over!") ;
        require(walletMintCount[msg.sender] + 1 <= maxMintPerAddress, "Exceeded Mint Amount");
        require(verifyMessage(_hashMessage, _v, _r, _s, recipient), "You need to Sign Before Minting");



        uint256 newItemId;
        for(uint i=0; i < quantity; i++){
        
            _tokenIds.increment();
            newItemId = _tokenIds.current();

            walletMintCount[msg.sender] ++;
            _mint(recipient, newItemId);
            _currentTokenId = _currentTokenId + 1; 

        }
        return newItemId;
    }

    function mintMobile(address recipient, uint256 quantity) public virtual payable returns (uint256) {
        require(quantity <= 5, "Too Much Amount");
        require(msg.value == MINT_PRICE * quantity,   "Invalid Payment Amount");
        require(_currentTokenId <= _totalSupply, "Minting Sale Over!") ;
        require(walletMintCount[msg.sender] + 1 <= maxMintPerAddress, "Exceeded Mint Amount");



        uint256 newItemId;
        for(uint i=0; i < quantity; i++){
        
            _tokenIds.increment();
            newItemId = _tokenIds.current();

            walletMintCount[msg.sender] ++;
            _mint(recipient, newItemId);
            _currentTokenId = _currentTokenId + 1; 

        }
        return newItemId;
    }


    function getTokenId() public view returns (uint256){

        return _currentTokenId; 
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

  


    

    


}