// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import { IERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol";

/**
 * @notice Secp256k1 signature values.
 * @param deadline Timestamp at which the signature expires.
 * @param v `v` portion of the signature.
 * @param r `r` portion of the signature.
 * @param s `s` portion of the signature.
 */
struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @title Dollet ERC20Lib
 * @author Dollet Team
 * @notice Helper library that implements some additional methods for interacting with ERC-20 tokens.
 */
library ERC20Lib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Transfers specified amount of token from `_from` to `_to`.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function pull(address _token, address _from, address _to, uint256 _amount) internal {
        IERC20Upgradeable(_token).safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice Transfers specified amount of token from `_from` to `_to` using permit.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     * @param _signature A signature of the permit to use at the time of transfer.
     */
    function pullPermit(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        Signature memory _signature
    )
        internal
    {
        IERC20PermitUpgradeable(_token).permit(
            _from, address(this), _amount, _signature.deadline, _signature.v, _signature.r, _signature.s
        );
        pull(_token, _from, _to, _amount);
    }

    /**
     * @notice Transfers a specified amount of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function push(address _token, address _to, uint256 _amount) internal {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Transfers the current balance of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     */
    function pushAll(address _token, address _to) internal {
        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));

        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Executes a safe approval operation on a token. If the previous allowance is GT 0, it sets it to 0 and
     *         then executes a new approval.
     * @param _token A token to approve.
     * @param _spender A spender of the token to approve for.
     * @param _amount An amount of tokens to approve.
     */
    function safeApprove(address _token, address _spender, uint256 _amount) internal {
        if (IERC20Upgradeable(_token).allowance(address(this), _spender) != 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
        }

        IERC20Upgradeable(_token).safeApprove(_spender, _amount);
    }
}
