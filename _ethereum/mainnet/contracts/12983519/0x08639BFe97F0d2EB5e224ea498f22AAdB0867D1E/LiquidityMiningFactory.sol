// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./LiquidityMining.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract StakingFactory is Ownable {
    using SafeERC20 for IERC20;
    LiquidityMining[] public liqs;

    function createLiq(
        address _token,
        uint256 _initreward,
        uint256 _startTime,
        uint256 _duration
    ) public virtual onlyOwner returns (LiquidityMining) {
        require(
            _startTime > _duration,
            "start time must be greater than duration"
        );

        LiquidityMining _liq =
            new LiquidityMining(_token, _initreward, _startTime, _duration);

        IERC20 token = IERC20(_token);

        token.approve(address(_liq), _initreward);
        token.transferFrom(msg.sender, address(_liq), _initreward);

        require(
            _initreward == token.balanceOf(address(_liq)),
            "StakingRewards: wrong reward amount supplied"
        );

        _liq.transferOwnership(msg.sender);
        liqs.push(_liq);

        return _liq;
    }

    function getLiqs() public view returns (LiquidityMining[] memory) {
        return liqs;
    }
}
