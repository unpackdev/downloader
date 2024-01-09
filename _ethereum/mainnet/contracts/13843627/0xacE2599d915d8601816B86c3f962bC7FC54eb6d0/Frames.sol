// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/**
 * @title Frames contract
 */
contract Frames is ERC721Enumerable, ERC721URIStorage, Ownable {
    bool public metadataFrozen;

    mapping(uint256 => bool) claimedFrames;

    string public baseUri;
    address public ommContractAddress;

    event SetBaseUri(string indexed baseUri);
    event MintFrame(uint256 frameId);

    modifier whenMetadataIsNotFrozen() {
        require(!metadataFrozen, "Frames: Metadata already frozen.");
        _;
    }

    modifier onlyOMMContract() {
        require(msg.sender == ommContractAddress, "Frames: Only the OMM Contract is allowed to call this function.");
        _;
    }

    constructor(address _ommContractAddress) ERC721("Frame", "FRM") {
        metadataFrozen = false;
        ommContractAddress = _ommContractAddress;
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ------------------
    // Public functions
    // ------------------

    /**
     * Receive two frames when burning one OMM
     */
    function mintFrames(address owner) external onlyOMMContract {
        _mintFrame(owner);
        _mintFrame(owner);
    }

    function claimFreeFrame(uint256 ommTokenId) external {
        require(!claimedFrames[ommTokenId], "Frames: The free frame has already been claimed for the OMM.");
        require(IERC721(ommContractAddress).ownerOf(ommTokenId) == msg.sender, "Frames: The sender does not own the OMM.");

        _mintFrame(msg.sender);
        claimedFrames[ommTokenId] = true;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    // ------------------
    // Internal functions
    // ------------------

    function _mintFrame(address owner) internal {
        uint256 mintIndex = totalSupply() + 1;
        _safeMint(owner, mintIndex);
        emit MintFrame(mintIndex);
    }

    // ------------------
    // Owner functions
    // ------------------

    function setOmmContractAddress(address _ommContractAddress) external onlyOwner {
        ommContractAddress = _ommContractAddress;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataIsNotFrozen {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner whenMetadataIsNotFrozen {
        super._setTokenURI(tokenId, tokenURI);
    }

    function freezeMetadata() external onlyOwner whenMetadataIsNotFrozen {
        metadataFrozen = true;
    }
}
