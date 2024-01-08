pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract sPhunk is ERC721Enumerable {
    //Has the token been claimed
    mapping(uint256 => bool) private _claimed;
    uint256 private _claimsClosed;
    address private _phunkAddress;
    
    constructor(address _proxyRegistryAddress, address raribleProxy, address phunkAddress) 
        ERC721(_proxyRegistryAddress, raribleProxy)  { 
            _phunkAddress = phunkAddress;
            _claimsClosed = block.number + 500000;
        }
        
    function claim(uint256 tokenId) external {
        require(!_claimed[tokenId], "Token Already Claimed");
        require(block.number < _claimsClosed, "Too late to claim");
        
        IERC721 phunkContract = IERC721(_phunkAddress);
        require(phunkContract.ownerOf(tokenId) == _msgSender(), "Not owner of Phunk");
        
        emit Transfer(address(0), _msgSender(), tokenId);
        _transfer(owner(), _msgSender(), tokenId);
        _claimed[tokenId] = true;
    }
}