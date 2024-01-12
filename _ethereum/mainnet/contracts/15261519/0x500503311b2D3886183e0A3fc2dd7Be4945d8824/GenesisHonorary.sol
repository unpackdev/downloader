// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Strings.sol";

contract GenesisHonorary is Ownable, ERC721A, ERC2981 {
    using Strings for uint256;

    string private metadataUri;

    constructor(
        string memory _metadataUri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721A("GenesisHonorary", "GENESIS_HONORARY") {
        metadataUri = _metadataUri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataUri, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataUri, "contractURI"));
    }

    function mint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
