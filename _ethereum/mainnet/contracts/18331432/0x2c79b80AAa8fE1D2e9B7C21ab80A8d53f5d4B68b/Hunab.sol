// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";

import "./ERC721A.sol";

import "./HunabEventsAndErrors.sol";
import "./HunabMintConfig.sol";
import "./HunabPricingModel.sol";
import "./IHunabRevolution.sol";
import "./OnceLocker.sol";

/**
 * @title Hunab contract implementation.
 *
 * The price formulas are as follows:
 *
 * Mint Price = (Current Supply+1)^alpha / beta + gamma
 * Burn Price = Current Supply^alpha / beta + gamma
 *
 * where alpha = 1.625, beta = 18000, gamma = 0.
 *
 * Hunab whitepaper: https://hunab.gitbook.io/whitepaper.
 */
contract Hunab is
    Ownable,
    ERC721A,
    HunabPricingModel,
    HunabMintConfig,
    HunabEventsAndErrors,
    OnceLocker
{
    uint256 public constant ROYALTY_RATE = 500; // 5/100 royalty rate

    address public constant TREASURY_ADDRESS = 0x846c3CCD7c0C9531769b1B5b7bCE88ba9b3d81e2; // treasury address
    uint256 public constant TREASURY_RESERVED = 15; // reserved amount for the community treasury

    address public royaltyRecipient; // royalty recipient

    IHunabRevolution public hunabRevolution; // Hunab Revolution contract for redemption

    bool private _redemptionEnabled; // indicate if redemption is enabled
    uint256 public redemptionIndex; // current redemption index

    string private _tokenURI;

    /**
     * @notice Constructor.
     * @param tokenURI_ The token URI
     * @param royaltyRecipient_ The royalty recipient
     * @param authConfig_ The config for auth mint
     * @param publicConfig_ The config for public mint
     */
    constructor(
        string memory tokenURI_,
        address royaltyRecipient_,
        AuthMintConfig memory authConfig_,
        PublicMintConfig memory publicConfig_
    ) ERC721A("Hunab", "HUNAB") {
        _tokenURI = tokenURI_;
        royaltyRecipient = royaltyRecipient_;

        authConfig = authConfig_;
        publicConfig = publicConfig_;
    }

    /**
     * @notice Reserve for the community treasury. The method can only be called once.
     */
    function reserve() external payable onlyOwner once(this.reserve.selector) {
        _batchMint(TREASURY_ADDRESS, TREASURY_RESERVED);
    }

    /**
     * @notice Authorized mint for allowlist.
     * @param proof The merkle proof
     */
    function mint(bytes32[] calldata proof) external payable {
        if (!isAuthMintEnabled()) revert AuthMintNotEnabled();
        if (!isAuthorized(_msgSender(), proof)) revert NotAuthorized();

        if (authMinted[_msgSender()] + 1 > MAX_AUTH_MINT_PER_WALLET)
            revert MaxAuthMintPerWalletExceeded();
        if (totalAuthMinted + 1 > MAX_AUTH_MINT) revert MaxAuthMintExceeded();

        authMinted[_msgSender()]++;
        totalAuthMinted++;

        _mint(_msgSender());
    }

    /**
     * @notice Public mint.
     */
    function mint() external payable {
        if (!isPublicMintEnabled()) revert PublicMintNotEnabled();

        _mint(_msgSender());
    }

    /**
     * @notice Burn token.
     * @param tokenId The id of the token to be burned
     */
    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();

        uint256 price = getBurnPrice(totalSupply());

        _burn(tokenId);

        _burnFundHandler(price);
    }

    /**
     * @notice Redeem the given Hunab token for the new Hunab Revolution token. The original token will be locked forever.
     * And `extractableFund` will be transferred to the Hunab Revolution contract.
     * @param tokenId The id of the Hunab token to be redeemed
     */
    function redeem(uint256 tokenId) external {
        if (!isRedemptionEnabled()) revert RedemptionNotEnabled();

        transferFrom(_msgSender(), address(this), tokenId);
        uint256 newTokenId = hunabRevolution.hunabMint(_msgSender(), tokenId);

        uint256 extractableFund = getExtractableFund(++redemptionIndex);
        Address.sendValue(payable(address(hunabRevolution)), extractableFund);

        emit Redeemed(tokenId, newTokenId, extractableFund);
    }

    /**
     * @notice Set config for auth mint.
     * @param startTime The start time
     * @param endTime The end time
     * @param verificationRoot The merkle root
     */
    function setAuthConfig(
        uint64 startTime,
        uint64 endTime,
        bytes32 verificationRoot
    ) external onlyOwner {
        if (startTime != 0) {
            authConfig.startTime = startTime;
        }

        if (endTime != 0) {
            if (endTime <= authConfig.startTime) revert InvalidParams();
            authConfig.endTime = endTime;
        }

        if (verificationRoot != 0x0) {
            authConfig.verificationRoot = verificationRoot;
        }
    }

    /**
     * @notice Set config for public mint.
     * @param startTime The start time
     */
    function setPublicConfig(uint64 startTime) external onlyOwner {
        publicConfig.startTime = startTime;
    }

    /**
     * @notice Set royalty recipient.
     * @param newRoyaltyRecipient The new royalty recipient
     */
    function setRoyaltyRecipient(
        address newRoyaltyRecipient
    ) external onlyOwner {
        royaltyRecipient = newRoyaltyRecipient;
    }

    /**
     * @notice Set the Hunab Revolution contract.
     * @param hunabRevolution_ The Hunab Revolution contract
     */
    function setHunabRevolution(
        IHunabRevolution hunabRevolution_
    ) external onlyOwner {
        hunabRevolution = hunabRevolution_;
    }

    /**
     * @notice Set the redemption status.
     * @param redemptionEnabled The redemption status
     */
    function setRedemptionStatus(bool redemptionEnabled) external onlyOwner {
        _redemptionEnabled = redemptionEnabled;
    }

    /**
     * @notice Set the token URI.
     * @param newTokenURI The new token URI
     */
    function setTokenURI(string memory newTokenURI) external onlyOwner {
        _tokenURI = newTokenURI;
    }

    function _mint(address to) internal {
        uint256 price = getMintPrice(totalSupply());
        _mintFundHandler(price);

        _safeMint(to, 1);
    }

    function _batchMint(address to, uint256 quantity) internal {
        uint256 currentSupply = totalSupply();
        uint256 totalPrice;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 price = getMintPrice(currentSupply + i);
            totalPrice += price;
        }

        _mintFundHandler(totalPrice);

        _safeMint(to, quantity);
    }

    function _mintFundHandler(uint256 price) internal {
        uint256 royalty = _getRoyalty(price);
        uint256 priceWithFee = price + royalty;

        if (msg.value < priceWithFee) revert InsufficientValue();

        _payRoyalty(royalty);

        if (msg.value > priceWithFee) {
            payable(_msgSender()).transfer(msg.value - priceWithFee);
        }
    }

    function _burnFundHandler(uint256 price) internal {
        uint256 royalty = _getRoyalty(price);
        _payRoyalty(royalty);

        payable(_msgSender()).transfer(price - royalty);
    }

    function _payRoyalty(uint256 royalty) internal {
        payable(royaltyRecipient).transfer(royalty);
    }

    function _getRoyalty(
        uint256 price
    ) internal pure returns (uint256 royalty) {
        return (price * ROYALTY_RATE) / 10000;
    }

    /**
     * @notice Check if the auth mint is enabled.
     * @return bool True if the auth mint is enabled, false otherwise
     */
    function isAuthMintEnabled() public view returns (bool) {
        return
            authConfig.startTime != 0 &&
            block.timestamp >= authConfig.startTime &&
            authConfig.endTime != 0 &&
            block.timestamp < authConfig.endTime &&
            authConfig.verificationRoot != 0x0;
    }

    /**
     * @notice Check if the public mint is enabled.
     * @return bool True if the public mint is enabled, false otherwise
     */
    function isPublicMintEnabled() public view returns (bool) {
        return
            publicConfig.startTime != 0 &&
            block.timestamp >= publicConfig.startTime;
    }

    /**
     * @notice Check if redemption is enabled.
     * @return bool True if redemption is enabled, false otherwise
     */
    function isRedemptionEnabled() public view returns (bool) {
        return _redemptionEnabled;
    }

    /**
     * @notice Verify whether the given account is authorized.
     * @param account The destination address to be verified
     * @param proof The merkle proof
     * @return authorized True if the given address is authorized, false otherwise
     */
    function isAuthorized(
        address account,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                authConfig.verificationRoot,
                keccak256(abi.encodePacked(account))
            );
    }

    /**
     * @notice Get the mint price plus royalty by the given total supply.
     * @param totalSupply The total supply
     * @return price The final mint price
     */
    function getMintPriceAfterFee(
        uint256 totalSupply
    ) public pure returns (uint256) {
        uint256 price = getMintPrice(totalSupply);
        uint256 royalty = _getRoyalty(price);

        return price + royalty;
    }

    /**
     * @notice Get the burn price minus royalty by the given total supply.
     * @param totalSupply The total supply
     * @return price The final burn price
     */
    function getBurnPriceAfterFee(
        uint256 totalSupply
    ) public pure returns (uint256) {
        uint256 price = getBurnPrice(totalSupply);
        uint256 royalty = _getRoyalty(price);

        return price - royalty;
    }

    /**
     * @notice Get the current mint price plus royalty.
     * @return price The current mint price
     */
    function getCurrentMintPriceAfterFee() public view returns (uint256) {
        return getMintPriceAfterFee(totalSupply());
    }

    /**
     * @notice Get the current burn price minus royalty.
     * @return price The current burn price
     */
    function getCurrentBurnPriceAfterFee() public view returns (uint256) {
        return getBurnPriceAfterFee(totalSupply());
    }

    /**
     * @notice Get the batch mint price plus royalty by the given total supply and quantity.
     * @param totalSupply The total supply
     * @param quantity The quantity of tokens to be minted
     * @return The total mint price
     */
    function getBatchMintPriceAfterFee(
        uint256 totalSupply,
        uint256 quantity
    ) public pure returns (uint256) {
        uint256 totalPrice;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 price = getMintPrice(totalSupply + i);
            totalPrice += price;
        }

        uint256 royalty = _getRoyalty(totalPrice);

        return totalPrice + royalty;
    }

    /**
     * @notice Get the batch burn price minus royalty by the given total supply and quantity.
     * @param totalSupply The total supply
     * @param quantity The quantity of tokens to be burned
     * @return The total burn price
     */
    function getBatchBurnPriceAfterFee(
        uint256 totalSupply,
        uint256 quantity
    ) public pure returns (uint256) {
        uint256 totalPrice;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 price = getBurnPrice(totalSupply - i);
            totalPrice += price;
        }

        uint256 royalty = _getRoyalty(totalPrice);

        return totalPrice - royalty;
    }

    /**
     * @notice Get the total number of minted tokens.
     * @return totalNumber The total number of minted tokens
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @notice Get the total number of burned tokens.
     * @return totalNumber The total number of burned tokens
     */
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    /**
     * @notice Override `ERC721A.tokenURI`.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        return _tokenURI;
    }

    /**
     * @notice Override `ERC721A._startTokenId`.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @notice Query all tokens of the given owner.
     * @param owner The destination owner
     * @return tokenIds The ids of tokens of the given owner
     */
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);

        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);

            if (ownership.burned) {
                continue;
            }

            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }

        return tokenIds;
    }
}
