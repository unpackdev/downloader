// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import "./IERC2981.sol";
import "./Strings.sol";
import "./Address.sol";
import "./BaseFacet.sol";
import "./ERC721AUpgradeable.sol";

contract ERC721AFacet is BaseFacet, ERC721AUpgradeable, IERC2981 {
    using Strings for uint256;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_as.isReveal) {
            return string(abi.encodePacked(_as.baseTokenURI, "/", tokenId.toString(), ".json"));
        } else {
            return _as.unrevealURI;
        }
    }

    // Not in used (see @DiamondCutAndLoupeFacet)
    function supportsInterface(bytes4 interfaceId) override(ERC721AUpgradeable, IERC165) public view virtual returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    function initialize() external initializerERC721A onlyOwner {
        __ERC721A_init('Creepy Clown Club', 'CCC');
    }

    // =========== ERC721A ===========

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(address _methodsExposureFacetAddress) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.methodsExposureFacetAddress = _methodsExposureFacetAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = _baseTokenURI;
    }

    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.mintPrice = _mintPrice;
    }

    function setMaxMintsPerWallet(uint32 _maxMintsPerWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxSupply(uint32 _maxSupply) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxSupply = _maxSupply;
    }

    function setReveal(bool _isReveal) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.isReveal = _isReveal;
    }

    function setMintOpen(bool _mintOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.mintOpen = _mintOpen;
    }

    // ==================== Views ====================

    function maxSupply() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxSupply;
    }

    function baseTokenURI() external view returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.baseTokenURI;
    }

    function mintPrice() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.mintPrice;
    }

    function maxMintsPerWallet() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxMintsPerWallet;
    }

    function isReveal() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.isReveal;
    }

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    function mintOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.mintOpen;
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // =========== Mint ===========

    function mint(uint256 quantity) payable external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.mintOpen, "Mint not open");
        require(totalSupply() + quantity <= _as.maxSupply, "No more mints");
        require(msg.value == _as.mintPrice * quantity, "Wrong value sent");
        require(balanceOf(msg.sender) + quantity <= _as.maxMintsPerWallet, "Too many mints");
        _safeMint(msg.sender, quantity);
        Address.sendValue(payable(_as.royaltiesRecipient), address(this).balance);
    }

}
