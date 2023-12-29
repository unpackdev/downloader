// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";

contract HyakkiToken1155 is ERC1155, Ownable {

    bool public metadataLocked = false;
    address public mintvial;
    string public name;
    string public symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri,
        address mintvial_
    ) ERC1155(uri) {
        name = name_;
        symbol = symbol_;
        mintvial = mintvial_;
    }

    function mint(address to, uint256 id, uint256 amount) public {
        require(msg.sender == mintvial, "Not authorized to mint");
        _mint(to, id, amount, "");
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || owner() == _msgSender(),
            "ERC1155: caller is not token owner or approved"
        );
        _burn(account, id, value);
    }

    function setMintvial(address mintvial_) public onlyOwner {
        mintvial = mintvial_;
    }

    function setURI(string memory newuri) public onlyOwner {
        require(!metadataLocked, "Metadata locked");
        _setURI(newuri);
    }

    function lockMetadata() public onlyOwner {
        metadataLocked = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
