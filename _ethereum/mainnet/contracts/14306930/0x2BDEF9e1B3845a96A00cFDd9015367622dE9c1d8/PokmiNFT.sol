// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";

interface IERC2981Royalties {
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

interface IERCMultiRoyalties {
    function royaltyInfoAll(uint256 tokenId, uint256 value) external view returns (address[] memory, uint256[] memory);
}

contract PokmiNFT is ERC721, ERC721Enumerable, AccessControlEnumerable, IERC2981Royalties, IERCMultiRoyalties {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NFT_MOVER_ROLE = keccak256("NFT_MOVER_ROLE");

    string private theBaseURI;

    struct Royalty {
        address[] recipients;
        uint256[] percent;
        uint256 totalPercent;
    }

    mapping(uint256 => Royalty) public royaltyOf;

    constructor(string memory _theBaseURI) ERC721("PokmiNFT", "NFT") {

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NFT_MOVER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setBaseURI(_theBaseURI);
    }

    // Public & External functions

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if a whitelisted mover address is detected, auto-return true
        if (hasRole(NFT_MOVER_ROLE, _operator)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external override view returns (address, uint256) {
        Royalty memory royalty = royaltyOf[tokenId];
        return (royalty.recipients[0], (value * royalty.totalPercent) / 10000);
    }

    function royaltyInfoAll(uint256 tokenId, uint256 value) external override view returns (address[] memory, uint256[] memory) {
        Royalty memory royalty = royaltyOf[tokenId];
        uint256[] memory amounts = new uint256[](royalty.recipients.length);
        for (uint256 i = 0; i < royalty.recipients.length; i++) {
            amounts[i] = (value * royalty.percent[i]) / 10000;
        }
        return (royalty.recipients, amounts);
    }

    /**
     * @dev Mints `tokenId` to the primary creator, then transfers it to the buyer.
     * The first creator is treated as the primary creator.
     */
    function mintForSomeoneAndBuy(
        uint256 tokenId,
        address[] calldata creators,
        uint256[] calldata royaltyPercent,
        address buyer
    ) external onlyRole(MINTER_ROLE) {
        _setTokenRoyalty(creators, royaltyPercent, tokenId);
        _safeMint(creators[0], tokenId);
        _safeTransfer(creators[0], buyer, tokenId, "");
    }

    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    function burn(uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _burn(tokenId);
        delete royaltyOf[tokenId];
    }

    // Internal functions

    function _setBaseURI(string memory newBaseURI) internal {
        theBaseURI = newBaseURI;
    }

    function _setTokenRoyalty(
        address[] calldata creators,
        uint256[] calldata royaltyPercent,
        uint256 tokenId
    ) internal {

        require(creators.length > 0, "PokmiNFT: Must have creators");
        require(creators.length == royaltyPercent.length, "PokmiNFT: Length mismatch");
        uint256 totalPercent;
        for (uint256 i = 0; i < royaltyPercent.length; i++) {
            totalPercent += royaltyPercent[i];
        }
        require(totalPercent <= 10000, "ERC2981Royalties: Total royalty too high");
        royaltyOf[tokenId] = Royalty(creators, royaltyPercent, totalPercent);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId
            || interfaceId == type(IERCMultiRoyalties).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return theBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
