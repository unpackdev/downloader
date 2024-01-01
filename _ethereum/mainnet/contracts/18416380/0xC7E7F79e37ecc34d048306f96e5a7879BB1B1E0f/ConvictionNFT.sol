// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./OperatorFilterer.sol";

error NotScrolls();
error TokenDoesNotExist();

contract ConvictionNFT is
    UUPSUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ERC721Upgradeable
{
    using Strings for uint256;

    // Address of the scrolls contract that will mint from this contract
    address public scrolls;

    // Whether operator filtering is enabled
    bool public operatorFilteringEnabled;

    // Base metadata uri
    string public baseTokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        string memory name,
        string memory symbol,
        address _scrolls,
        address _royaltyReceiver
    ) public initializer {
        // Upgradeable initializations
        __ERC721_init(name, symbol);
        __UUPSUpgradeable_init();
        __Ownable_init();

        // Set scrolls contract
        scrolls = _scrolls;

        // Setup operator filtering
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty to 5%
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    /**
     * Mint function that can only be initiated from the scrolls contract
     * @param to Address to mint the NFT to
     * @param tokenId The token id to mint (matches up to the Scroll 1:1)
     */
    function mint(address to, uint256 tokenId) external {
        if (msg.sender != scrolls) {
            revert NotScrolls();
        }
        _mint(to, tokenId);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    /**
     * Overridden setApprovalForAll with operator filtering.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * Overridden approve with operator filtering.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * Overridden transferFrom with operator filtering.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Overridden safeTransferFrom with operator filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * Overridden safeTransferFrom with operator filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Owner-only function to toggle operator filtering.
     * @param value Whether operator filtering is on/off.
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    /**
     * Owner-only function to set the royalty receiver and royalty rate
     * @param receiver Address that will receive royalties
     * @param feeNumerator Royalty amount in basis points. Denominated by 10000
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
