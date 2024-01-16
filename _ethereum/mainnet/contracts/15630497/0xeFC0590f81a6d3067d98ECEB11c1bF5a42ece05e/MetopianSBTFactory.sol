// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./strings.sol";
import "./addressFormatter.sol";
import "./IMetopianSBTFactory.sol";


contract MetopianSBTFactory is IMetopianSBTFactory, Ownable{
    
	using strings for *;
    using Counters for Counters.Counter;

    event Issue(uint typeId);
    event Update(uint typeId);


    Counters.Counter private _tokenTypeId;
    TokenType[] public _tokenTypes;

    constructor(){
        
    }

    function transferOwnership(uint id, address newOwner) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(id < _tokenTypeId.current() && _tokenTypes[id].owner == msg.sender, "Invalid id");
        _tokenTypes[id].owner = newOwner;
    }

    function issue(string memory featuredImageCID, string memory title, string memory space, string memory description, string[] memory fields) public {
        require(bytes(featuredImageCID).length==46, "CID Len error");
        _tokenTypeId.increment();
        _tokenTypes.push(TokenType(featuredImageCID, title, space, description, replace(title, " ", "%20"), replace(space, " ", "%20"), replace(description, " ", "%20"), fields, msg.sender));
        emit Issue(_tokenTypeId.current() - 1);
    }

    function update(uint id, string memory featuredImageCID, string memory title, string memory space, string memory description, string[] memory fields) public{
        require(id < _tokenTypeId.current() && _tokenTypes[id].owner == msg.sender, "Invalid id");
        require(bytes(featuredImageCID).length==46, "CID Len error");
        _tokenTypes[id].featuredImageCID=featuredImageCID;
        _tokenTypes[id].title=title;
        _tokenTypes[id].titleEncoded = replace(title, " ", "%20");
        _tokenTypes[id].space=space;
        _tokenTypes[id].spaceEncoded=replace(space,  " ", "%20");
        _tokenTypes[id].description=description;
        _tokenTypes[id].descriptionEncoded=replace(description,  " ", "%20");
        _tokenTypes[id].fields=fields;
        // _tokenTypes[id].issuerName = lookupName(msg.sender);
    }

    function replace(string memory _str, string memory _find, string memory _to) private pure returns(string memory) {
        strings.slice memory s = _str.toSlice();
        strings.slice memory delim = _find.toSlice();
        strings.slice memory to = _to.toSlice();
        strings.slice memory buff = "".toSlice();
 
        while(!s.empty()){
            buff = buff.concat(s.split(delim)).toSlice();
            if(!s.empty()){
                buff = buff.concat(to).toSlice();
            }
        }
        return buff.toString();
    }

    
    function tokenType(uint id) external view override returns(TokenType memory){
        require(id < _tokenTypeId.current(), "Invalid id");
        return _tokenTypes[id];
    }
}