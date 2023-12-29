// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IERC20.sol";
import "./IERC721.sol";

import "./ILoanCore.sol";
import "./IOriginationController.sol";
import "./IFeeController.sol";

import "./ILoanCoreV2.sol";
import "./IRepaymentControllerV2.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

interface IVault {
    /**
     * @dev copied from @balancer-labs/v2-vault/contracts/interfaces/IVault.sol,
     *      which uses an incompatible compiler version. Only necessary selectors
     *      (flashLoan) included.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IV2ToV3RolloverBase is IFlashLoanRecipient {
    event V2V3Rollover(
        address indexed lender,
        address indexed borrower,
        uint256 collateralTokenId,
        uint256 newLoanId
    );
    
    event PausedStateChanged(bool isPaused);

    struct OperationContracts {
        IFeeController feeControllerV3;
        IOriginationController originationControllerV3;
        ILoanCore loanCoreV3;
        IERC721 borrowerNoteV3;
    }

    function flushToken(IERC20 token, address to) external;

    function pause(bool _pause) external;
}
