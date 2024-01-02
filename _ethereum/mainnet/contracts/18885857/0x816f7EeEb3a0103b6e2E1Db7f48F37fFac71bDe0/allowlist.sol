// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

/// @custom:security-contact billzh@aburra.xyz
contract MemeTokenWillGoToZero is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert if signer assigned tranferred to the zero address.
    error InvalidAddress();

    /// @dev Revert if the FID is not a positive integer.
    error InvalidFid();

    /// @dev Revert if the call provides an invalid signature when minting with fid.
    error InvalidSignature();

    /// @dev Revert if the call provides incorrect payment.
    error InvalidPayment();

    /// @dev Revert if the address mint limit is exceeded.
    error MintLimitExceeded();

    /// @dev Revert if the token max supply is exceeded.
    error MaxSupplyExceeded();

    /// @dev Revert if caller attempts a btach aidrop with mismatched input array lengths or an empty array.
    error InvalidBatchInput();

    /// @dev Revert if the native token transfer fails.
    error FailedToSendNativeToken();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emit an event when tokens are minted.
     *
     * @param user   Address of the user who minted the tokens.
     * @param amount The amount of tokens minted.
     */
    event TokensMinted(address indexed user, uint256 amount);

    /**
     * @dev Emit an event when tokens are minted with FID discount.
     *
     * @param user        Address of the user who minted the tokens.
     * @param amount      The amount of tokens minted.
     * @param farcasterId The FID used for minting.
     */
    event TokensMintedWithFid(
        address indexed user,
        uint256 amount,
        uint256 farcasterId
    );

    /**
     * @dev Emit an event when tokens are airdropped.
     *
     * @param recipient Address of the recipient of the airdrop.
     * @param amount    The amount of tokens airdropped.
     */
    event TokensAirdropped(address indexed recipient, uint256 amount);

    /**
     * @dev Emit an event when a withdrawal to Purple is made (treasury can only go to Purple).
     *
     * @param amount The amount of ether withdrawn.
     */
    event WithdrawalToPurple(uint256 amount);

    /**
     * @dev Emit an event when the signer address changes.
     *
     * @param newSigner The new signer address.
     */
    event SignerAddressChanged(address newSigner);

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The price per hundred tokens in ether.
     */
    uint256 public constant PRICE_PER_HUNDRED_TOKENS = 0.0001 ether;

    /**
     * @notice The last valid FID before Farcaster went permissionless in 2023.
     */
    uint256 public constant LAST_PRE_PERMISSIONLESS_FID = 20939;

    /**
     * @dev The treasury address of Purple. It is a proxy contract deployed on Ethereum Mainnet.
     */
    address public constant PURPLE_DAO_TREASURY =
        0xeB5977F7630035fe3b28f11F9Cb5be9F01A9557D;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The maximum supply of the token.
     */
    uint256 public MAX_SUPPLY;

    /**
     * @notice The maximum amount of tokens that can be minted per address.
     */
    uint256 public MAX_MINT_PER_ADDRESS;

    /**
     * @notice Increment of tokens per mint operation.
     */
    uint256 public MINT_INCREMENT;

    /**
     * @notice The address authorized to sign FID-based minting operations.
     */
    address public signerAddress;

    /**
     * @notice Tracks the amount of tokens minted by each address.
     */
    mapping(address => uint256) public mintedAmounts;

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @param initialOwner The address of the initial owner of the contract.
     */
    function initialize(address initialOwner) public initializer {
        __ERC20_init("FARTS", "FARTS");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (initialOwner == address(0)) {
            revert InvalidAddress();
        }

        signerAddress = initialOwner;
        MAX_SUPPLY = 1e9 * 10 ** decimals();
        MAX_MINT_PER_ADDRESS = 2 * 1e7 * 10 ** decimals();
        MINT_INCREMENT = 100 * 10 ** decimals();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                        MINT AND WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows a user to mint tokens at normal price
     * @param numberOfHundreds The number tokens the user wishes to mint, in hundreds.
     */
    function mint(uint256 numberOfHundreds) public payable {
        uint256 tokensToMint = numberOfHundreds * MINT_INCREMENT;
        uint256 requiredPayment = numberOfHundreds * PRICE_PER_HUNDRED_TOKENS;

        _mintTokens(_msgSender(), tokensToMint, requiredPayment, msg.value);
        emit TokensMinted(_msgSender(), tokensToMint);
    }

    /** @notice Enables a Farcaster user to mint tokens with a discount, validated through a FID-based signature.
     * @param numberOfHundreds The number tokens the user wishes to mint, in hundreds.
     * @param farcasterId The FID (Farcaster ID) used for minting with a discount.
     * @param signature The signature for validating FID ownership.
     */
    function mintWithFid(
        uint256 numberOfHundreds,
        uint256 farcasterId,
        bytes memory signature
    ) public payable {
        if (farcasterId == 0) revert InvalidFid();

        // check signature
        bytes32 message = keccak256(
            abi.encodePacked(_msgSender(), farcasterId)
        );
        bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            message
        );
        if (signedMessageHash.recover(signature) != signerAddress)
            revert InvalidSignature();

        uint256 tokensToMint = numberOfHundreds * MINT_INCREMENT;
        uint256 unitPrice = _calculateUnitPrice(farcasterId);
        uint256 requiredPayment = unitPrice * numberOfHundreds;

        _mintTokens(_msgSender(), tokensToMint, requiredPayment, msg.value);
        emit TokensMintedWithFid(_msgSender(), tokensToMint, farcasterId);
    }

    /** @dev Internal function for minting tokens, applying checks for payment, mint limits, and max supply.
     * @param to The address to mint tokens to.
     * @param tokensToMint The amount of tokens to be minted.
     * @param requiredPayment The ether amount required for the minting operation.
     * @param currentPayment The actual ether amount sent by the user.
     */
    function _mintTokens(
        address to,
        uint256 tokensToMint,
        uint256 requiredPayment,
        uint256 currentPayment
    ) internal nonReentrant {
        if (currentPayment != requiredPayment) revert InvalidPayment();

        if (mintedAmounts[to] + tokensToMint > MAX_MINT_PER_ADDRESS)
            revert MintLimitExceeded();

        if (totalSupply() + tokensToMint > MAX_SUPPLY)
            revert MaxSupplyExceeded();

        mintedAmounts[to] += tokensToMint;

        _mint(to, tokensToMint);
    }

    /** @dev Internal function to calculate the unit price for minting, based on the given FID.
     * @param farcasterId The FID for which the unit price is being calculated.
     * @return uint256 The calculated unit price for the given FID.
     */
    function _calculateUnitPrice(
        uint256 farcasterId
    ) internal pure returns (uint256) {
        uint256 newPricePctBasisPoints;

        if (farcasterId >= 1 && farcasterId <= LAST_PRE_PERMISSIONLESS_FID) {
            // new price scales linearly between 10% (1000 basis points) and 90% (9000 basis points)
            // integer division used for simplicity. loss of precision is minimum
            newPricePctBasisPoints =
                1000 +
                (farcasterId * 8000) /
                LAST_PRE_PERMISSIONLESS_FID;
        } else {
            newPricePctBasisPoints = 9000;
        }

        return (PRICE_PER_HUNDRED_TOKENS * newPricePctBasisPoints) / 10000;
    }

    /** @notice Returns the remaining quota of tokens that an address can mint.
     * @param user The address for which the remaining mint quota is queried.
     * @return uint256 The remaining amount of tokens that the user can mint.
     */
    function remainingMintQuota(address user) public view returns (uint256) {
        return MAX_MINT_PER_ADDRESS - mintedAmounts[user];
    }

    /** @notice Allows withdrawal of contract's ether balance to Purple Treasury address. Anyone can call this function.
     */
    function withdrawToPurple() public nonReentrant {
        uint256 FUNDS_SEND_NORMAL_GAS_LIMIT = 310_000;

        uint256 balance = address(this).balance;
        (bool sent, ) = PURPLE_DAO_TREASURY.call{
            value: balance,
            gas: FUNDS_SEND_NORMAL_GAS_LIMIT
        }("");
        if (!sent) revert FailedToSendNativeToken();

        emit WithdrawalToPurple(balance);
    }

    /*//////////////////////////////////////////////////////////////
                        PERMISSIONED ACTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Airdrops a specified amount of tokens to a given address.
     * @param to The address to receive the airdropped tokens.
     * @param amount The amount of tokens to be airdropped.
     */
    function airdrop(address to, uint256 amount) public onlyOwner {
        _airdrop(to, amount);
    }

    /** @notice Airdrops tokens to multiple addresses in a single transaction.
     * @param recipients An array of addresses to receive the airdropped tokens.
     * @param amounts An array of token amounts to be airdropped to the corresponding addresses.
     */
    function batchAirdrop(
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwner {
        if (recipients.length == 0 || amounts.length == 0)
            revert InvalidBatchInput();

        if (recipients.length != amounts.length) revert InvalidBatchInput();

        for (uint256 i = 0; i < recipients.length; ++i) {
            _airdrop(recipients[i], amounts[i]);
        }
    }

    /** @dev Internal function to handle the airdropping of tokens.
     * @param recipient The address to receive the airdropped tokens.
     * @param amount The amount of tokens to be airdropped.
     */
    function _airdrop(address recipient, uint256 amount) internal nonReentrant {
        uint256 amountWithDecimals = amount * 10 ** decimals();

        if (totalSupply() + amountWithDecimals > MAX_SUPPLY)
            revert MaxSupplyExceeded();

        _mint(recipient, amountWithDecimals);
        emit TokensAirdropped(recipient, amountWithDecimals);
    }

    /** @notice Updates the signer address used for FID-based minting validation.
     * @param _signerAddress The new signer address.
     */
    function setSignerAddress(
        address _signerAddress
    ) public onlyOwner nonReentrant {
        if (_signerAddress == address(0)) revert InvalidAddress();
        signerAddress = _signerAddress;
        emit SignerAddressChanged(_signerAddress);
    }
}
