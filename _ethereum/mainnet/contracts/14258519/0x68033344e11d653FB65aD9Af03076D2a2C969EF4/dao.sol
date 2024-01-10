// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract DAO is ERC721,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public _tokenURI;

    constructor() ERC721(unicode"DA☯️ Votes",unicode"☯️") {
      _tokenURI = "https://gateway.pinata.cloud/ipfs/QmWvfbTkY9iSE42t1wB7mVCm5UQ1vV3BJwWSihfaATTbtz";
      _mint(0x0E74B853587854c2Afa95890a9f1B209cbf2b994,0);  //DA☯️
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      return _tokenURI;
    }

    function updateTokenURI(string memory newURI) public onlyOwner(){
      _tokenURI = newURI;
    }

    function grantMembership(address member) public onlyOwner{
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(member, newItemId);
    }

    function revokeMembership(uint tokenID) public onlyOwner{
        _burn(tokenID);
    }

    function grantGroupMembership(address[] memory members) public onlyOwner{
        for(uint i=0;i<members.length;i++){
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(members[i], newItemId);
        }
    }

    function revokeGroupMembership(uint[] memory tokenIDs) public onlyOwner{
        for(uint i=0;i<tokenIDs.length;i++){
            _burn(tokenIDs[i]);
        }
    }
}
