
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./AM721.sol";
import "./IERC721Enumerable.sol";

abstract contract AM721Enumerable is IERC165, IERC721Enumerable, AM721 {
    mapping(address => uint) internal _balances;

    function balanceOf(address owner) public view override returns(uint256 balance){
        return _balances[owner];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AM721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) external view override returns (uint tokenId) {
        require(index < balanceOf(owner), "AM721Enumerable: owner index out of bounds");

        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }

        revert("AM721Enumerable: owner index out of bounds");
    }

    function totalSupply() public view override returns (uint) {
        return _owners.length - _burned;
    }

    function tokenByIndex(uint index) external view override returns (uint) {
        require(index < totalSupply(), "AM721Enumerable: global index out of bounds");
        return index;
    }


    //internal
    function _beforeTokenTransfer(address from, address to) internal override {
        address zero = address(0);
        if( from != zero )
            --_balances[from];

        if( to != zero )
            ++_balances[to];
    }
}
