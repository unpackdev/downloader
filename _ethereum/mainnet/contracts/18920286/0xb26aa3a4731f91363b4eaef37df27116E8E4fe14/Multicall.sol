// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Errors.sol";
import "./CallLib.sol";
import "./TokenUtils.sol";
import "./IAdapter.sol";

/**
 * @title Multicall
 * @author StakeEase
 * @notice Multicaller contract.
 */
contract Multicall is TokenUtils, AccessControl {
    using SafeERC20 for IERC20;

    struct RefundData {
        address[] tokens;
    }

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    uint256 public constant TEMP_TOKENS_LENGTH = 6;

    mapping(address => bool) private whitelistedBridgeAdapters;

    constructor(address[] memory _whitelistedBridgeAdapters) payable {
        uint256 length = _whitelistedBridgeAdapters.length;

        for (uint256 i = 0; i < length; ) {
            require(
                _whitelistedBridgeAdapters[i] != address(0),
                Errors.BRIDGE_ADAPTER_ADDRESS_CANNOT_BE_ZERO
            );

            whitelistedBridgeAdapters[_whitelistedBridgeAdapters[i]] = true;

            unchecked {
                ++i;
            }
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
    }

    /**
     * @notice Function to check if a bridge adapter is whitelisted.
     * @param bridgeAdapter Address of the bridge adapter.
     */
    function isBridgeWhitelisted(
        address bridgeAdapter
    ) public view returns (bool) {
        return whitelistedBridgeAdapters[bridgeAdapter];
    }

    /**
     * @notice Function to whitelist a bridge adapter.
     * @notice Can only be called by an address with the SETTER_ROLE.
     * @param bridgeAdapters Array of addresses of bridge adapters.
     * @param shouldWhitelist Array of booleans suggesting whether the bridge adapter should be whitelisted.
     */
    function setBridgeWhitelist(
        address[] memory bridgeAdapters,
        bool[] memory shouldWhitelist
    ) external onlyRole(SETTER_ROLE) {
        uint256 length = bridgeAdapters.length;
        require(length == shouldWhitelist.length, Errors.ARRAY_LENGTH_MISMATCH);

        for (uint256 i = 0; i < length; ) {
            require(
                bridgeAdapters[i] != address(0),
                Errors.BRIDGE_ADAPTER_ADDRESS_CANNOT_BE_ZERO
            );

            whitelistedBridgeAdapters[bridgeAdapters[i]] = shouldWhitelist[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev function to execute batch calls on the same chain.
     * @param token Addresses of the tokens to fetch from the user.
     * @param amount amounts of the tokens to fetch from the user.
     * @param target Addresses of the contracts to call.
     * @param data Data of the transactions.
     */
    function execute(
        address token,
        uint256 amount,
        address[] calldata target,
        bytes[] calldata data
    ) external payable {
        require(amount > 0, Errors.AMOUNT_CANNOT_BE_ZERO);

        if (token != NATIVE_ADDRESS) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        } else
            require(
                msg.value == amount,
                Errors.INSUFFICIENT_NATIVE_FUNDS_PASSED
            );

        address[] memory tempTokens = new address[](TEMP_TOKENS_LENGTH);
        tempTokens[0] = token;

        _executeBatch(msg.sender, target, data, tempTokens);
    }

    /**
     * @dev Function to execute batch calls on the destination chain.
     * @param refundRecipient Address of recipient of refunds of dust at the end.
     * @param target Addresses of the contracts to call.
     * @param data Data of the transactions.
     */
    function executeDest(
        address refundRecipient,
        address[] calldata target,
        bytes[] calldata data
    ) external payable {
        require(msg.sender == address(this), Errors.ONLY_SELF);

        address[] memory tempTokens = new address[](TEMP_TOKENS_LENGTH);
        tempTokens[0] = NATIVE_ADDRESS;

        _executeBatch(refundRecipient, target, data, tempTokens);
    }

    /**
     * @notice Function to receive calls from Bridge Adapters on the destination chain.
     * @notice Always native tokens should be received with this call.
     * @param payload Payload received from the source chain.
     */
    function bridgeReceive(
        bytes memory payload
    ) external payable onlyWhitelistedBridges {
        uint256 amount = msg.value;

        require(amount != 0, Errors.AMOUNT_CANNOT_BE_ZERO);

        (
            address refundAddress,
            address[] memory target,
            bytes[] memory data
        ) = abi.decode(payload, (address, address[], bytes[]));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(
            abi.encodeWithSelector(
                this.executeDest.selector,
                refundAddress,
                target,
                data
            )
        );

        require(success, Errors.BRIDGE_TX_FAILED_ON_MULTICALL);
    }

    /**
     * @notice Function to withdraw funds from this contract which may be sent due to mistake.
     * @notice Can only be called by the DEFAULT_ADMIN.
     * @param token Address of the token to withdraw.
     * @param recipient Address of the recipient.
     * @param amount Amount of funds to withdraw.
     */
    function emergencyWithdrawFunds(
        address token,
        address recipient,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), Errors.RECIPIENT_CANNOT_BE_ZERO);

        if (token == address(0) || token == NATIVE_ADDRESS) {
            if (amount == 0) amount = address(this).balance;
            if (amount == 0) revert(Errors.AMOUNT_CANNOT_BE_ZERO);
            payable(recipient).transfer(amount);
        } else {
            if (amount == 0) amount = IERC20(token).balanceOf(address(this));
            if (amount == 0) revert(Errors.AMOUNT_CANNOT_BE_ZERO);
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    /**
     * @dev Function to execute batch calls.
     * @param refundRecipient Address of the refund recipient.
     * @param target Addresses of the contracts to call.
     * @param data Data of the transactions.
     */
    function _executeBatch(
        address refundRecipient,
        address[] calldata target,
        bytes[] calldata data,
        address[] memory tempTokens
    ) internal {
        uint256 targetLength = target.length;

        require(
            targetLength != 0 && targetLength == data.length,
            Errors.WRONG_BATCH_PROVIDED
        );

        uint256 returnAmount = 0;

        for (uint256 i = 0; i < targetLength; ) {
            (returnAmount, tempTokens) = _execute(
                target[i],
                returnAmount,
                i,
                data[i],
                tempTokens
            );

            unchecked {
                ++i;
            }
        }

        _processRefunds(refundRecipient, tempTokens);
    }

    function _execute(
        address target,
        uint256 returnAmount,
        uint256 index,
        bytes memory data,
        address[] memory tempTokens
    ) internal returns (uint256, address[] memory) {
        bytes memory _calldata = abi.encodeWithSelector(
            IAdapter.execute.selector,
            index,
            returnAmount,
            data
        );

        bytes memory result = CallLib._delegateCall(target, _calldata);

        (uint256 returnVal, address token) = abi.decode(
            result,
            (uint256, address)
        );

        tempTokens[index + 1] = token;

        return (returnVal, tempTokens);
    }

    function _processRefunds(
        address user,
        address[] memory tempTokens
    ) internal {
        for (uint256 i = 0; i < TEMP_TOKENS_LENGTH; ) {
            if (tempTokens[i] == address(0)) {
                break;
            }

            withdrawTokens(tempTokens[i], user, type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    function _onlyWhitelistedBridges() private view {
        require(
            isBridgeWhitelisted(msg.sender),
            Errors.ONLY_WHITELISTED_BRIDGES
        );
    }

    modifier onlyWhitelistedBridges() {
        _onlyWhitelistedBridges();
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
