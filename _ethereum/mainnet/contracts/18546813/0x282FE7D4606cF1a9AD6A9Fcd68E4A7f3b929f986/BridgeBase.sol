// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

import "./BridgeUserBlocklist.sol";
import "./BridgeTransfer.sol";
import "./BridgeSignatureTransfer.sol";
import "./BridgeSignatures.sol";
import "./BridgeRefundRequest.sol";
import "./BridgeRoles.sol";

contract BridgeBase is Pausable, BridgeSignatures, BridgeSignatureTransfer, BridgeUserBlocklist, BridgeRefundRequest {
    event EmergencyTokenWithdraw(address indexed token, address indexed to, uint amount, uint timestamp);

    using SafeERC20 for IERC20;

    constructor(
        address owner_,
        address admin_,
        address refundManager_,
        address[] memory signers_,
        address token_,
        address blocklist_,
        string memory name
    )
        BridgeUserBlocklist(blocklist_)
        BridgeRoles(owner_, admin_, refundManager_, signers_)
        BridgeSignatures(name, "1")
        BridgeTransfer(token_)
    {
        _setMinTeleportAmount(1000);
    }

    receive() external payable {
        revert("Bridge: ether can not be sent to the bridge contract");
    }

    modifier moreThanMinTeleportAmount(uint amount) {
        require(amount >= minTeleportAmount, "Bridge: amount is less than min teleport amount");
        _;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(BridgeUserBlocklist, AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || BridgeUserBlocklist.supportsInterface(interfaceId);
    }

    /******************************************************************************/
    /*                     BridgeTransfer & BridgeSigTransfer                     */
    /******************************************************************************/

    /**
     * @dev Teleports tokens from the user to the bridge contract.
     * @param amount The amount of tokens to teleport.
     * @notice The user must approve the bridge contract to transfer the tokens.
     */
    function teleport(
        uint256 amount
    ) external userIsNotBlocked(msg.sender) whenNotPaused moreThanMinTeleportAmount(amount) {
        _teleport(msg.sender, address(this), amount);
    }

    /**
     * @dev Teleports tokens from the user to the bridge contract.
     * @param from The address of the user to teleport the tokens from.
     * @param amount The amount of tokens to teleport.
     * @param deadline The deadline for the signature.
     * @param r The signature's R value.
     * @param s The signature's S value.
     * @param v The signature's V value.
     * @notice The user must approve the bridge contract to transfer the tokens.
     */
    function teleportSig(
        address from,
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external userIsNotBlocked(from) whenNotPaused moreThanMinTeleportAmount(amount) {
        _teleportSig(from, amount, deadline, r, s, v);
    }

    /**
     * @dev Claims tokens from the bridge contract to the user.
     * @param to The address of the user to claim the tokens to.
     * @param amount The amount of tokens to claim.
     * @param otherChainNonce The nonce of the teleport on the other chain.
     * @param signerInfo The array of signer info.
     */
    function claimSig(
        address to,
        uint256 amount,
        uint256 otherChainNonce,
        SignatureWithDeadline[] calldata signerInfo
    ) external userIsNotBlocked(to) whenNotPaused {
        _claimSig(to, amount, otherChainNonce, signerInfo);
    }

    /**
     * @dev Sets the minimum amount of tokens to teleport.
     * @param amount The minimum amount of tokens to teleport.
     */
    function setMinTeleportAmount(uint256 amount) external onlyOwner whenNotPaused {
        _setMinTeleportAmount(amount);
    }

    /******************************************************************************/
    /*                            BridgeRefundRequest                             */
    /******************************************************************************/

    // To open refund request user must call openRefundRequest function first
    // After it's done user must await for the refund request to be approved or declined
    // In case of approval tokens will be transferred to the user instantly
    // In case of decline tokens will not be transferred, but user can contact us to reopen the refund request
    // Either approve or decline of refund request cannot be done quicker than 1 day after the request was opened due to security reasons

    /**
     * @notice Approves a refund request.
     * @param nonce The nonce of the refund(teleport) request.
     * @param signatures The signatures for the refund.
     */
    function approveRefund(
        uint256 nonce,
        SignatureWithDeadline[] memory signatures
    ) external onlyRefundManager whenNotPaused {
        _approveRefund(nonce, signatures);
    }

    /**
     * @notice Declines a refund request.
     * @param nonce The nonce of the refund(teleport) request.
     */
    function declineRefund(uint256 nonce) external onlyRefundManager whenNotPaused {
        _declineRefund(nonce);
    }

    /**
     * @notice Reopens a refund request.
     * @param nonce The nonce of the refund(teleport) request.
     */
    function reopenRefund(uint256 nonce) external onlyRefundManager whenNotPaused {
        _reopenRefund(nonce);
    }

    /**
     * @notice Opens a refund request.
     * @param nonces The nonces of the refund(teleport) requests.
     * @param approved The status of the refund requests.
     * @param signatures Signatures for each of the approved refunds.
     */
    function processRefunds(
        uint256[] calldata nonces,
        bool[] calldata approved,
        SignatureWithDeadline[][] memory signatures
    ) external onlyRefundManager whenNotPaused {
        require(nonces.length == approved.length, "Bridge: nonces and approved arrays must have the same length");
        require(nonces.length == signatures.length, "Bridge: nonces and signatures arrays must have the same length");
        for (uint256 i = 0; i < nonces.length; i++) {
            if (approved[i]) {
                _approveRefund(nonces[i], signatures[i]);
            } else {
                _declineRefund(nonces[i]);
            }
        }
    }

    /******************************************************************************/
    /*                                                                            */
    /******************************************************************************/

    /**
     * @dev Returns the status of the nonces.
     * @param nonces The nonces to check.
     */
    function areProcessedNonces(uint256[] calldata nonces) external view returns (bool[] memory) {
        uint256 length = nonces.length;
        bool[] memory result = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = processedNonces[nonces[i]];
        }
        return result;
    }

    /******************************************************************************/
    /*                                  Pausable                                  */
    /******************************************************************************/

    /**
     * @dev Pauses the bridge.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses the bridge.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /******************************************************************************/
    /*                                    Misc                                    */
    /******************************************************************************/

    /**
     * @dev This function can be used if the bridge contract receives tokens by mistake or some scam tokens are transferred to contract.
     * @param tokens The tokens to withdraw.
     */
    function withdrawTokens(address[] memory tokens) external onlyOwner {
        address bridgeToken = address(token);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                tokens[i] != bridgeToken,
                "Bridge: token address is the same as the bridge token. Can not withdraw bridge token."
            );
            uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).safeTransfer(_msgSender(), amount);
        }
    }

    /**
     * @dev This function can be used if the bridge contract receives ether by mistake.
     */
    function withdrawEther() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}
