// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./UtilsReady.sol";
import "./IKeep3rV1.sol";

import "./IKeep3rEscrow.sol";

contract Keep3rEscrow is UtilsReady, IKeep3rEscrow {
    using SafeMath for uint256;

    address governance;
    IKeep3rV1 Keep3rV1;
    IERC20 lpToken;

    constructor(address _governance, address _keep3r, address _lpToken) public UtilsReady() {
        governance = _governance;
        Keep3rV1 = IKeep3rV1(_keep3r);
        lpToken = IERC20(_lpToken);
        _addProtocolToken(_lpToken);
    }

    function isKeep3rEscrow() external pure override returns (bool) { return true; }


    function returnLPsToGovernance() external override onlyGovernor {
        IERC20(lpToken).transfer(governance, IERC20(lpToken).balanceOf(address(this)));
    }

    function addLiquidityToJob(address _liquidity, address _job, uint _amount) external override onlyGovernor {
        lpToken.approve(address(Keep3rV1), _amount);
        Keep3rV1.addLiquidityToJob(_liquidity, _job, _amount);
    }

    function applyCreditToJob(address provider, address _liquidity, address _job) external override onlyGovernor {
        Keep3rV1.applyCreditToJob(provider, _liquidity, _job);
    }

    function unbondLiquidityFromJob(address _liquidity, address _job, uint _amount) external override onlyGovernor {
        Keep3rV1.unbondLiquidityFromJob(_liquidity, _job, _amount);
    }

    function removeLiquidityFromJob(address _liquidity, address _job) external override onlyGovernor {
        Keep3rV1.removeLiquidityFromJob(_liquidity, _job);
    }

}
