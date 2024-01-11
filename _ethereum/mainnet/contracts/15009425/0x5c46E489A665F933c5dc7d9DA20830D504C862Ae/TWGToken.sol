// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ReentrancyGuard.sol";

error TWG_ExceedsMaxPerAddress();
error TWG_ExceedsPublicSupply();
error TWG_FunctionLocked();
error TWG_InvalidAmount();
error TWG_InvalidValue();
error TWG_ClaimDisabled();
error TWG_MintDisabled();
error TWG_TokenNotVested();
error TWG_VestingNotStarted();

interface IWolfGuildMintPass is IERC1155 {
    function burn(address from, uint256 id) external;
}

interface IWolfGuildVestingMintPass is IWolfGuildMintPass {
    function mint(address to, uint256 id) external;
}

contract TWGToken is ERC1155, Ownable, ReentrancyGuard {
    IWolfGuildMintPass public immutable WOLF_GUILD_MINT_PASS;
    IWolfGuildVestingMintPass public immutable WOLF_GUILD_VESTING_MINT_PASS;

    uint256 public constant RT_DAY0_CLAIM_AMOUNT = 27;
    uint256 public constant FC_DAY0_CLAIM_AMOUNT = 16;
    uint256 public constant RT_VESTED_CLAIM_AMOUNT = 9;
    uint256 public constant FC_VESTED_CLAIM_AMOUNT = 5;
    uint256 public constant OG_CLAIM_AMOUNT_PER_MP = 3;
    uint256 public constant VESTING_PERIOD_DURATION = 90 days;
    uint256 public constant MAX_VESTING_PERIOD = 8;
    string private constant NAME = "The Wolf Guild Token";
    string private constant SYMBOL = "TWG";

    uint256 public publicSupply = 3460;
    uint256 public ogPrice = 0.069 ether;
    uint256 public publicPrice = 0.1 ether;
    uint256 public maxPerAddress = 20;
    uint256 public vestingStartedAt;
    uint256 public discountMinted;
    uint256 public publicMinted;
    uint256 public totalClaimed;
    bool public claimEnabled;
    bool public mintEnabled;
    mapping(address => uint256) public addressMintedAmount;

    constructor(
        string memory _uri,
        IWolfGuildMintPass _mintPass,
        IWolfGuildVestingMintPass _vestingMintPass
    )
        ERC1155(_uri)
    {
        WOLF_GUILD_MINT_PASS = IWolfGuildMintPass(_mintPass);
        WOLF_GUILD_VESTING_MINT_PASS = IWolfGuildVestingMintPass(_vestingMintPass);
    }

    /**
     * @notice Mock ERC721 name functionality
     * @return string Token name
     */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /**
     * @notice Mock ERC721 symbol functionality
     * @return string Token symbol
     */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /**
     * @notice Total amount of tokens minted and claimed
     * @return uint256 Total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return totalClaimed + publicMinted + discountMinted;
    }

    /**
     * @notice Current vesting period if vesting has started
     * @return uint256 Current vesting period
     */
    function vestingPeriod() public view returns (uint256) {
        if (vestingStartedAt == 0) revert TWG_VestingNotStarted();

        uint256 period = (block.timestamp - vestingStartedAt) / VESTING_PERIOD_DURATION;
        return (period > MAX_VESTING_PERIOD) ? MAX_VESTING_PERIOD : period;
    }

    /**
     * @notice Time remaining until next vesting period
     * @return uint256 Seconds until next vesting period
     */
    function vestingRemainingTime() public view returns (uint256) {
        return (vestingPeriod() == MAX_VESTING_PERIOD)
            ? 0
            : VESTING_PERIOD_DURATION - ((block.timestamp - vestingStartedAt) % VESTING_PERIOD_DURATION);
    }

    /**
     * @notice Flip between enabling and disabling RT and FC token claim
     * @dev The first time this is done will set the vesting timer
     */
    function flipClaimEnabled() external onlyOwner {
        if (vestingStartedAt == 0) vestingStartedAt = block.timestamp;

        claimEnabled = !claimEnabled;
    }

    /**
     * @notice Flip between enabling and disabling OG and public mint
     */
    function flipMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    /**
     * @notice Set the discounted price for OG mints
     * @param price New price of OG mints
     */
    function setOgPrice(uint256 price) external onlyOwner {
        ogPrice = price;
    }

    /**
     * @notice Set the price for public mints
     * @param price New price of public mints
     */
    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    /**
     * @notice Set the maximum amount of tokens an address can public mint
     * @param max New maximum amount of tokens
     */
    function setMaxPerAddress(uint256 max) external onlyOwner {
        maxPerAddress = max;
    }

    /**
     * @notice Set token URI for all tokens
     * @dev More details in ERC1155 contract
     * @param uri base metadata URI applied to token IDs
     */
    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    /**
     * @notice Claim tokens using a RT or FC mint pass
     * @param tokenId Mint pass to claim with
     */
    function claim(uint256 tokenId) external nonReentrant {
        if (!claimEnabled) revert TWG_ClaimDisabled();

        uint256 requiredVestingPeriod = tokenId / 2;
        uint256 currentVestingPeriod = vestingPeriod();

        if (requiredVestingPeriod > currentVestingPeriod) revert TWG_TokenNotVested();

        totalClaimed += requiredVestingPeriod > 0
            ? vestedClaim(tokenId, currentVestingPeriod, currentVestingPeriod - requiredVestingPeriod)
            : day0Claim(tokenId);
    }

    /**
     * @notice Returns if a token is a RT token
     * @param tokenId Token to check
     * @return bool Whether or not token is a RT token
     */
    function isRTToken(uint256 tokenId) private pure returns (bool) {
        return tokenId % 2 == 0;
    }

    /**
     * @notice Initial claim for a RT or FC mint pass available at day 0
     * @param tokenId Mint pass to claim with
     * @return uint256 Amount of tokens minted
     */
    function day0Claim(uint256 tokenId) private returns (uint256) {
        WOLF_GUILD_MINT_PASS.burn(msg.sender, tokenId);

        uint256 amountClaimed = isRTToken(tokenId) ? RT_DAY0_CLAIM_AMOUNT : FC_DAY0_CLAIM_AMOUNT;
        _mint(msg.sender, 0, amountClaimed, "");

        WOLF_GUILD_VESTING_MINT_PASS.mint(msg.sender, tokenId + 2);

        return amountClaimed;
    }

    /**
     * @notice Vested claim for a RT or FC mint pass
     * @param tokenId Mint pass to claim with
     * @param currentVestingPeriod Current vesting period
     * @param vestingPeriodDifference Difference between the current vesting period and required vesting period
     * @return uint256 Amount of tokens minted
     */
    function vestedClaim(
        uint256 tokenId,
        uint256 currentVestingPeriod,
        uint256 vestingPeriodDifference
    )
        private
        returns (uint256)
    {
        WOLF_GUILD_VESTING_MINT_PASS.burn(msg.sender, tokenId);

        uint256 baseClaimAmount = isRTToken(tokenId) ? RT_VESTED_CLAIM_AMOUNT : FC_VESTED_CLAIM_AMOUNT;
        uint256 amountClaimed = (vestingPeriodDifference + 1) * baseClaimAmount;
        _mint(msg.sender, 0, amountClaimed, "");

        if (currentVestingPeriod < MAX_VESTING_PERIOD) {
            WOLF_GUILD_VESTING_MINT_PASS.mint(msg.sender, tokenId + 2 + (vestingPeriodDifference * 2));
        }

        return amountClaimed;
    }

    /**
     * @notice Mint tokens at a discounted price using OG mint passes
     * @param amount Amount of tokens to mint (requires 1 OG MP for every 3 tokens)
     */
    function discountMint(uint256 amount) external payable nonReentrant {
        if (msg.value != amount * ogPrice) revert TWG_InvalidValue();
        if (amount == 0) revert TWG_InvalidAmount();

        uint256 abandonedTokens = amount % OG_CLAIM_AMOUNT_PER_MP;
        uint256 requiredMintPasses = amount / OG_CLAIM_AMOUNT_PER_MP
            + (abandonedTokens == 0 ? 0 : 1);
        publicSupply += abandonedTokens;

        for (uint256 i; i < requiredMintPasses;) {
            WOLF_GUILD_MINT_PASS.burn(msg.sender, 2);
            unchecked { ++i; }
        }

        _mint(msg.sender, amount);
        discountMinted += amount;
    }

    /**
     * @notice Mint tokens at full price
     * @param amount Amount of tokens to mint
     */
    function publicMint(uint256 amount) external payable nonReentrant {
        addressMintedAmount[msg.sender] += amount;
        publicMinted += amount;

        if (addressMintedAmount[msg.sender] > maxPerAddress) revert TWG_ExceedsMaxPerAddress();
        if (publicMinted > publicSupply) revert TWG_ExceedsPublicSupply();
        if (msg.value != amount * publicPrice) revert TWG_InvalidValue();

        _mint(msg.sender, amount);
    }

    /**
     * @notice Private minting function
     * @param account Address to mint the tokens to
     * @param amount Amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal {
        if (!mintEnabled) revert TWG_MintDisabled();
        _mint(account, 0, amount, "");
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }
}