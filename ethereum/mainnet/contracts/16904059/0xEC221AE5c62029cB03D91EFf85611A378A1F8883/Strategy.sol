// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Ownable.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import "IGenericVault.sol";
import "IStrategy.sol";
import "IRewards.sol";
import "ICvxCrvStaking.sol";
import "IHarvester.sol";

contract stkCvxCrvStrategy is Ownable {
    using SafeERC20 for IERC20;

    address public immutable vault;
    address public harvester;
    address[] public rewardTokens;
    mapping(address => uint256) public rewardTokenStatus;
    ICvxCrvStaking public immutable cvxCrvStaking;
    address private constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;

    uint256 public constant FEE_DENOMINATOR = 10000;

    constructor(address _vault, address _staking) {
        vault = _vault;
        cvxCrvStaking = ICvxCrvStaking(_staking);
    }

    /// @notice Set approvals for the contracts used when swapping & staking
    function setApprovals() public {
        IERC20(CVXCRV_TOKEN).safeApprove(address(cvxCrvStaking), 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            address(cvxCrvStaking),
            type(uint256).max
        );
    }

    /// @notice update the list and status of reward tokens
    /// @param _token - token address
    /// @param _status - 1 for active, else inactive
    function updateRewardToken(address _token, uint256 _status)
        public
        onlyOwner
    {
        require(_status > 0, "can't delete");
        if (rewardTokenStatus[_token] == 0) {
            rewardTokens.push(_token);
        }
        rewardTokenStatus[_token] = _status;
    }

    /// @notice set the strategy's reward weight
    /// @param _weight the desired weight: 0 = full group 0, 10k = full group 1
    function setRewardWeight(uint256 _weight) public onlyVault {
        cvxCrvStaking.setRewardWeight(_weight);
    }

    /// @notice Update the harvester contract
    /// @param _harvester address of the new contract
    function setHarvester(address _harvester) external onlyOwner {
        require(_harvester != address(0));
        harvester = _harvester;
    }

    /// @notice Query the amount currently staked
    /// @return total - the total amount of tokens staked
    function totalUnderlying() public view returns (uint256 total) {
        return cvxCrvStaking.balanceOf(address(this));
    }

    /// @notice Deposits underlying tokens in the staking contract
    function stake(uint256 _amount) public onlyVault {
        cvxCrvStaking.stake(_amount, address(this));
    }

    /// @notice Withdraw a certain amount from the staking contract
    /// @param _amount - the amount to withdraw
    /// @dev Can only be called by the vault
    function withdraw(uint256 _amount) external onlyVault {
        cvxCrvStaking.withdraw(_amount);
        IERC20(CVXCRV_TOKEN).safeTransfer(vault, _amount);
    }

    /// @notice Claim rewards and swaps them to ETH then cvxCRV for restaking
    /// @dev Can be called by the vault only
    /// @param _caller - the address calling the harvest on the vault
    /// @param _minAmountOut -  min amount of LP tokens to receive w/o revert
    /// @param _sweep - whether to retrieve token rewards in strategy contract
    /// @return harvested - the amount harvested
    function harvest(
        address _caller,
        uint256 _minAmountOut,
        bool _sweep
    ) public onlyVault returns (uint256 harvested) {
        // claim rewards to harvester
        cvxCrvStaking.getReward(address(this), harvester);
        // sweep rewards to harvester if needed
        if (_sweep) {
            _sweepRewards();
        }
        // process rewards via harvester
        uint256 _cvxCrvBalance = IHarvester(harvester).processRewards();

        require(_cvxCrvBalance >= _minAmountOut, "slippage");
        // if this is the last call or no CRV
        // no restake & no fees
        if (IGenericVault(vault).totalSupply() == 0 || _cvxCrvBalance == 0) {
            return 0;
        }

        uint256 _stakingAmount = _cvxCrvBalance;
        uint256 _callIncentive = IGenericVault(vault).callIncentive();
        // Deduce and pay out incentive to caller (not needed for final exit)
        if (_callIncentive > 0) {
            uint256 incentiveAmount = (_cvxCrvBalance * _callIncentive) /
                FEE_DENOMINATOR;
            IERC20(CVXCRV_TOKEN).safeTransfer(_caller, incentiveAmount);
            _stakingAmount = _stakingAmount - incentiveAmount;
        }
        // Deduce and pay platform fee
        uint256 _platformFee = IGenericVault(vault).platformFee();
        if (_platformFee > 0) {
            uint256 feeAmount = (_cvxCrvBalance * _platformFee) /
                FEE_DENOMINATOR;
            IERC20(CVXCRV_TOKEN).safeTransfer(
                IGenericVault(vault).platform(),
                feeAmount
            );
            _stakingAmount = _stakingAmount - feeAmount;
        }
        cvxCrvStaking.stake(_stakingAmount, address(this));

        return _stakingAmount;
    }

    function _rescueToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(
            _token != address(cvxCrvStaking),
            "Cannot rescue staking token"
        );
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Transfers an ERC20 stuck in the contract to designated address
    /// @param _token - token address (can not be staking token)
    /// @param _to - address to send token to
    /// @param _amount - amount to transfer
    function rescueToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _rescueToken(_token, _to, _amount);
    }

    /// @notice Retrieves all reward tokens in strategy contract and sends to harvester
    function _sweepRewards() internal {
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            address _token = rewardTokens[i];
            if (rewardTokenStatus[_token] == 1) {
                uint256 _amount = IERC20(_token).balanceOf(address(this));
                if (_amount > 0) {
                    _rescueToken(_token, harvester, _amount);
                }
            }
        }
    }

    modifier onlyVault() {
        require(vault == msg.sender, "Vault calls only");
        _;
    }

    receive() external payable {}
}
