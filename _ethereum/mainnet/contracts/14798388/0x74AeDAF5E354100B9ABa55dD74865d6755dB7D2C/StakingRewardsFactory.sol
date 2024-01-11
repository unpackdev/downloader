// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./StakingRewards.sol";
import "./StakingRewardsFactoryInterface.sol";

contract StakingRewardsFactory is Ownable, StakingRewardsFactoryInterface {
    using SafeERC20 for IERC20;

    /// @notice The list of staking rewards contract
    address[] private _stakingRewards;

    /// @notice The staking token - staking rewards contract mapping
    mapping(address => address) private _stakingRewardsMap;

    /**
     * @notice Emitted when a staking rewards contract is deployed
     */
    event StakingRewardsCreated(
        address indexed stakingRewards,
        address indexed stakingToken
    );

    /**
     * @notice Emitted when a staking rewards contract is removed
     */
    event StakingRewardsRemoved(address indexed stakingToken);

    /**
     * @notice Emitted when tokens are seized
     */
    event TokenSeized(address token, uint256 amount);

    /**
     * @notice Return the amount of staking reward contracts.
     * @return The amount of staking reward contracts
     */
    function getStakingRewardsCount() external view returns (uint256) {
        return _stakingRewards.length;
    }

    /**
     * @notice Return all the staking reward contracts.
     * @return All the staking reward contracts
     */
    function getAllStakingRewards() external view returns (address[] memory) {
        return _stakingRewards;
    }

    /**
     * @notice Return the staking rewards contract of a given staking token
     * @param stakingToken The staking token
     * @return The staking reward contracts
     */
    function getStakingRewards(address stakingToken)
        external
        view
        returns (address)
    {
        return _stakingRewardsMap[stakingToken];
    }

    /**
     * @notice Create staking reward contracts.
     * @param stakingTokens The staking token list
     */
    function createStakingRewards(
        address[] calldata stakingTokens,
        address helperContract
    ) external onlyOwner {
        for (uint256 i = 0; i < stakingTokens.length; i++) {
            address stakingToken = stakingTokens[i];
            require(
                _stakingRewardsMap[stakingToken] == address(0),
                "staking rewards contract already exist"
            );

            // Create a new staking rewards contract.
            StakingRewards sr = new StakingRewards(
                stakingToken,
                helperContract
            );
            sr.transferOwnership(msg.sender);

            _stakingRewards.push(address(sr));
            _stakingRewardsMap[stakingToken] = address(sr);
            emit StakingRewardsCreated(address(sr), stakingToken);
        }
    }

    /**
     * @notice Remove a staking reward contract.
     * @param stakingToken The staking token
     */
    function removeStakingRewards(address stakingToken) external onlyOwner {
        require(
            _stakingRewardsMap[stakingToken] != address(0),
            "staking rewards contract not exist"
        );

        for (uint256 i = 0; i < _stakingRewards.length; i++) {
            if (_stakingRewardsMap[stakingToken] == _stakingRewards[i]) {
                _stakingRewards[i] = _stakingRewards[
                    _stakingRewards.length - 1
                ];
                delete _stakingRewards[_stakingRewards.length - 1];
                _stakingRewards.pop();
                break;
            }
        }
        _stakingRewardsMap[stakingToken] = address(0);
        emit StakingRewardsRemoved(stakingToken);
    }

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }
}
