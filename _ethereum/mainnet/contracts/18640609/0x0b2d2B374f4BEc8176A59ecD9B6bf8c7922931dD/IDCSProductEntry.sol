// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./DCSStructs.sol";
import "./IOracleEntry.sol";

interface IDCSProductEntry {
    // FUNCTIONS

    function dcsGetProduct(
        uint32 productId
    ) external view returns (DCSProduct memory);

    function dcsGetProductDepositAsset(
        uint32 productId
    ) external view returns (address);

    function dcsGetDepositQueue(
        uint32 productId
    )
        external
        view
        returns (
            address[] memory depositors,
            uint128[] memory amounts,
            uint128 totalAmount
        );

    function dcsGetWithdrawalQueue(
        address vaultAddress
    )
        external
        view
        returns (
            Withdrawer[] memory withdrawers,
            uint256[] memory amounts,
            bool[] memory withProxy,
            uint256 totalAmount
        );

    function dcsIsWithdrawalPossible(
        address vaultAddress
    ) external view returns (bool);

    function dcsCalculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128);

    function dcsCreateProduct(
        DCSProductCreationParams calldata creationParams
    ) external returns (uint32);

    function dcsAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function dcsProcessDepositQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    function dcsAddToWithdrawalQueue(
        address vault,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    function dcsAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;

    function dcsProcessWithdrawalQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    function dcsCheckTradeExpiry(address vaultAddress) external;

    function dcsCheckSettlementDefault(address vaultAddress) external;

    function dcsCollectVaultFees(address vaultAddress) external;

    function dcsSubmitDispute(address vaultAddress) external;

    function dcsProcessTradeDispute(
        address vaultAddress,
        uint128 newPrice
    ) external;
}
