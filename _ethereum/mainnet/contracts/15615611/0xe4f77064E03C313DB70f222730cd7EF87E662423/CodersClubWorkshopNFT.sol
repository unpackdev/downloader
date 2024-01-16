// SPDX-License-Identifier: MIT

// Contract by @Montana_Wong

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./ERC2981.sol";

import "./ERC721A.sol";

contract CodersClubWorkshopNFT is ERC721A, Ownable, ERC2981 {

    string public metadataUri;
    bool public isMintingEnabled = true;
    // For splitting royalties
    PaymentSplitter public splitter;

    constructor(string memory _name,
        string memory _symbol,
        string memory _metadataUri,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A(_name, _symbol) {
        metadataUri = _metadataUri;
        splitter = new PaymentSplitter(_payees, _shares);
        _setDefaultRoyalty(address(splitter), 500);
    }

    function mint() external payable {
        // Check if Minting has been enabled
        require(isMintingEnabled, "mint Minting is not enabled");

        _mint(msg.sender, 1);
    }

    function toggleMinting() external onlyOwner {
        isMintingEnabled = !isMintingEnabled;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(metadataUri).length != 0 ? metadataUri : '';
    }

    function release() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address(splitter)), balance);
    }

    function setDefaultRoyalty(address receiver, uint96 numerator) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
