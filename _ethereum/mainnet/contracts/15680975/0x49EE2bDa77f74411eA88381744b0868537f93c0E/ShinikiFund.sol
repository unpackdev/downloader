// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./ISignatureVerifier.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract ShinikiFund is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // Info interface address signature
    ISignatureVerifier public SIGNATURE_VERIFIER;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info address token reward
    address public WALLET_REWARD;

    //Info claimed reward for each address
    mapping(address => mapping(address => uint256)) public claimed;

    //Info claimed reward for each address
    mapping(address => uint256) public claimedETH;

    event Claimed(
        address token,
        address receiver,
        uint256 maxAllowce,
        uint256 amount,
        uint256 nonce
    );

    function initialize(address signatureVerifier) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        SIGNATURE_VERIFIER = ISignatureVerifier(signatureVerifier);
        WALLET_REWARD = address(0);
    }

    /**
    @notice User claim reward
     * @param token 'address' token reward
     * @param maxAllowce 'uint256' maximum number reward (not claimed + claimed)
     * @param amount 'uint256' number token to claim
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when claim
     */
    function claim(
        address token,
        uint256 maxAllowce,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(
            SIGNATURE_VERIFIER.verifyClaim(
                token,
                msg.sender,
                maxAllowce,
                amount,
                nonce,
                signature
            ),
            "ShinikiFund: signature claim is invalid"
        );
        require(
            claimed[token][msg.sender] + amount == maxAllowce,
            "ShinikiFund:  can not claimed greater than allowce"
        );
        claimed[token][msg.sender] += amount;
        if (token == address(0)) {
            transferETH(msg.sender, amount);
        } else {
            transferToken(token, WALLET_REWARD, msg.sender, amount);
        }

        emit Claimed(token, msg.sender, maxAllowce, amount, nonce);
    }

    /**
    @notice User claim reward
     * @param maxAllowce 'uint256' maximum number reward (not claimed + claimed)
     * @param amount 'uint256' number token to claim
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when claim
     */
    function claimETH(
        uint256 maxAllowce,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(
            SIGNATURE_VERIFIER.verifyClaimETH(
                msg.sender,
                maxAllowce,
                amount,
                nonce,
                signature
            ),
            "ShinikiFund: signature claim is invalid"
        );
        uint256 totalClaimed = claimedETH[msg.sender] + amount;
        require(
            totalClaimed == maxAllowce,
            "ShinikiFund:  can not claimed greater than allowce"
        );
        claimedETH[msg.sender] = totalClaimed;
        transferETH(msg.sender, amount);
       
        emit Claimed(address(0), msg.sender, maxAllowce, amount, nonce);
    }

    /**
    @notice Setting wallet reward
     * @param _walletReward 'address' token reward
     */
    function setWalletReward(address _walletReward) external onlyOwner {
        WALLET_REWARD = _walletReward;
    }

    /**
    @notice Setting new address signature
     * @param _signatureVerifier 'address' signature 
     */
    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        SIGNATURE_VERIFIER = ISignatureVerifier(_signatureVerifier);
    }

    /**
    @notice Deposite token ETH to pool
     */
    function deposite() public payable onlyOwner {}

    /**
    @notice Withdraw asset
     * @param receiver 'address' receiver token
     * @param amount 'uint256' number token to withdraw
     */
    function withdraw(address receiver, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        transferETH(receiver, amount);
    }

    receive() external payable {}

    /**
    @notice Transfer ETH
     * @param receiver 'address' receiver ETH
     * @param amount 'uint256' number ETH to transfer
     */
    function transferETH(address receiver, uint256 amount) internal {
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "transfer failed.");
    }

    /**
    @notice Transfer token
     * @param token 'address' token
     * @param sender 'address' sender token
     * @param receiver 'address' receiver token
     * @param amount 'uint256' number token to transfer
     */
    function transferToken(
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        require(
            IERC20Upgradeable(token).balanceOf(sender) >= amount,
            "token insufficient balance"
        );
        IERC20Upgradeable(token).safeTransferFrom(sender, receiver, amount);
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
