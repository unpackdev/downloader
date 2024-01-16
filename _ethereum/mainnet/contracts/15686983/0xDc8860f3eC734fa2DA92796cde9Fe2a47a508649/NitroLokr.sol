//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";


/// @title Standard ERC721 NFT.
/// @author NitroLeague.
contract NitroLokr is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    string private baseURI;
    bool private _isMetaLocked;
    uint16 public maxSupply = 500;
    uint16 public availableSupply;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        availableSupply = maxSupply;
    }
    
    function setBaseURI(string memory _baseURI) public onlyOwner {
        require(bytes(_baseURI).length > 0, "baseURI cannot be empty");
        require(_isMetaLocked == false, "contract is locked, cannot modify");

        baseURI = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json")) ;
    
    }

    function safeMint(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "quantity cannot be zero");
        require(_quantity <= availableSupply,"insufficent supply");
        

        for(uint256 i =0; i < _quantity; i++){
            _tokenIdCounter.increment();    
            _safeMint(_to, _tokenIdCounter.current());
            availableSupply = availableSupply - 1;
        }
        
    }

    function bulkMint(address[] memory _to, uint[] memory _quantity) public onlyOwner {
        require(_to.length == _quantity.length,"data inconsistent");

        uint256 _totalItems = 0;
        for(uint256 i =0; i < _quantity.length; i++){
            _totalItems = _totalItems + _quantity[i];
        }

        require(_totalItems <= availableSupply,"insufficent supply");

        for(uint256 a = 0; a < _totalItems; a++){
            for(uint256 i =0; i < _to.length; i++){
                address _owner = _to[i];
                if(_quantity[i] > 0){
                    _quantity[i] = _quantity[i]-1;

                    _tokenIdCounter.increment();    
                    _safeMint(_owner, _tokenIdCounter.current());
                    availableSupply = availableSupply - 1;
                }
                
            }
        }
    }

    function getIsMetaLocked() public view returns(bool isMetaLocked){
        return _isMetaLocked;
    }

    function lockMetaData() public onlyOwner {
         _isMetaLocked = true;
    }

    function addSupply(uint16 _quantity) public onlyOwner {
        require(_quantity > 0,"quantity cannot be zero");
        require(_isMetaLocked == false,"contract is locked, cannot modify");

        maxSupply = maxSupply + _quantity;
        availableSupply = availableSupply + _quantity;

    }
}