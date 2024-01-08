// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";

contract StonerCatsPosters is ERC721Enumerable, Ownable{
    IERC721Enumerable stonerCats;

    string __uriBase = "https://flat-fuchsia-fairy.fission.app/json/";
    string __uriSuffix = ".json";

    uint16 private tokens;
    mapping(uint => bool) _claimed;
    bool public started = false;

    constructor(address _stonerCats) ERC721("Stoner Cats Posters","SCP"){
        stonerCats = IERC721Enumerable(_stonerCats);
    }

    function start() public onlyOwner{
        started = true;
    }

    function claim(uint _tokenId) public{
        require(started,"claim process not started");

        require(stonerCats.ownerOf(_tokenId) == msg.sender,"owner");
        require(!_claimed[_tokenId],"poster already claimed");
        require(_tokenId < 10420,"posters are for the original 10420");
        _claimed[_tokenId] = true;
        _safeMint(msg.sender,tokens++);
    }

    function claimMultiple(uint[] calldata _tokenIds) public{
        for(uint i = 0; i < _tokenIds.length; i++){
            claim(_tokenIds[i]);
        }
    }

    function claimable(uint _tokenId) public view returns(bool){
        return _tokenId < 10420 && !_claimed[_tokenId];
    }

    function unclaimed(uint start_index, uint limit) public view returns(uint[] memory){
        uint unclaimedTokens;
        uint balance = stonerCats.balanceOf(msg.sender);
        if(balance == 0){
            uint[] memory _unclaimed;
            return _unclaimed;
        }

        require(start_index < balance,"Invalid start index");
        uint sampleSize = balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        for(uint i = 0; i < sampleSize; i++){
            if(claimable(stonerCats.tokenOfOwnerByIndex(msg.sender,i + start_index))){
                unclaimedTokens++;
            }
        }
        uint[] memory _tokenIds = new uint256[](unclaimedTokens);
        unclaimedTokens = 0;
        for(uint i = 0; i < sampleSize; i++){
            uint tokenId = stonerCats.tokenOfOwnerByIndex(msg.sender,i + start_index);
            if(claimable(tokenId)){
                _tokenIds[unclaimedTokens] = tokenId;
                unclaimedTokens++;
            }
        }
        return _tokenIds;
    }

    function claimed(uint start_index, uint limit) public view returns(uint[] memory){
        uint balance = balanceOf(msg.sender);
        if(balance == 0){
            uint[] memory _unclaimed;
            return _unclaimed;
        }
        require(start_index < balance,"Invalid start index");
        uint sampleSize = balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds = new uint256[](sampleSize);
        for(uint i = 0; i < sampleSize; i++){
            _tokenIds[i] = tokenOfOwnerByIndex(msg.sender,i + start_index);
        }
        return _tokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override  returns (string memory){
        require(_exists(_tokenId),"exists");

        if(_tokenId == 0){
            return string(abi.encodePacked(__uriBase,bytes("0"),__uriSuffix));
        }


        uint _i = _tokenId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }

}
