// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155URIStorage.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

contract RAKUZA1155 is ERC1155, ERC1155URIStorage, Ownable {

    using Strings for uint256;
    /**
     * @dev A descriptive name for a collection of tokens.
     */
    string internal name_;

    /**
     * @dev An abbreviated name for a collection of tokens.
     */
    string internal symbol_;

    /**
     * @dev Current token id to mint new token.
     */
    uint256 public currentId = 0;

    string public baseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
        baseURI = _uri;
    }

    /**
     * @dev Returns a descriptive name for a collection of tokens.
     * @return _name Representing name.
     */
    function name() external view returns (string memory _name) {
        _name = name_;
    }

    /**
     * @dev Returns an abbreviated name for a collection tokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = symbol_;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function uri(
        uint256 id
    ) public view virtual override(ERC1155, ERC1155URIStorage) returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner returns (uint256, uint256) {
        _mint(account, id, amount, data);
        return (id, amount);
    }

    function mint(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyOwner returns (uint256, uint256) {
        _mint(account, currentId, amount, data);
        return (currentId++, amount);
    }
}
