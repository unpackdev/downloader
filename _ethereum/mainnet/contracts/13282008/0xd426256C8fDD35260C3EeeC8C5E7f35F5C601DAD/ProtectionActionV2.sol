// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILendingPoolAddressesProvider.sol";
import "./SProtection.sol";
import "./FProtectionActionV2.sol";
import "./FProtectionAction.sol";
import "./ISwapModule.sol";
import "./ProtectionAction.sol";

/// @author Gelato Digital
/// @title ProtectionV2 Action Contract.
/// @dev Perform protection by repaying the debt with collateral token.
contract ProtectionActionV2 is ProtectionAction {
    event LogBestColAndDebtToken(
        bytes32 indexed taskHash,
        address colToken,
        address debtToken,
        uint256 rateMode
    );

    // solhint-disable no-empty-blocks
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        address __aaveServices,
        ISwapModule __swapModule
    ) ProtectionAction(_addressProvider, __aaveServices, __swapModule) {}

    /// Execution of Protection.
    /// @param _taskHash Task identifier.
    /// @param _data Data needed to perform Protection.
    /// @dev _data is on-chain data, one of the input to produce Task hash of Aave services.
    /// @param _offChainData Data computed off-chain and needed to perform Protection.
    /// @dev _offChainData include the amount of collateral to withdraw
    /// and the amount of debt token to repay, cannot be computed on-chain.
    // solhint-disable function-max-lines
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external override onlyAaveServices {
        ProtectionPayload memory protectionPayload = _getProtectionPayload(
            _taskHash,
            _data,
            _offChainData
        );

        emit LogBestColAndDebtToken(
            _taskHash,
            protectionPayload.colToken,
            protectionPayload.debtToken,
            protectionPayload.rateMode
        );

        // Check if the task submitter is the aave user.
        _checkSubmitterIsUser(protectionPayload, _data);

        // Check if AmtToFlashBorrow and AmtOfDebtToRepay are the one given by the formula.
        _checkRepayAndFlashBorrowAmt(
            protectionPayload,
            LENDING_POOL,
            ADDRESSES_PROVIDER,
            this
        );

        // Cannot give to executeOperation the path array through params bytes
        // => Stack too Deep error.

        _flashLoan(LENDING_POOL, address(this), protectionPayload);

        // Fetch User Data After Refinancing

        (, , , , , uint256 healthFactor) = LENDING_POOL.getUserAccountData(
            protectionPayload.onBehalfOf
        );

        // Check if the service didn't keep any dust amt.
        _transferDust(
            address(this),
            protectionPayload.debtToken,
            protectionPayload.onBehalfOf
        );

        // Check if position is safe.
        _requirePositionSafe(
            healthFactor,
            discrepancyBps,
            protectionPayload.wantedHealthFactor
        );
    }
}
