// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IHotPotV3FundDeployer.sol";
import "./HotPotV3Fund.sol";

contract HotPotV3FundDeployer is IHotPotV3FundDeployer {
    struct Parameters {
        address WETH9;
        address uniswapV3Factory;
        address uniswapV3Router;
        address controller;
        address manager;
        address token;
        bytes descriptor;
        uint lockPeriod;
        uint baseLine;
        uint managerFee;
    }

    /// @inheritdoc IHotPotV3FundDeployer
    Parameters public override parameters;

    /// @dev Deploys a fund with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the fund.
    /// @param controller The controller address
    /// @param manager The manager address of this fund
    /// @param token The local token address
    /// @param descriptor bytes string descriptor, the first 32 bytes manager name + next bytes brief description
    /// @param lockPeriod Fund lock up period
    /// @param baseLine Baseline of fund manager fee ratio
    /// @param managerFee When the ROI is greater than the baseline, the fund manager’s fee ratio
    function deploy(
        address WETH9,
        address uniswapV3Factory,
        address uniswapV3Router,
        address controller,
        address manager,
        address token,
        bytes memory descriptor,
        uint lockPeriod,
        uint baseLine,
        uint managerFee
    ) internal returns (address fund) {
        parameters = Parameters({
            WETH9: WETH9,
            uniswapV3Factory: uniswapV3Factory,
            uniswapV3Router: uniswapV3Router,
            controller: controller,
            manager: manager,
            token: token, 
            descriptor: descriptor,
            lockPeriod: lockPeriod,
            baseLine: baseLine,
            managerFee: managerFee
        });

        fund = address(new HotPotV3Fund{salt: keccak256(abi.encode(manager, token, lockPeriod, baseLine, managerFee))}());
        delete parameters;
    }
}
