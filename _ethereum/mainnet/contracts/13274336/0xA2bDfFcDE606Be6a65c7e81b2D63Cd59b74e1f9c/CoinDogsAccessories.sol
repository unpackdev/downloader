// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Delegable.sol";

/**
 * @title CryptoDogsAccessories
 */

contract CoinDogsAccessories is ERC1155, Delegable
{
    using Strings for string;
    mapping(uint256 => string) private _uris;
    mapping(uint256 => address) private _creators;
    string private _defaultUri;
    string public name;
    string public symbol;
    constructor( string memory defaultUri_) ERC1155(defaultUri_) {
        name = "RinkeDogA";
        symbol = "RKDA";
        _defaultUri = defaultUri_;
    }
    
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        string memory _uri
    ) public onlyOwnerOrApproved {
    _mint(_to, _id, _quantity, "");
    _uris[_id] = _uri;
    _creators[_id] = _to;
  }

    function setDefaultUri(string memory _uri)public onlyOwnerOrApproved{
        _defaultUri = _uri;
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender())  || isApproved(_msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) || isApproved(_msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 id) public view override returns (string memory){
        if (_exists(id))
            return _uris[id];
        else
            return _defaultUri;
    }
    
    function _exists(
            uint256 _id
        ) public view returns (bool) {
        return _creators[_id] != address(0);
    }

}