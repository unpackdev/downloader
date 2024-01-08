// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public share; //LIFT
    address public control; //CTRL

    uint256 private _totalSupplyShare;
    uint256 private _totalSupplyControl;

    mapping(address => uint256) private _shareBalances;
    mapping(address => uint256) private _controlBalances;

    function gettotalSupplyShare() public view returns (uint256) {
        return _totalSupplyShare;
    }

    function gettotalSupplyControl() public view returns (uint256) {
        return _totalSupplyControl;
    }

    function getbalanceOfShare(address account) public view returns (uint256) {
        return _shareBalances[account];
    }

    function getbalanceOfControl(address account) public view returns (uint256) {
        return _controlBalances[account];
    }

    function settotalSupplyShare(uint256 amount) internal {
        _totalSupplyShare = amount;
    }

    function setbalanceOfShare(address account, uint256 amount) internal {
        _shareBalances[account] = amount;
    }

    function stakeShare(uint256 amount) public virtual {        
        stakeShareForThirdParty(msg.sender, msg.sender, amount);
    }
 
    function stakeShareForThirdParty(address staker, address from, uint256 amount) public virtual {
        _totalSupplyShare = _totalSupplyShare.add(amount);
        _shareBalances[staker] = _shareBalances[staker].add(amount);
        IERC20(share).safeTransferFrom(from, address(this), amount);
    }

    function stakeControl(uint256 amount) public virtual {
        stakeControlForThirdParty(msg.sender, msg.sender, amount);
    }    

    function stakeControlForThirdParty(address staker, address from, uint256 amount) public virtual {
        _totalSupplyControl = _totalSupplyControl.add(amount);
        _controlBalances[staker] = _controlBalances[staker].add(amount);
        IERC20(control).safeTransferFrom(from, address(this), amount);
    }

    function withdrawControl(uint256 amount) public virtual {
        uint256 stakerBalance = _controlBalances[msg.sender];
        require(
            stakerBalance >= amount,
            'Boardroom: withdraw request greater than staked amount'
        );
        _totalSupplyControl = _totalSupplyControl.sub(amount);
        _controlBalances[msg.sender] = stakerBalance.sub(amount);
        IERC20(control).safeTransfer(msg.sender, amount);
    }
}