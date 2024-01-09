
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is IERC165, IERC721Enumerable, ERC721 {
    mapping(address => uint[]) internal _balances;

    //IERC721
    function balanceOf(address owner) public view override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner].length;
    }


    //IERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) external view override returns (uint tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _balances[owner][index];
    }

    function totalSupply() public view override returns (uint) {
        return tokens.length - _burned;
    }

    function tokenByIndex(uint index) external view override returns (uint) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }


    //internal
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        address zero = address(0);
        if( from != zero ){
            //find this token and remove it
            uint length = _balances[from].length;
            for( uint i; i < length; ++i ){
                if( _balances[from][i] == tokenId ){
                    _balances[from][i] = _balances[from][length - 1];
                    _balances[from].pop();
                    break;
                }
            }
        }

        if( to != zero )
            _balances[to].push( tokenId );
    }
}
