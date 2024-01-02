// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Errors.sol";
import "./IFeeManager.sol";

/**
 * @title FeeManager
 * @author StakeEase
 * @notice Fee Manager contract for StakeEase.
 */
contract FeeManager is IFeeManager, AccessControl {
    using SafeERC20 for IERC20;

    struct Fee {
        uint64 minFee;
        uint64 maxFee;
        uint64 bpsFeex1000;
    }

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    uint256 public constant PRECISION = 10 ** 7;
    Fee private _fee;

    constructor(Fee memory fee) payable {
        _fee = fee;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
    }

    /**
     * @notice Function to fetch the fee struct.
     * @return Fee struct.
     */
    function getFeeStruct() public view returns (Fee memory) {
        return _fee;
    }

    /**
     * @notice Function to set the fee struct.
     * @notice Can only be called by an address with SETTER_ROLE.
     * @param fee Fee struct to be set.
     */
    function setFeeStruct(Fee memory fee) external onlyRole(SETTER_ROLE) {
        _fee = fee;
    }

    /**
     * @inheritdoc IFeeManager
     */
    function getFee(uint256 txVolume) public view returns (uint256) {
        require(txVolume > 0, Errors.VOLUME_CANNOT_BE_ZERO);

        Fee memory feeStruct = getFeeStruct();
        uint256 fee = (txVolume * feeStruct.bpsFeex1000) / PRECISION;

        if (fee < feeStruct.minFee) return feeStruct.minFee;
        else if (fee > feeStruct.maxFee) return feeStruct.maxFee;

        return fee;
    }

    /**
     * @notice Function to withdraw funds in this contract in case of emergency.
     * @param token Addresses of the token. For native token, pass address(0).
     * @param amount Array of amount of funds to withdraw. To withdraw all, pass this as 0.
     * @param recipient Address of the recipient of funds.
     */
    function withdrawFees(
        address[] memory token,
        uint256[] memory amount,
        address recipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), Errors.RECIPIENT_CANNOT_BE_ZERO);

        uint256 length = token.length;
        require(
            length != 0 || length == amount.length,
            Errors.ARRAY_LENGTH_MISMATCH
        );

        for (uint256 i = 0; i < length; ) {
            if (token[i] != address(0)) {
                if (amount[i] == 0)
                    amount[i] = IERC20(token[i]).balanceOf(address(this));

                if (amount[i] == 0) {
                    revert(Errors.AMOUNT_CANNOT_BE_ZERO);
                }

                IERC20(token[i]).safeTransfer(recipient, amount[i]);
            } else {
                if (amount[i] == 0) amount[0] = address(this).balance;

                if (amount[i] == 0) {
                    revert(Errors.AMOUNT_CANNOT_BE_ZERO);
                }

                payable(recipient).transfer(amount[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
