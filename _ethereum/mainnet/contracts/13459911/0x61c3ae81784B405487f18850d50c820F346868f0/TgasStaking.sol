pragma solidity >=0.5.16;

import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ITomiConfig.sol";
import "./BaseToken.sol";


contract TgasStaking is BaseToken {
    using SafeMath for uint;

    uint public lockTime;
    uint public totalSupply;
    uint public stakingSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public allowance;

    constructor (address _baseToken) public {
        initBaseToken(_baseToken);
    }

    function estimateLocktime(address user, uint _endTime) internal view returns(uint) {
        uint collateralLocktime = allowance[user];

        if (_endTime == 0) {
            uint depositLockTime = block.timestamp + lockTime;
            return depositLockTime > collateralLocktime ? depositLockTime: collateralLocktime;
        }

        return _endTime > collateralLocktime ? _endTime: collateralLocktime; 
    }

    function _add(address user, uint value, uint endTime) internal {
        require(value > 0, 'ZERO');
        balanceOf[user] = balanceOf[user].add(value);
        stakingSupply = stakingSupply.add(value);
        allowance[user] = estimateLocktime(user, endTime);
    }

    function _reduce(address user, uint value) internal {
        require(balanceOf[user] >= value && value > 0, 'TgasStaking: INSUFFICIENT_BALANCE');
        balanceOf[user] = balanceOf[user].sub(value);
        stakingSupply = stakingSupply.sub(value);
    }

    function deposit(uint _amount) external returns (bool) {
        TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
        _add(msg.sender, _amount, 0);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }

    // function onBehalfDeposit(address _user, uint _amount) external returns (bool) {
    //     TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
    //     _add(_user, _amount);
    //     totalSupply = IERC20(baseToken).balanceOf(address(this));
    //     return true;
    // }

    function withdraw(uint _amount) external returns (bool) {
        require(block.timestamp > allowance[msg.sender], 'TgasStaking: NOT_DUE');
        TransferHelper.safeTransfer(baseToken, msg.sender, _amount);
        _reduce(msg.sender, _amount);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }

}