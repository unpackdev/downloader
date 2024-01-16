// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./StakingV2.sol";
/**
 * @title TokenVesting
 * @dev Vesting for BEP20 compatible token.
 */
contract StakingV2Balancer is Ownable {
    using SafeERC20 for IERC20;

    struct StakingRoute {
        uint256 stakingLevel;
        address stakingAddress;
    }
    StakingRoute[] public allowedStakingInstances;
    mapping(address => bool) public stakingAllowed;

    event StakingInstanceChanged();

    function addStakingInstances(address[] memory stakingInstances, uint256[] memory stakingLevels) public onlyOwner {
        require(stakingInstances.length > 0, 'StakingV2Balancer: staking instances has to have at least one element!');
        require(stakingInstances.length <= 20, 'StakingV2Balancer: staking instances has to have no more than 20 elements!');
        address token = address(StakingV2(stakingInstances[0]).token());

        for (uint i=0; i<allowedStakingInstances.length; ++i) {
            stakingAllowed[allowedStakingInstances[i].stakingAddress] = false;
        }
        delete allowedStakingInstances;

        for (uint i=0; i<stakingInstances.length; ++i) {
            require(stakingAllowed[address(stakingInstances[i])] == false, 'StakingV2Balancer: duplicated instances!');
            require(token == address(StakingV2(stakingInstances[i]).token()),
                'StakingV2Balancer: provided wrong staking!');
            allowedStakingInstances.push(
                StakingRoute({ stakingAddress: address(stakingInstances[i]), stakingLevel: stakingLevels[i] })
            );
            stakingAllowed[address(stakingInstances[i])] = true;
        }
        emit StakingInstanceChanged();
    }

    function reward(IERC20 _token, uint256 _level, uint256 _amount, uint256 _blockRange) public onlyOwner {
        uint256 tokenStaked;
        address addr;

        StakingV2 staking;
        for (uint i=0; i<allowedStakingInstances.length; i++) {
            if (allowedStakingInstances[i].stakingLevel >= _level) {
                addr = allowedStakingInstances[i].stakingAddress;
                staking = StakingV2(addr);
                ( ,, uint256 tokenRealStaked,,,,, ) = staking.poolInfo(0);
                tokenStaked = tokenStaked + tokenRealStaked;
            }
        }
        return (tokenStaked == 0)
            ? rewardEven(_token, _level, _amount, _blockRange)
            : rewardProp(_token, _level, _amount, _blockRange, tokenStaked);
    }

    // consistent interface with rewardProp
    function rewardEven(IERC20 _token, uint256 _level, uint256 _amount, uint256 _blockRange) public onlyOwner {
        uint256 tokenAmount;
        address addr;
        uint256 size;

        StakingV2 staking;
        for (uint i=0; i<allowedStakingInstances.length; i++) {
            if (allowedStakingInstances[i].stakingLevel >= _level) {
                size++;
            }
        }

        if (size == 0) return;

        for (uint i=0; i<allowedStakingInstances.length; i++) {
            if (allowedStakingInstances[i].stakingLevel >= _level) {
                addr = allowedStakingInstances[i].stakingAddress;
                staking = StakingV2(addr);

                tokenAmount = _amount / size;
                _token.safeTransferFrom(address(msg.sender), addr, tokenAmount);
                if (_blockRange > 0) tokenAmount = tokenAmount / _blockRange;
                staking.setTokenPerBlock(_token, tokenAmount, _blockRange);
            }
        }
    }

    // consistent interface with rewardEven
    function rewardProp(IERC20 _token, uint256 _level, uint256 _amount, uint256 _blockRange, uint256 _staked) public onlyOwner {
        require(_staked > 0, 'StakingV2Balancer: divisor needs to be higher than zero!');
        uint256 tokenAmount;
        address addr;

        StakingV2 staking;
        for (uint i=0; i<allowedStakingInstances.length; i++) {
            if (allowedStakingInstances[i].stakingLevel >= _level) {
                addr = allowedStakingInstances[i].stakingAddress;
                staking = StakingV2(addr);
                ( ,, uint256 tokenRealStaked,,,,, ) = staking.poolInfo(0);
                if (tokenRealStaked > 0) {
                    tokenAmount = _amount * tokenRealStaked / _staked;
                    _token.safeTransferFrom(address(msg.sender), addr, tokenAmount);
                    if (_blockRange > 0) tokenAmount = tokenAmount / _blockRange;
                    staking.setTokenPerBlock(_token, tokenAmount, _blockRange);
                }

            }
        }
    }
}
