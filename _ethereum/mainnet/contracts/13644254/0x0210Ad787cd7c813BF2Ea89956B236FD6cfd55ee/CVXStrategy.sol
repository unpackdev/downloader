pragma solidity ^0.6.0;

import "./IERC20.sol";

import "./ClaimableStrategy.sol";
import "./ICVXRewards.sol";

/// @title CVXStrategy
/// @notice CVXVault strategy: in CVX out cvxCRV
contract CVXStrategy is ClaimableStrategy {
    ICVXRewards public cvxRewards;

    function configure(
        address _wantAddress,
        address _controllerAddress,
        address _governance,
        address _cvxRewards
    ) public onlyOwner initializer {
        _configure(_wantAddress, _controllerAddress, _governance);
        cvxRewards = ICVXRewards(_cvxRewards);
    }

    /// @dev Function that controller calls
    function deposit() external override onlyController {
        IERC20 wantToken = IERC20(_want);
        uint256 _amount = wantToken.balanceOf(address(this));
        if (wantToken.allowance(address(this), address(cvxRewards)) == 0) {
            wantToken.approve(address(cvxRewards), uint256(-1));
        }
        cvxRewards.stake(_amount);
    }

    function getRewards() external override {
        cvxRewards.getReward(false);
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        cvxRewards.withdraw(_amount, true);
        return _amount;
    }
}
