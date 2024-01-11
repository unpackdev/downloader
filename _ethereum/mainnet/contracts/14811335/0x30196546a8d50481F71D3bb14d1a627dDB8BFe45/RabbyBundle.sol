// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract RabbyBundle is ERC1155Supply, Ownable {
    uint256 public constant MINI = 0;
    uint256 public constant BOOSTER = 1;
    uint256 public constant PRO = 2;
    uint256 public constant SUPER = 3;

    string internal baseURI = "";

    constructor() ERC1155("") {}

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
        baseURI = newURI;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to    Receiver address
     * @param _id    Amount of tokens to mint
     * @param _quantity    Amount of tokens to mint
     */
    function mintFor(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) public onlyOwner {
        require(_id < 4);
        _mint(_to, _id, _quantity, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155#uri: NONEXISTENT_TOKEN");
        require(bytes(baseURI).length > 0, "ERC1155#uri: BLANK_URI");
        return string(abi.encodePacked(baseURI, Strings.toString(_id)));
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
}
