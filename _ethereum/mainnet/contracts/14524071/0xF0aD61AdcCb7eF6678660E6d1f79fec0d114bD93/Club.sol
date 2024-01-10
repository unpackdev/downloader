
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Club {
    uint256[] private _memberTokens;
    mapping(uint256 => uint256) private _tokenIndices;
    event LotteryWin(address indexed to, uint256 indexed tokenId);

function _addMember(uint tokenId) internal {
   if(!isMember(tokenId)){
       uint256 newPseudoIndex = _memberTokens.length+1;
       _memberTokens.push(tokenId);
       _tokenIndices[tokenId]=newPseudoIndex;
}

}
function _removeMember(uint256 tokenId) internal{
    if(isMember(tokenId)){
        uint256 lastToken = _memberTokens[_memberTokens.length -1];
        uint256 oldIndex = _tokenIndices[tokenId];
        _tokenIndices[lastToken] =  oldIndex;
        _memberTokens[oldIndex-1] = lastToken;
        delete _tokenIndices[tokenId];
        _memberTokens.pop();
    }
}
function isMember(uint256 tokenId) public view returns(bool){
    return _tokenIndices[tokenId]>0;
}

function numberOfMembers() public view returns (uint256){
    return _memberTokens.length;
}



function getMemberByIndex(uint256 index)public view returns(uint256){
    require(index<_memberTokens.length, "index is to big");
    return _memberTokens[index];
}
}



