// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract PCC_POAP_Claim is ERC721, Ownable, ReentrancyGuard, Pausable, ERC721Enumerable {
   using Counters for Counters.Counter;
   using Strings for uint256;
   using SafeMath for uint256;
   
   mapping(address => bool)[50] public Whitelist;
   mapping(address => bool)[50] public AddressRedeemed;
   
   string[50] ImageHashes;
   
   uint256[] public ImageOffset = [0, 500];
   uint256 private tokenCount;
   Counters.Counter[50] private _tokenCounter;
   Counters.Counter private _collectionCount;
   
   string public BaseUri = "ipfs://";
   
   
       constructor() ERC721("Non Fungible Idiots","NFI") {    
           _collectionCount.increment(); //1
    } 
    
    function collectionTotalSupply(uint256 _index) public view tokenExists(_index) returns(uint256)  {
        return _tokenCounter[_index].current();
    } 
    
    function addWhitelist(uint256 index, address[] memory addresses) public onlyOwner tokenExists(index) {
        for(uint256 i; i < addresses.length; i++){
            Whitelist[index][addresses[i]] = true;
        }
    }
    
    function adjustLastCollectionSize(uint256 _newSize) public onlyOwner{
        uint256 index = ImageOffset.length.sub(2);
        require(_tokenCounter[index].current() <= _newSize, "Cannot reduce collection size less than current count");
        ImageOffset[index.add(1)] = ImageOffset[index].add(_newSize);
    }
    

    function addNewCollection(uint256 _size, string memory _hash) public onlyOwner {
        uint256 index = _collectionCount.current();
        uint256 start_number = ImageOffset[index];
        ImageHashes[_collectionCount.current()] = _hash;
        _collectionCount.increment();
        ImageOffset.push(start_number.add(_size));
    }
    
    function updateCollectionHash(uint256 _index, string memory _hash) public onlyOwner tokenExists(_index){
        ImageHashes[_index] = _hash;
    }
    
    function updateBaseUri(string memory _uri) public onlyOwner{
        BaseUri = _uri;
    }

    function redeemGift(uint256 index) public nonReentrant whenNotPaused tokenExists(index) {
        require(Whitelist[index][msg.sender], "Address not on whitelist");
        require(!AddressRedeemed[index][msg.sender], "Address has already redeemed");
        require(_tokenCounter[index].current().add(ImageOffset[index]) < ImageOffset[index+1], "Cannot redeem this many tokens");
        
        _tokenCounter[index].increment();
        _mint(msg.sender, _tokenCounter[index].current().add(ImageOffset[index]));
        
        AddressRedeemed[index][msg.sender] = true;
        tokenCount++;
    }
    
    function devMint(uint256 index, uint256 quantity, address _to) public nonReentrant onlyOwner tokenExists(index){
        require(_tokenCounter[index].current().add(quantity + ImageOffset[index]) <= ImageOffset[index + 1], "Cannot redeem this many tokens");
        
        for(uint256 i; i < quantity; i++){
        _tokenCounter[index].increment();
        _mint(_to, _tokenCounter[index].current().add(ImageOffset[index]));  
        }
        tokenCount = tokenCount.add(quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        ownerOf(tokenId); // << check for non-existent token
        uint256 index = getIndex(tokenId);
        
        return string(abi.encodePacked(BaseUri, ImageHashes[index]));
        
    }
    
    function getIndex(uint256 _tokenId) private view returns(uint256){
        for(uint256 i; i < ImageOffset.length; i++){
            if (_tokenId <= ImageOffset[i]){
                return i.sub(1);
            }
        }
        require(false, "token out of range");
        return 0;
    }
    
        function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function claimStatus(uint256 index, address addy) public view returns(bool canClaim, bool hasClaimed) {
        canClaim = Whitelist[index][addy];
        hasClaimed = AddressRedeemed[index][addy];
    }
    
    function totalSupply() public override view returns(uint256 supply){
        supply = tokenCount;
    }
    
    function tokenTotalSupply(uint256 tokenId) public view tokenExists(tokenId) returns(uint256){
        return _tokenCounter[tokenId].current();
    }
    
    function togglePause() public onlyOwner {
        if (paused()){
            _unpause();
        }
        else{
            _pause();
        }
    }
    
        function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
       modifier tokenExists(uint256 tokenId) {
      require(tokenId < _collectionCount.current(), "token does not exist" );
    _;
       }
}