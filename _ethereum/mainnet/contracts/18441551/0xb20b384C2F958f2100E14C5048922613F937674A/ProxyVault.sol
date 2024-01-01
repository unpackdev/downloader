// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFeeReceiver.sol";
import "./ITokenLocker.sol";

//vault that may hold funds/fees/locks etc but is controlled by an outside operator
contract ProxyVault {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address public immutable locker;
    address public operator;
    event WithdrawTo(address indexed user, uint256 amount);
    event SetOperator(address _operator);

    constructor(address _locker, address _owner, address _operator) {
        locker = _locker;
        owner = _owner;
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!op");
        _;
    }

    function setOperator(address _op) external {
        require(msg.sender == owner, "!owner");
        operator = _op;
        emit SetOperator(operator);
    }
    
    function withdrawTo(IERC20 _asset, uint256 _amount, address _to) external onlyOperator{
        _asset.safeTransfer(_to, _amount);
        emit WithdrawTo(_to, _amount);
    }

    function withdrawLocked(uint256 _amount) external onlyOperator{
        //pay penalty and withdraw now
        ITokenLocker(locker).withdrawWithPenalty(_amount);
    }

    function withdrawExpired() external onlyOperator{
        //withdraw all expired locks
        ITokenLocker(locker).withdrawExpiredLocks(0);
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }

}