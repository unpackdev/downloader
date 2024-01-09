// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./ERC1155Supply.sol";

contract PudgyApesSpecials is ERC1155Supply, Pausable, Ownable {
    uint256 constant MAX_SUPPLY = 900;

    string public _baseTokenURI;
    address public pudgyApesAddress;

    string public symbol = "PHG";
    string public name = "Pudgy Holder Gift";

    constructor(string memory _uri, address _pudgyApesAddress) ERC1155(_uri) {
        _pause();

        _baseTokenURI = _uri;
        pudgyApesAddress = _pudgyApesAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function claim() external whenNotPaused {
        require(totalSupply(0) < MAX_SUPPLY, "PudgyApesSpecials: Max supply reached");
        require(balanceOf(msg.sender, 0) == 0, "PudgyApesSpecials: You have already claimed the gift!");
        require(IERC721(pudgyApesAddress).balanceOf(msg.sender) > 0, "PudgyApesSpecials: You don't own the PudgyApe!");

        _mint(msg.sender, 0, 1, "");
    }

    function setPudgyApesAddress(address _pudgyApesAddress) external onlyOwner {
        require(_pudgyApesAddress != address(0), "PudgyApesSpecials: PudgyApes address cannot be 0!");
        pudgyApesAddress = _pudgyApesAddress;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "URI: nonexistent token");
        return string(abi.encodePacked(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)), ".json"));
    }
}
