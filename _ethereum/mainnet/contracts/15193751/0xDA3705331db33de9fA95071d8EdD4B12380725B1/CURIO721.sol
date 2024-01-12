// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";




 
 /**
 * @title CurioERC721
 * CurioERC721 - ERC721 contract for Curio platform, that whitelists a trading address, and has minting functionality
 * Based off of ERC721 contract (openzeppelin/contracts 3.2.0) with solidity 0.6.0, pulls elements from ERC721Tradable
 * Batch Lazy Minting capabilities added to offset gas fees at minting and push the true 'minting' costs to first transfer
 * Inspired by the Gods Unchained process for card activation and event transmittals
 * Requires making virtual isApprovedForAll, totalSupply, _exists in ERC721.sol
 * NOTE: Enumeration capabilities are not fully supported until all minted tokens have been activated
 */

contract CurioERC721 is ERC721, Ownable, ERC2981ContractWideRoyalties {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    string public contractURI;
    
    uint96 royaltyFeesInBips;
    address royaltyAddress;

   
    uint256 private _currentTokenId = 0;
  
    
    mapping(uint256 => bool) private _activated;
    uint256 private _totalSupply;
    uint256 private _activatedSupply = 0;
    
    address private omnibusAddress;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _contractURI,
        uint96 _royaltyFeesInBips
       ) 
        ERC721(_name, _symbol) {
       
         contractURI = _contractURI;
         royaltyFeesInBips = _royaltyFeesInBips;
       
       
    }



  function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }



 string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }



    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

  //Approvals


  function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {

        return super.isApprovedForAll(owner, operator);
    }

    
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
   

  


    /**
     * @dev Mints a token to an address, and activates it immediately (non-lazy)
     * @param _to address of the future owner of the token
     */
    function mint(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();

        if (!_activated[newTokenId]) {
            _activateTokenId(newTokenId);
        }        
    }
    
	/**
     * @dev Lazy mints a batch of tokens to an address, does not activate them
     * @param _to address of the omnibus wallet
     */
    function batchLazyMint(address _to, uint256 _size) public onlyOwner {
    	require(
            _to != address(0),
            "address must not be null"
        );

        require(
            _size > 0 && _size <= 1000,
            "size must be within limits"
        );
        
        uint256 newTokenId = _currentTokenId;
        
        for (uint256 i = 0; i < _size; i++) {
	        newTokenId++;	
            emit Transfer(address(0), _to, newTokenId);
        }
        
        omnibusAddress = _to;
        _currentTokenId = newTokenId; //only set it at the end
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        if (owner == omnibusAddress) {
        	return _currentTokenId.sub(_activatedSupply).add(super.balanceOf(owner)); //for return to omnibusAddress
		} else {
	        return super.balanceOf(owner);
		}
    }    

     function ownerOf(uint256 _tokenId) public view override returns (address) {
         require(_exists(_tokenId), "ERC721: owner query for nonexistent token");
         
         if (_activated[_tokenId]) {
             return super.ownerOf(_tokenId);
         } else {
         	return omnibusAddress;
         }
     }

    function _exists(uint256 _tokenId) internal view override returns (bool) {
        if (_activated[_tokenId]) {
	        return super._exists(_tokenId);
        } else {
        	if (_tokenId > 0 && _tokenId <= _currentTokenId) {
                return true;
            }
            return false;
        }
    }
    
    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }    
 function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);

         if (!_activated[tokenId]) {
            _activateTokenId(tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public  virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        super.safeTransferFrom(from, to, tokenId, _data);

        if (!_activated[tokenId]) {
            _activateTokenId(tokenId);
        }
    }

    /**
     * @dev marks a token ID as activated, increments the value of _activatedSupply
     */
    function _activateTokenId(uint256 _tokenId) private {
        require(!_activated[_tokenId], "Token already activated");
        _activated[_tokenId] = true;
        _activatedSupply++;
    }    
    
	/**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }





    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    
}