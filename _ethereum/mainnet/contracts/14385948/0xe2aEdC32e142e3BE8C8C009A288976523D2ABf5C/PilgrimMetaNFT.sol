// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IPilgrimMetaNFT.sol";
import "./IViewFacet.sol";

/**
 * PilgrimMetaNFT ERC-721 contract based on OpenZeppelin implementation
 */
contract PilgrimMetaNFT is ERC721, Ownable, IPilgrimMetaNFT {
    using Counters for Counters.Counter;

    address public core;

    Counters.Counter private tokenIdCounter;

    constructor() ERC721("PilgrimMetaNFT", "PILMETA") {}

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        (address nftAddress, uint256 tokenId, , ) = IViewFacet(core).getPairInfo(_tokenId);
        return IERC721Metadata(nftAddress).tokenURI(tokenId);
    }

    /// @notice Set the Pilgrim core address. This function must be called right after deployment.
    ///
    /// @param _core Pilgrim core contract address
    ///
    function setCore(address _core) external override onlyOwner {
        core = _core;
    }

    modifier onlyCore() {
        require(core == _msgSender(), "PilgrimMetaNFT: caller is not core");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "PilgrimMetaNFT: caller is not token owner");
        _;
    }

    function safeMint(address _to) external override onlyCore returns (uint256 _tokenId) {
        _tokenId = tokenIdCounter.current();
        _safeMint(_to, _tokenId);
        tokenIdCounter.increment();
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "PilgrimMetaNFT: transfer caller is not owner nor approved"
        );
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function burn(uint256 _tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "PilgrimMetaNFT: unauthorized burning attempt");
        _burn(_tokenId);
    }
}
