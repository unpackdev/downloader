// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IXNFTFactory.sol";

//
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
//    Created for locksonic.io
//    support@locksonic.io

/// @title XNFT Clone Contract
/// @author Wilson A.
/// @notice Used for creating collection of XNFT
contract XNFTClone is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable
{
    uint256 private accountId;
    IXNFTFactory private xnftFactory;

    modifier onlyFactory() {
        require(msg.sender == address(xnftFactory), "only factory");
        _;
    }

    modifier onlyLiquidityPool() {
        (, address xnftLPAddr) = xnftFactory.accountAddresses(accountId);
        require(msg.sender == xnftLPAddr, "only liquidity pool");
        _;
    }

    modifier onlyMarketplace() {
        require(
            bytes4(msg.data[msg.data.length - 4:]) ==
                xnftFactory.marketplaceHash(),
            "only marketplace"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _accountId
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __ERC2981_init();
        accountId = _accountId;
        xnftFactory = IXNFTFactory(msg.sender);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // -- Whitelist -- //
    /**
     * @dev Overrides the ERC721 `approve` function to include whitelist checks.
     * @param to The address to which approval is granted.
     * @param tokenId The ID of the token.
     * @notice This function checks if the recipient is whitelisted or if the whitelist is paused before granting approval.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(
            xnftFactory.whitelists(to) || xnftFactory.whitelistPaused(),
            "not whitelisted"
        );
        super.approve(to, tokenId);
    }

    /**
     * @dev Overrides the ERC721 `setApprovalForAll` function to include whitelist checks.
     * @param operator The operator to approve or disapprove.
     * @param approved Whether to approve or disapprove the operator.
     * @notice This function checks if the operator is whitelisted or if the whitelist is paused before setting approval.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(
            xnftFactory.whitelists(operator) || xnftFactory.whitelistPaused(),
            "not whitelisted"
        );
        super.setApprovalForAll(operator, approved);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override onlyMarketplace {
        require(
            xnftFactory.whitelists(to) || xnftFactory.whitelistPaused(),
            "not whitelisted"
        );
        super._safeTransfer(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(!xnftFactory.locklists(accountId, tokenId), "token locked");
        (, address xnftLPAddr) = xnftFactory.accountAddresses(accountId);
        if (to == xnftLPAddr)
            require(msg.sender == xnftLPAddr, "only liquidity pool");

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Returns the total supply of tokens, which is the total number of tokens minted.
     * @return The total supply of tokens as a `uint256`.
     */
    function totalSupply() public view virtual returns (uint256) {
        return xnftFactory.mintCount(accountId);
    }

    // -- URI -- //
    /**
     * @dev Overrides the ERC721 `tokenURI` function to retrieve the token URI from the factory contract.
     * @param _tokenId The token ID.
     * @return string The token URI.
     * @notice This function retrieves the token URI from the factory contract based on the account ID and token ID.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireMinted(_tokenId);
        return xnftFactory.tokenURI(accountId, _tokenId);
    }

    /**
     * @dev Retrieves the contract URI from the factory contract.
     * @return string The contract URI.
     * @notice This function retrieves the contract URI from the factory contract based on the account ID.
     */
    function contractURI() public view returns (string memory) {
        return xnftFactory.contractURI(accountId);
    }

    // -- Mint -- //
    function mint(address recepient, uint256 tokenId) external onlyFactory {
        _mint(recepient, tokenId);
    }

    //-- Redemption -- //
    function nftRedemption(
        address user,
        uint256 tokenId
    ) external onlyLiquidityPool {
        _transfer(user, msg.sender, tokenId);
    }

    // -- Royalty -- //
    /**
     * @dev Overrides the `supportsInterface` function to check for ERC2981 and ERC721 support.
     * @param interfaceId The interface ID to check.
     * @return bool True if the contract supports the interface; otherwise, false.
     * @notice This function checks if the contract supports the ERC2981 and ERC721 interfaces.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Retrieves royalty information for a given token and sale price.
     * @param _tokenId The token ID for which royalty information is retrieved.
     * @param _salePrice The sale price of the token.
     * @return address The address to receive royalties.
     * @return uint256 The royalty amount to be paid.
     * @notice This function retrieves royalty information for a specific token and sale price.
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view override returns (address, uint256) {
        _requireMinted(_tokenId);
        return xnftFactory.royaltyInfo(accountId, _salePrice);
    }

    uint256[48] __gap;
}
