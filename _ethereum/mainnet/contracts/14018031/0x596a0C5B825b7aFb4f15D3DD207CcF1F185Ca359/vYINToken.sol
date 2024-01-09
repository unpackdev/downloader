// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract vYin is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public yinToken;
    address public governance;
    uint256 public constant RATIO = uint256(100);
    mapping(address => uint256) private _yinBalances;
    uint256 private _yinTotalSupply;

    event Stake(address account, uint256 amount);

    constructor(
        address _yinToken,
        address _governance,
        uint256 amount
    ) ERC20("YIN Finance", "vYIN") {
        yinToken = IERC20(_yinToken);
        governance = _governance;
        _mint(governance, amount);
    }

    function yinBalanceOf(address account) public view returns (uint256) {
        return _yinBalances[account];
    }

    function yinTotalSupply() external view returns (uint256) {
        return _yinTotalSupply;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "AM0");
        require(yinToken.balanceOf(msg.sender) >= amount, "AML");
        yinToken.safeTransferFrom(msg.sender, governance, amount);
        _yinBalances[msg.sender] = _yinBalances[msg.sender].add(amount);
        _yinTotalSupply = _yinTotalSupply.add(amount);

        uint256 ratioAmount = amount.div(RATIO);
        _mint(msg.sender, ratioAmount);

        emit Stake(msg.sender, amount);
    }
}
