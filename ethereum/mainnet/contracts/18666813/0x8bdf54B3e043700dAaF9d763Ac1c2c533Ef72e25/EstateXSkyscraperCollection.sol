// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title EstateX Skyscraper Collection
/// @author EstateX B.V.

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";

contract EstateXSkyscraperCollection is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    struct Building {
        uint32 firstTokenId; // The first token in this building
        uint32 totalTokenAmount; // The amount of tokens in this building
        uint32 claimTokenAmount; // The amount of tokens allocated for claim, starts at "firstTokenId".
        uint32 publicMinted; // The amount of public tokens that have been minted.
        uint32 claimMinted; // The amount of claimable tokens that have been minted.
        uint48 tokenPrice;
        uint48 points;
    }

    mapping(uint256 => Building) public buildings;
    uint256 public nextBuildingId = 0;

    // Map token ids to building ids for faster lookup.
    mapping(uint256 => uint256) public tokenIdToBuildingId;

    mapping(address => bool) public approvedTokens;

    bool public isRevealed = false;

    address private claimMintVerificationAddress;
    address private publicMintVerificationAddress;

    struct SignedClaimMint {
        uint256 buildingId;
        uint256 tokenId;
        address sender;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SignedPublicMint {
        uint256 nonce;
        address sender;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(uint256 => bool) nonceUsed;

    enum ContractState {
        OFF,
        CLAIM,
        PUBLIC
    }
    ContractState public contractState = ContractState.OFF;

    AggregatorV3Interface public priceFeed;

    string public baseURI;
    string public preRevealBaseURI;

    constructor() ERC721("EstateX Skyscraper Collection", "ESXSC") Ownable() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        approvedTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        approvedTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
    }

    //
    // Modifiers
    //

    /**
     * Ensure current state is correct for this method.
     */
    modifier isNotContractState(ContractState contractState_) {
        require(contractState != contractState_, "invalid contract state");
        _;
    }

    /**
     * Ensure current state is correct for this method.
     */
    modifier isContractState(ContractState contractState_) {
        require(contractState == contractState_, "invalid contract state");
        _;
    }

    /**
     * Ensure correct amount of Ether present in transaction.
     */
    modifier correctValue(uint256 expectedValue) {
        require(expectedValue <= msg.value, "ether value sent is not correct");
        _;
    }

    //
    // Price Feed
    //

    function getTokentoUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getPriceEth(uint256 buildingId) public view returns (uint256) {
        int256 price = getTokentoUSD();
        return (uint256(buildings[buildingId].tokenPrice) * 10 ** 18) / uint256(price);
    }

    //
    // Mint
    //

    /**
     * Verifies given signature for claim mint.
     *
     * @param signedMint The signed claim mint struct to verify.
     */
    modifier verifyClaimMintSignature(SignedClaimMint calldata signedMint) {
        require(!_exists(signedMint.tokenId), "token already minted");
        require(signedMint.sender == msg.sender, "invalid signature");

        bytes32 msgHash = keccak256(abi.encode(signedMint.buildingId, signedMint.tokenId, signedMint.sender));
        address signer = ECDSA.recover(msgHash, signedMint.v, signedMint.r, signedMint.s);

        // Check if the coupon has been signed by the correct private key.
        require(signer == claimMintVerificationAddress, "invalid signature");

        _;
    }

    /**
     * Verifies given signature for public mint.
     *
     * @param signedMint The signed public mint struct to verify.
     */
    modifier verifyPublicMintSignature(SignedPublicMint calldata signedMint) {
        require(signedMint.sender == msg.sender, "invalid signature");
        require(nonceUsed[signedMint.nonce] == false, "signature already used");

        bytes32 msgHash = keccak256(abi.encode(signedMint.nonce, signedMint.sender));
        address signer = ECDSA.recover(msgHash, signedMint.v, signedMint.r, signedMint.s);

        // Check if the coupon has been signed by the correct private key.
        require(signer == publicMintVerificationAddress, "invalid signature");

        // Set nonce to used
        nonceUsed[signedMint.nonce] = true;

        _;
    }

    /**
     * Validates the given building id and returns the corresponding building struct.
     *
     * @param buildingId The building id to verify and use.
     */
    function _validateAndGetBuilding(uint256 buildingId) internal view returns (Building storage) {
        require(buildingId < nextBuildingId, "invalid building id");
        return buildings[buildingId];
    }

    /**
     * Mints the given token id.
     *
     * @param receiver The address that should receive the token.
     * @param buildingId The building id this token is part of.
     * @param tokenId The token id to mint.
     */
    function _mintTokenId(address receiver, uint256 buildingId, uint256 tokenId) internal {
        require(buildingId < nextBuildingId, "invalid building id");
        Building storage building = buildings[buildingId];
        require(
            tokenId >= building.firstTokenId && tokenId < building.firstTokenId + building.totalTokenAmount,
            "invalid token id"
        );

        tokenIdToBuildingId[tokenId] = buildingId;
        _safeMint(receiver, tokenId);
    }

    /**
     * Mints the given token id as a claim mint.
     *
     * @param receiver The address that should receive the token.
     * @param buildingId The building id this token is part of.
     * @param tokenId The token id to mint.
     * @param building The building this token is part of.
     */
    function _mintClaim(address receiver, uint256 buildingId, uint256 tokenId, Building storage building) internal {
        building.claimMinted += 1;
        _mintTokenId(receiver, buildingId, tokenId);
    }

    /**
     * Mints the given amount of tokens as a public mint.
     *
     * @param receiver The address that should receive the token.
     * @param buildingId The building id this token is part of.
     * @param quantity The amount of tokens to mint.
     * @param building The building this token is part of.
     */
    function _mintPublic(address receiver, uint256 buildingId, uint32 quantity, Building storage building) internal {
        require(quantity > 0, "invalid quantity");
        require(building.publicMinted + quantity <= building.totalTokenAmount - building.claimTokenAmount, "sold out");

        uint256 oldPublicMinted = building.publicMinted;
        building.publicMinted += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = building.firstTokenId + building.claimTokenAmount + oldPublicMinted + i;
            _mintTokenId(receiver, buildingId, tokenId);
        }
    }

    /**
     * Transfers the given amount of third-party tokens to this contract.
     * This can be used as an alternative to ETH.
     *
     * @param tokenAddress The address of the third-party token to use.
     * @param building The building of which the price for our token should be used from.
     * @param quantity The amount of our tokens which should be used for the price calculation.
     */
    function _transferTokensForMint(address tokenAddress, Building storage building, uint256 quantity) internal {
        require(approvedTokens[tokenAddress], "token not approved");

        uint256 transferAmount = (building.tokenPrice * quantity * (10 ** IERC20Metadata(tokenAddress).decimals())) /
            (10 ** 8);
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), transferAmount);
    }

    /**
     * Executes a claim mint payed with ethereum.
     *
     * @param signedMint The signed claim mint struct to verify.
     */
    function mintClaim(
        SignedClaimMint calldata signedMint
    ) external nonReentrant isNotContractState(ContractState.OFF) verifyClaimMintSignature(signedMint) {
        Building storage building = _validateAndGetBuilding(signedMint.buildingId);
        _mintClaim(msg.sender, signedMint.buildingId, signedMint.tokenId, building);
    }

    /**
     * Executes a public mint payed with ethereum.
     *
     * @param signedMint The signed public mint struct to verify.
     * @param buildingId The id of the building the tokens should be minted from.
     * @param quantity The amount of tokens to mint.
     */
    function mintEthPublic(
        SignedPublicMint calldata signedMint,
        uint256 buildingId,
        uint32 quantity
    )
        external
        payable
        nonReentrant
        isContractState(ContractState.PUBLIC)
        verifyPublicMintSignature(signedMint)
        correctValue(getPriceEth(buildingId) * quantity)
    {
        Building storage building = _validateAndGetBuilding(buildingId);
        _mintPublic(msg.sender, buildingId, quantity, building);
    }

    /**
     * Executes a public mint payed with a third-party token.
     *
     * @param buildingId The id of the building the tokens should be minted from.
     * @param quantity The amount of tokens to mint.
     * @param tokenAddress The address of the third-party token to use.
     */
    function mintTokenPublic(
        SignedPublicMint calldata signedMint,
        uint256 buildingId,
        uint32 quantity,
        address tokenAddress
    ) external nonReentrant isContractState(ContractState.PUBLIC) verifyPublicMintSignature(signedMint) {
        Building storage building = _validateAndGetBuilding(buildingId);

        _transferTokensForMint(tokenAddress, building, quantity);
        _mintPublic(msg.sender, buildingId, quantity, building);
    }

    /**
     * Executes a reserved mint for a claim token.
     *
     * @param receiver The address that should receive the token.
     * @param buildingId The id of the building this token should be minted from.
     * @param tokenId The token id to mint.
     */
    function mintReservedClaim(address receiver, uint256 buildingId, uint256 tokenId) external nonReentrant onlyOwner {
        Building storage building = _validateAndGetBuilding(buildingId);
        _mintClaim(receiver, buildingId, tokenId, building);
    }

    /**
     * Executes a reserved mint for public tokens.
     *
     * @param receiver The address that should receive the tokens.
     * @param buildingId The id of the building the tokens should be minted from.
     * @param quantity The amount of tokens to mint.
     */
    function mintReservedPublic(address receiver, uint256 buildingId, uint32 quantity) external nonReentrant onlyOwner {
        Building storage building = _validateAndGetBuilding(buildingId);
        _mintPublic(receiver, buildingId, quantity, building);
    }

    /**
     * @notice Burns `tokenId`. The caller must own `tokenId` or be an
     *         approved operator.
     */
    // solhint-disable-next-line comprehensive-interface
    function burn(uint256[] memory ids) external {
        for (uint i; i < ids.length; i++) {
            require(_isApprovedOrOwner(msg.sender, ids[i]), "ERC721: caller is not token owner or approved");
            _burn(ids[i]);
        }
    }

    //
    // Admin
    //

    /**
     * Adds a new building to the collection.
     * The building id will be assigned automatically.
     *
     * @param totalTokenAmount The total amount of tokens in this building.
     * @param claimTokenAmount The amount of tokens allocated for claim.
     * @param tokenPrice The price of a single token in USD with 8 decimals.
     * @param points The amount of points this building is worth.
     */
    function addBuilding(
        uint32 totalTokenAmount,
        uint32 claimTokenAmount,
        uint48 tokenPrice,
        uint48 points
    ) external onlyOwner {
        _addBuilding(totalTokenAmount, claimTokenAmount, tokenPrice, points);
    }

    /**
     * Adds many new buildings to the collection.
     * The building id will be assigned automatically.
     *
     * All args have to be arrays of the same length. The first building
     * will be created with data from the first index of each array, and so on.
     *
     * @param totalTokenAmount The total amount of tokens in each building.
     * @param claimTokenAmount The amount of tokens allocated for claim.
     * @param tokenPrice The price of a single token in USD with 8 decimals.
     * @param points The amount of points each building is worth.
     */
    function addManyBuildings(
        uint32[] calldata totalTokenAmount,
        uint32[] calldata claimTokenAmount,
        uint48[] calldata tokenPrice,
        uint48[] calldata points
    ) external onlyOwner {
        require(totalTokenAmount.length == claimTokenAmount.length, "invalid length");
        require(totalTokenAmount.length == tokenPrice.length, "invalid length");
        require(totalTokenAmount.length == points.length, "invalid length");

        for (uint256 i = 0; i < totalTokenAmount.length; i++) {
            _addBuilding(totalTokenAmount[i], claimTokenAmount[i], tokenPrice[i], points[i]);
        }
    }

    /**
     * Adds a new building to the collection.
     * The building id will be assigned automatically.
     *
     * @param totalTokenAmount The total amount of tokens in this building.
     * @param claimTokenAmount The amount of tokens allocated for claim.
     * @param tokenPrice The price of a single token in USD.
     * @param points The amount of points this building is worth.
     */
    function _addBuilding(uint32 totalTokenAmount, uint32 claimTokenAmount, uint48 tokenPrice, uint48 points) internal {
        uint32 firstTokenId = 1;
        if (nextBuildingId > 0) {
            Building storage previousBuilding = buildings[nextBuildingId - 1];
            firstTokenId = previousBuilding.firstTokenId + previousBuilding.totalTokenAmount;
        }

        buildings[nextBuildingId] = Building(
            firstTokenId,
            totalTokenAmount,
            claimTokenAmount,
            0,
            0,
            tokenPrice,
            points
        );

        nextBuildingId++;
    }

    /**
     * Updates the token price for a building.
     *
     * @param newTokenPrice The new token price.
     * @param buildingId The new token price.
     */
    function setTokenPrice(uint256 buildingId, uint48 newTokenPrice) external onlyOwner {
        require(buildingId < nextBuildingId, "invalid building id");

        buildings[buildingId].tokenPrice = newTokenPrice;
    }

    /**
     * Updates the amount of tokens allocated for claim for given building.
     *
     * @param buildingId The id of the building to update.
     * @param newClaimTokenAmount The new amount of tokens allocated for claim.
     */
    function setClaimTokenAmount(uint256 buildingId, uint32 newClaimTokenAmount) external onlyOwner {
        require(buildingId < nextBuildingId, "invalid building id");
        Building storage building = buildings[buildingId];

        require(newClaimTokenAmount <= building.totalTokenAmount - building.publicMinted, "invalid claim amount");
        require(newClaimTokenAmount >= building.claimMinted, "invalid claim amount");

        building.claimTokenAmount = newClaimTokenAmount;
    }

    /**
     * Sets the contract state.
     *
     * @param contractState_ The new state of the contract.
     */
    function setContractState(uint256 contractState_) external onlyOwner {
        require(contractState_ < 3, "invalid contract state");

        if (contractState_ == 0) {
            contractState = ContractState.OFF;
        } else if (contractState_ == 1) {
            contractState = ContractState.CLAIM;
        } else {
            contractState = ContractState.PUBLIC;
        }
    }

    /**
     * Sets the price feed address.
     *
     * @param newFeed The new price feed address.
     */
    function setPriceFeed(address newFeed) external onlyOwner {
        require(newFeed != address(0), "invalid address");
        priceFeed = AggregatorV3Interface(newFeed);
    }

    /**
     * Sets given token to be approved.
     *
     * @param token The token address.
     */
    function setApprovedToken(address token, bool approved) external onlyOwner {
        require(token != address(0), "invalid address");
        approvedTokens[token] = approved;
    }

    /**
     * Set the ECDSA verification address for the claim mint.
     *
     * @param addr The verification address to use
     */
    function setClaimVerificationAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid address");
        claimMintVerificationAddress = addr;
    }

    /**
     * Set the ECDSA verification address for the public mint.
     *
     * @param addr The verification address to use
     */
    function setPublicVerificationAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid address");
        publicMintVerificationAddress = addr;
    }

    /**
     * Sets base URI.
     *
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Sets prereveal base URI.
     *
     * @param newBaseURI The new prereveal base URI.
     */
    function setPreRevealBaseURI(string memory newBaseURI) external onlyOwner {
        preRevealBaseURI = newBaseURI;
    }

    /**
     * Set wether the collection should be revealed or not. Changes the baseURI used.
     *
     * @param state The new revealed state.
     */
    function setRevealed(bool state) external onlyOwner {
        isRevealed = state;
    }

    /**
     * Withdraw contract funds to a given address.
     *
     * @param account The account to withdraw to.
     * @param amount The amount to withdraw.
     */
    function ownerWithdraw(address payable account, uint256 amount) external virtual onlyOwner {
        require(account != address(0), "invalid address");

        Address.sendValue(account, amount);
    }

    /**
     * Withdraw contract funds to a given address.
     *
     * @param account The account to withdraw to.
     * @param amount The amount to withdraw.
     */
    function ownerWithdraw(address payable account, uint256 amount, address tokenAddress) external virtual onlyOwner {
        require(account != address(0), "invalid address");

        IERC20(tokenAddress).safeTransfer(account, amount);
    }

    //
    // Views
    //

    /**
     * Returns either the public or pre-reveal base uri for the token metadata.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (isRevealed) {
            return baseURI;
        }
        return preRevealBaseURI;
    }

    function getPoints(address account) external view returns (uint256) {
        uint256 totalPoints = 0;
        for (uint256 i; i < balanceOf(account); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i);
            uint256 buildingId = tokenIdToBuildingId[tokenId];

            totalPoints += buildings[buildingId].points;
        }
        return totalPoints;
    }
}
