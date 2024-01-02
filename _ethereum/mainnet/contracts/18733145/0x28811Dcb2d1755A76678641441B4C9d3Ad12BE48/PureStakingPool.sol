//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Ownable.sol";

contract PureStakingPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 internal immutable stakingToken_;

    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances_;

    event Staked(address indexed user, uint256 amount, uint256 balance);
    event Withdrawn(address indexed user, uint256 amount, uint256 balance);

    constructor(address _stakingToken) public {
        __Ownable_init();
        stakingToken_ = IERC20(_stakingToken);
    }

    // This function allows governance to take unsupported tokens out of the
    // contract, since this one exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously
    // mess up. There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function rescueTokens(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        // cant take staked asset
        require(_token != stakingToken_, "stakingToken_");

        // transfer _to
        _token.safeTransfer(_to, _amount);
    }

    function _stake(address _sender, address _receiver, uint256 _amount) internal {
        require(_amount > 0, "_stake: Cannot stake 0");
        stakingToken_.safeTransferFrom(_sender, address(this), _amount);
        totalSupply_ = totalSupply_.add(_amount);
        balances_[_receiver] = balances_[_receiver].add(_amount);
        emit Staked(_receiver, _amount, balances_[_receiver]);
    }

    function _withdraw(address _sender, uint256 _amount) internal {
        require(_amount > 0, "Cannot withdraw 0");
        totalSupply_ = totalSupply_.sub(_amount);
        balances_[_sender] = balances_[_sender].sub(_amount);
        stakingToken_.safeTransfer(_sender, _amount);
        emit Withdrawn(_sender, _amount, balances_[_sender]);
    }

    function stake(uint256 _amount) external {
        _stake(msg.sender, msg.sender, _amount);
    }

    function stake(address _receiver, uint256 _amount) external {
        _stake(msg.sender, _receiver, _amount);
    }

    function withdraw(uint256 _amount) external {
        _withdraw(msg.sender, _amount);
    }

    function stakingToken() external view returns (IERC20) {
        return stakingToken_;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances_[account];
    }
}
