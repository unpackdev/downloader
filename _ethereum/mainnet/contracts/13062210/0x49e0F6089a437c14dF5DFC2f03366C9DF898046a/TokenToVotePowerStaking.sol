// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./SafeMath.sol";

/// @title ERC20 token staking to receive voting power
/// @notice This contracts allow to get voting power for DAO voting
/// @dev Voting power non-transferable, user can't send or receive it from another user, only get it from staking.
contract TokenToVotePowerStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Token which can be staked in exchange for voting power
    IERC20 internal stakingToken;
    /// @dev Total amount of the voting power in the system
    uint256 private _totalSupply;
    /// @dev Voting power balances
    mapping(address => uint256) private _balances;

    /// @notice Returns staking token address
    /// @return _stakingToken - staking token address
    function getStakingToken() external view returns(IERC20 _stakingToken){
        return stakingToken;
    }

    /// @notice Contract constructor
    /// @param _stakingToken Sets staking token
    constructor(IERC20 _stakingToken) public {
        stakingToken = _stakingToken;
    }

    /// @notice Returns amount of the voting power in the system
    /// @dev Returns _totalSupply variable
    /// @return Voting power amount
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns account's voting power balance
    /// @param account The address of the user
    /// @return Voting power balance of the user
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice Stakes token and adds voting power (with a 1:1 ratio)
    /// @dev Token amount must be approved to this contract before staking.
    /// @param amount Amount to stake
    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Withdraws token and subtracts voting power (with a 1:1 ratio)
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }
}
