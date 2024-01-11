// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "./Address.sol";
import "./IERC20.sol";
import "./ICreditManagerV2.sol";
import "./IAdapter.sol";
import "./IErrors.sol";
import "./Constants.sol";

abstract contract AbstractAdapter is IAdapter {
    using Address for address;

    ICreditManagerV2 public immutable override creditManager;
    address public immutable override creditFacade;
    address public override targetContract;

    constructor(address _creditManager, address _targetContract) {
        if (_creditManager == address(0) || _targetContract == address(0))
            revert ZeroAddressException(); // F:[ACV1-1]

        creditManager = ICreditManagerV2(_creditManager); // F:[ACV1-2]
        creditFacade = ICreditManagerV2(_creditManager).creditFacade(); // F:[ACV1-2]
        targetContract = _targetContract;
    }

    function _executeFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        result = _executeFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn
        );
    }

    function _executeFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        if (allowTokenIn) {
            if (
                IERC20(tokenIn).allowance(creditAccount, targetContract) <
                ALLOWANCE_THRESHOLD // F:[CM-24]
            ) {
                creditManager.approveCreditAccount(
                    msg.sender,
                    targetContract,
                    tokenIn,
                    type(uint256).max
                );
            }
        }

        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); //
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); //
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); //

        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            ); //
        } else {
            creditManager.checkAndEnableToken(creditAccount, tokenOut); //
        }
    }

    function _safeExecuteFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); //
        }

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                balanceInBefore
            );
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); //

        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            ); //
        } else {
            creditManager.checkAndEnableToken(creditAccount, tokenOut); //
        }

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                1
            );
        }
    }

    function _executeFullCheck(address creditAccount, bytes memory callData)
        internal
        returns (bytes memory result)
    {
        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); // F:[ACV1_2-4]

        if (msg.sender != creditFacade) {
            creditManager.fullCollateralCheck(creditAccount); // F:[ACV1_2-4]
        }
    }
}
