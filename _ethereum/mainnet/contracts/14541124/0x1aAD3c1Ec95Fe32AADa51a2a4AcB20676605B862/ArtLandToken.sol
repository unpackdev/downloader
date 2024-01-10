// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

import "./LandMint.sol";
import "./Admin.sol";

/// @custom:security-contact security@dreamspacexr.com
contract DreamSpaceLand is ERC721, LandMint, Pausable, ERC721Burnable, IERC2981, ReentrancyGuard {
    string private _baseTokenURI;
    string private _contractURI;
    uint16 private _royaltyRatio;

    constructor(uint16 _maximumLand) ERC721("DreamSpaceLand", "DSL") LandMint(_maximumLand) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function mintLand(MintData calldata mintData, bytes calldata signature)
        external payable nonReentrant
    {
        uint256[] memory tokens = _mintLand(mintData, signature);
        uint256 tokensLength = tokens.length;
        for (uint i = 0; i < tokensLength; i++) {
            _safeMint(_msgSender(), tokens[i]);
        }
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        to.transfer(amount);
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner{
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setRayaltyRatio(uint16 royaltyRatio) external onlyOwner{
        _royaltyRatio = royaltyRatio;
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (owner(), (_salePrice * _royaltyRatio) / 10000);
    }

    function setContractURI(string calldata newContractURI) external onlyOwner{
        _contractURI = newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
