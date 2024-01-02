// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Structs.sol";
import "./IBlurPool.sol";
import "./IBlend.sol";
import "./DataTypes.sol";

interface IRangeProtocolBlurVaultGetters {
    function blurPool() external view returns (IBlurPool);
    function blend() external view returns (IBlend);
    function getLiensByIndex(
        uint256 from,
        uint256 to
    ) external view returns (DataTypes.LienData[] memory liensData);
    function liensCount() external view returns (uint256);
    function managerFee() external view returns (uint256);
    function getRefinancingAuctionRate(
        Lien calldata lien,
        uint256 lienId
    ) external view returns (uint256 rateLimit);
    function getCurrentDebtByLien(
        Lien calldata lien,
        uint256 lienId
    ) external view returns (uint256 currentDebt);
}
