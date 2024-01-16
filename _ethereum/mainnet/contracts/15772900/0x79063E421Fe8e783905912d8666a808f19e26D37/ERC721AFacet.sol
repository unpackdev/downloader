// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Lively modified from Chiru Labs

pragma solidity ^0.8.9;

import "./Shared.sol";
import "./ERC721A.sol";
import "./Pausable.sol";
import "./Modifiers.sol";
import "./AllowList.sol";
import "./LibDiamond.sol";
import "./ERC721ALib.sol";
import "./CoinSwapper.sol";
import "./PriceConsumer.sol";

import "./console.sol";

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AFacet is ERC721A {
    uint256 constant MAX_UINT256 = type(uint256).max;
    uint64 constant MAX_UINT64 = type(uint64).max;

    // =============================================================
    //                           Mint functions
    // =============================================================
    function mint(address to) external payable whenNotPaused {
        if (s.allowListEnabled) revert AllowListEnabled();
        if (s.editionsEnabled) revert EditionsEnabled();

        _mintApproved(to, 1);
    }

    function mint(address to, uint256 quantity) external payable whenNotPaused {
        if (s.allowListEnabled) revert AllowListEnabled();
        if (s.editionsEnabled) revert EditionsEnabled();

        _mintApproved(to, quantity);
    }

    // Allow list mint
    function mint(
        address to,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        if (s.editionsEnabled) revert EditionsEnabled();
        if (!s.allowListEnabled) revert AllowListDisabled();
        if (!AllowList.checkValidity(merkleProof)) revert InvalidMerkleProof();

        _mintApproved(to, quantity);
    }

    // Minting is allowed, do checks against set limits
    function _mintApproved(address to, uint256 quantity)
        internal
        whenNotPaused
    {
        quantityCheck(to, quantity);
        s.airdrop ? airdropCheck() : priceCheck(quantity);

        emit Shared.PaymentReceived(_msgSender(), msg.value);

        // If conversion is automatically enabled then convert the ETH to USD
        if (s.automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }

        ERC721ALib._mint(to, quantity);
    }

    // =============================================================
    //                    Check functions
    // =============================================================
    function quantityCheck(address to, uint256 quantity) private view {
        unchecked {
            if ((s.currentIndex + quantity) > maxSupply())
                revert ExceedsMaxSupply();

            if (ERC721ALib._numberMinted(to) + quantity > maxMintPerAddress())
                revert ExceedsMaxMintPerAddress();

            if (quantity > maxMintPerTx()) revert ExceedsMaxMintPerTx();
        }
    }

    function airdropCheck() private view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        if (_msgSender() != ds.contractOwner) revert InvalidAirdropCaller();
    }

    function priceCheck(uint256 quantity) private {
        if (msg.value < (quantity * price())) revert InvalidValueSent();
    }

    // =============================================================
    //                        Getters
    // =============================================================
    function airdrop() public view returns (bool) {
        return s.airdrop;
    }

    function maxMintPerTx() public view returns (uint256) {
        return s.maxMintPerTx == 0 ? MAX_UINT256 : s.maxMintPerTx;
    }

    function maxMintPerAddress() public view returns (uint256) {
        return s.maxMintPerAddress == 0 ? MAX_UINT64 : s.maxMintPerAddress;
    }

    function maxSupply() public view returns (uint256) {
        return s.maxSupply == 0 ? MAX_UINT256 : s.maxSupply;
    }

    function price() public view returns (uint256) {
        return s.isPriceUSD ? ERC721ALib.convertUSDtoWei(s.price) : s.price;
    }

    function isSoulbound() external view returns (bool) {
        return s.isSoulbound;
    }

    // =============================================================
    //                        Setters
    // =============================================================
    function setName(string calldata _name) external onlyOwner {
        s.name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        s.symbol = _symbol;
    }

    function setTokenURI(string calldata tokenURI) external onlyOwner {
        s.baseTokenUri = tokenURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        s.price = _price;
    }

    function setAirdrop(bool _airdrop) external onlyOwner {
        s.airdrop = _airdrop;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        s.maxMintPerTx = _maxMintPerTx;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress)
        external
        onlyOwner
    {
        s.maxMintPerAddress = _maxMintPerAddress;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        s.maxSupply = _maxSupply;
    }

    function setIsPriceUSD(bool _isPriceUSD) external onlyOwner {
        s.isPriceUSD = _isPriceUSD;
    }

    function setAutomaticUSDConversion(bool _automaticUSDConversion)
        external
        onlyOwner
    {
        s.automaticUSDConversion = _automaticUSDConversion;
    }

    function setSoulbound(bool _isSoulbound) external onlyOwner {
        s.isSoulbound = _isSoulbound;
    }

    // =============================================================
    //                        Other
    // =============================================================
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId, false);

        // Call Royalty Burn

        /** Type safe and more explicity example */
        // RoyaltyFacet(address(this)).royaltyBurn(tokenId);

        /** @dev Gas efficient example, needs testing. If it doesn't work the simpler above way will. */
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("royaltyBurn(uint256)"));
        // get facet address of function
        address facet = address(bytes20(ds.facets[functionSelector]));

        bytes memory myFunctionCall = abi.encodeWithSelector(
            functionSelector,
            tokenId
        );
        (bool success, ) = address(facet).delegatecall(myFunctionCall);

        require(success, "myFunction failed");
    }
}
