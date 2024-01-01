// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IVault.sol";

import "./BasePoolSplitCodeFactory.sol";

import "./IGyro2CLPPoolFactory.sol";
import "./ICappedLiquidity.sol";
import "./ILocallyPausable.sol";
import "./Gyro2CLPPool.sol";

contract Gyro2CLPPoolFactory is IGyro2CLPPoolFactory, BasePoolSplitCodeFactory {
    address public immutable gyroConfigAddress;

    constructor(IVault vault, address _gyroConfigAddress) BasePoolSplitCodeFactory(vault, type(Gyro2CLPPool).creationCode) {
        _grequire(_gyroConfigAddress != address(0), GyroErrors.ZERO_ADDRESS);
        _grequire(address(vault) != address(0), GyroErrors.ZERO_ADDRESS);
        gyroConfigAddress = _gyroConfigAddress;
    }

    /**
     * @dev Deploys a new `Gyro2CLPPool`.
     */
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
    ) external override returns (address) {
        ExtensibleWeightedPool2Tokens.NewPoolParams memory baseParams = _makePoolParams(name, symbol, tokens, swapFeePercentage, owner, pauseParams);

        Gyro2CLPPool.GyroParams memory params = Gyro2CLPPool.GyroParams({
            baseParams: baseParams,
            sqrtAlpha: sqrts[0],
            sqrtBeta: sqrts[1],
            rateProvider0: rateProviders[0],
            rateProvider1: rateProviders[1],
            capManager: capManager,
            capParams: capParams,
            pauseManager: pauseManager
        });

        return _create(abi.encode(params, gyroConfigAddress));
    }

    function _makePoolParams(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        address owner,
        ILocallyPausable.PauseParams memory pauseParams
    ) internal view returns (ExtensibleWeightedPool2Tokens.NewPoolParams memory) {
        return
            ExtensibleWeightedPool2Tokens.NewPoolParams({
                vault: getVault(),
                name: name,
                symbol: symbol,
                token0: tokens[0],
                token1: tokens[1],
                swapFeePercentage: swapFeePercentage,
                pauseWindowDuration: pauseParams.pauseWindowDuration,
                bufferPeriodDuration: pauseParams.bufferPeriodDuration,
                owner: owner
            });
    }
}
