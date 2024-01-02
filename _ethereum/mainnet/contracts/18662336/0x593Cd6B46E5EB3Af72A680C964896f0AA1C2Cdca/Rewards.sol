//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

contract TaskRewards is Ownable, ReentrancyGuard {
    /// @notice Thrown when signature is invalid
    error InvalidSignature();

    /// @notice Thrown when cooldownPeriod is not passed
    error CoolPeriodNotOver();

    /// @notice Thrown when value is zero
    error ZeroValue();

    /// @notice Thrown when trying to reuse same signature
    error HashUsed();

    /// @notice Thrown when zero address is passed in an input
    error ZeroAddress();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Thrown when deadline time of signature is over
    error DeadlineExpired();

    /// @notice Thrown when Redeem is disabled
    error RedeemNotEnable();

    IERC20 public tomiToken;
    using SafeERC20 for IERC20;

    /// @notice The address of signerWallet
    address public signerWallet;

    /// @notice The address of rewardWallet
    address public rewardWallet;

    /// @notice The cooldownPeriod (in second)
    uint256 public cooldownPeriod;

    /// @notice The redeem enabled or not
    bool public enableRedeem = true;

    /// @notice Gives last redeem time of the address
    mapping(address => uint256) public lastRedeemTime;

    /// @notice Gives the amount redeemed by the address
    mapping(address => uint256) public userRedeemHistory;

    /// @notice Gives the info of the signature
    mapping(bytes32 => bool) private _isUsed;

    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensRedeemed(address indexed redeemer, uint256 amount);
    event CooldownPeriodUpdated(
        uint256 oldCoolDownPeriod,
        uint256 newCooldownPeriod
    );
    event EnableRedeemUpdated(bool oldAccess, bool newAccess);
    event RewardWalletUpdated(address oldRewardWallet, address newRewardWallet);
    event SignerUpdated(address oldSigner, address newSigner);

    /// @notice Restricts when updating wallet/contract address to zero address
    modifier checkZeroAddress(address which) {
        if (which == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice Restricts when Redeem is disabled
    modifier canRedeem() {
        if (!enableRedeem) {
            revert RedeemNotEnable();
        }
        _;
    }

    /// @dev Constructor.
    /// @param owner The address of owner wallet
    /// @param signerAddress The address of signer wallet
    /// @param tomiTokenAddress The address of tomi token
    /// @param cooldownDuration The cooldown duration in seconds
    /// @param rewardWalletAddress The address of the reward wllet
    constructor(
        address owner,
        address signerAddress,
        address tomiTokenAddress,
        uint256 cooldownDuration,
        address rewardWalletAddress
    ) Ownable(owner) {
        if (
            owner == address(0) ||
            signerAddress == address(0) ||
            tomiTokenAddress == address(0) ||
            rewardWalletAddress == address(0)
        ) {
            revert ZeroAddress();
        }
        signerWallet = signerAddress;
        tomiToken = IERC20(tomiTokenAddress);
        cooldownPeriod = cooldownDuration;
        rewardWallet = rewardWalletAddress;
    }

    /// @notice Redeems tomi tokens
    /// @param deadline The expiry time of the signature
    /// @param amount The amount of tomi tokens
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function redeemTokens(
        uint256 deadline,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external canRedeem nonReentrant {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        if (lastRedeemTime[msg.sender] + cooldownPeriod > block.timestamp) {
            revert CoolPeriodNotOver();
        }
        if (amount == 0) {
            revert ZeroValue();
        }
        _verifySignature(msg.sender, amount, deadline, v, r, s);
        userRedeemHistory[msg.sender] += amount;
        lastRedeemTime[msg.sender] = block.timestamp;
        tomiToken.safeTransferFrom(rewardWallet, msg.sender, amount);
        emit TokensRedeemed({redeemer: msg.sender, amount: amount});
    }

    /// @notice Updates cool down period
    /// @param newCooldownPeriod The new cool down period in seconds
    function updateCooldownPeriod(
        uint256 newCooldownPeriod
    ) external onlyOwner {
        uint oldCoolDownPeriod = cooldownPeriod;
        if (newCooldownPeriod == 0) {
            revert ZeroValue();
        }
        if (oldCoolDownPeriod == newCooldownPeriod) {
            revert IdenticalValue();
        }
        emit CooldownPeriodUpdated({
            oldCoolDownPeriod: oldCoolDownPeriod,
            newCooldownPeriod: newCooldownPeriod
        });
        cooldownPeriod = newCooldownPeriod;
    }

    /// @notice Updates reward wallet
    /// @param newRewardWallet The new reward wallet address
    function updateRewardWallet(address newRewardWallet) external onlyOwner {
        address oldRewardWallet = rewardWallet;
        if (newRewardWallet == address(0)) {
            revert ZeroValue();
        }
        if (oldRewardWallet == newRewardWallet) {
            revert IdenticalValue();
        }
        emit RewardWalletUpdated({
            oldRewardWallet: oldRewardWallet,
            newRewardWallet: newRewardWallet
        });
        rewardWallet = newRewardWallet;
    }

    /// @notice Changes access of redeem tokens
    /// @param enabled The new access decision
    function updateEnableRedeem(bool enabled) external onlyOwner {
        bool oldAccess = enableRedeem;
        if (oldAccess == enabled) {
            revert IdenticalValue();
        }
        emit EnableRedeemUpdated({oldAccess: oldAccess, newAccess: enabled});
        enableRedeem = enabled;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function updateSignerAddress(
        address newSigner
    ) external checkZeroAddress(newSigner) onlyOwner {
        address oldSigner = signerWallet;
        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }
        emit SignerUpdated({oldSigner: oldSigner, newSigner: newSigner});
        signerWallet = newSigner;
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalid signature
    function _verifySignature(
        address redeemer,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bytes32 hash = keccak256(abi.encodePacked(redeemer, amount, deadline));
        if (_isUsed[hash]) {
            revert HashUsed();
        }
        if (
            signerWallet !=
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(hash),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
        _isUsed[hash] = true;
    }
}
