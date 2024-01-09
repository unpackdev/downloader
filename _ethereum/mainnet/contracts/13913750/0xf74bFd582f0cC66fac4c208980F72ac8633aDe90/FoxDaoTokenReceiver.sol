// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract FoxDaoTokenReceiver is Ownable {

    using SafeMath for uint256;

    struct TransferInfo {
        uint256 index;
        address account;
        uint256 amount;
        uint256 eta;
    }

    uint256 public constant delay = 86400;

    bool public initialized = false;
    uint256 public index = 0;
    address public token;

    mapping(uint256 => TransferInfo) public queue;

    event TokenSet(address newToken);
    event QueueTransfer(uint256 index, address account, uint256 amount, uint256 eta);
    event ExecTransfer(uint256 index, address account, uint256 amount);
    event CancelTransfer(uint256 index, address account, uint256 amount);

    function initialize(address _token) external onlyOwner {
        require(!initialized, "FoxDaoTokenReceiver: Initialized");
        initialized = true;
        token = _token;
        emit TokenSet(_token);
    }

    function queueTransfer(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        index = index + 1;
        require(IERC20(token).balanceOf(address(this)) >= _amount, "FoxDaoTokenReceiver: Insufficient token");

        uint256 eta = block.timestamp.add(delay);
        queue[index] = TransferInfo(
            index, _account, _amount, eta
        );
        emit QueueTransfer(index, _account, _amount, eta);
        return index;
    }

    function execTransfer(uint256 _index, address _account, uint256 _amount) external onlyOwner {
        require(_index <= index, "FoxDaoTokenReceiver: Invalid index");

        TransferInfo memory info = queue[_index];
        require(info.account != address(0), "FoxDaoTokenReceiver: Transaction has been executed or canceled");
        require(info.account == _account, "FoxDaoTokenReceiver: Invalid account");
        require(info.amount == _amount, "FoxDaoTokenReceiver: Invalid amount");
        require(block.timestamp >= info.eta, "FoxDaoTokenReceiver: Transaction hasn't surpassed time lock");

        IERC20(token).transfer(_account, _amount);
        delete queue[_index];

        emit ExecTransfer(_index, _account, _amount);
    }

    function cancelTransfer(uint256 _index, address _account, uint256 _amount) external onlyOwner {
        require(_index <= index, "FoxDaoTokenReceiver: Invalid index");

        TransferInfo memory info = queue[_index];
        require(info.account != address(0), "FoxDaoTokenReceiver: Transaction has been executed or canceled");
        require(info.account == _account, "FoxDaoTokenReceiver: Invalid account");
        require(info.amount == _amount, "FoxDaoTokenReceiver: Invalid amount");

        delete queue[_index];

        emit CancelTransfer(_index, _account, _amount);
    }
}