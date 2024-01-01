// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./ICappedLiquidity.sol";
import "./ILocallyPausable.sol";

interface IGyro2CLPPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory sqrts,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner,
        address capManager,
        ICappedLiquidity.CapParams memory capParams,
        address pauseManager,
        ILocallyPausable.PauseParams memory pauseParams
    ) external returns (address);
}
