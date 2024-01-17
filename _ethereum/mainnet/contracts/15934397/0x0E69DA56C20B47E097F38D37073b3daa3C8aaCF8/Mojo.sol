// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721PsiAddressData.sol";
import "./Ownable.sol";

contract Mojo is ERC721PsiAddressData, Ownable {
    string public baseURI;

    constructor(string memory name_, string memory symbol_)
        ERC721Psi(name_, symbol_)
    {}

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 quantity) external payable onlyOwner {
        _mint(msg.sender, quantity);
    }

    function mintTo(uint256 quantity, address receiver)
        external
        payable
        onlyOwner
    {
        _mint(receiver, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
