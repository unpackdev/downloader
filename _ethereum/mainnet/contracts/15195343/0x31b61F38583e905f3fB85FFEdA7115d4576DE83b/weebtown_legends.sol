// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract weebtown_legends is ERC721A, Ownable {
    string public contractMetadataURI;
    string public baseURI;

    constructor(string memory _contractMetadataURI, string memory _newBaseURI) ERC721A("weebtown legends", "WLGND") {
        contractMetadataURI = _contractMetadataURI;
        baseURI = _newBaseURI;
    }

    // PUBLIC READ

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    // OWNER

    function mintBestie(uint256 _amount, address _toAddress) external onlyOwner {
        _safeMint(_toAddress, _amount);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractMetadataURI(string calldata _contractMetadataURI) external onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // INTERNAL

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
