// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ERC20Staking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Target token for staking
    IERC20 public ERC20;

    constructor(address _ERC20) public {
        ERC20 = IERC20(_ERC20);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
     * @notice Total stake tokens
     * @dev The total of tokens staked for all accounts
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Account staked amount
     * @dev Amount of tokens currently staked
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Stake Token
     * @dev Stakes designated token
     * @param amount Amount of token to stake
     * @return true
     */
    function _stake(uint256 amount) internal virtual returns (bool) {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        ERC20.transferFrom(msg.sender, address(this), amount);

        return true;
    }

    /**
     * @notice Withdraw Token
     * @dev Withdraw designated token
     * @param amount Amount of token to withdraw
     * @return true
     */
    function _withdraw(uint256 amount) internal virtual returns (bool) {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        ERC20.transfer(msg.sender, amount);

        return true;
    }
}
