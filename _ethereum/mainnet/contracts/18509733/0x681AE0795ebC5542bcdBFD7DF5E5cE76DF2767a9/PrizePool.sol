// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

import "Context.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";

contract PrizePool is Context, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant _ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public owner;
    address public rewardToken;

    // Total Point: 1e6
    uint256 public bqlPoint; // BQL Weights
    uint256 public feePoint; // Fee Weights
    uint256 public randomPoint; // Random Weights

    uint256 public randomPool;
    uint256 public totalReward;
    uint256 public totalRandomPool;
    mapping(address => uint256) public userBqlPool;
    mapping(address => uint256) public userFeePool;
    mapping(uint256 => uint256) public epochBqlPool;
    mapping(uint256 => uint256) public epochFeePool;

    event ClaimReward(
        address indexed _receiver,
        uint256 _amount,
        string _type
    );

    event ClaimRandomPool(
        address indexed _receiver,
        uint256 _amount,
        string _network,
        string _txid
    );

    /* solium-disable-next-line */
    receive () external payable {}

    modifier onlyAdmin() {
        require(msg.sender == owner, "only admin is allowed");
        _;
    }

    function initialize(address _owner, address _rewardToken, uint256[] calldata _points) external initializer {
        owner = _owner;
        rewardToken = _rewardToken;

        require(_points[0] + _points[1] + _points[2] <= 1e6, "Point error");
        bqlPoint = _points[0];
        feePoint = _points[1];
        randomPoint = _points[2];
    }

    function setPoolPoint(uint256[] calldata _points) external onlyAdmin {
        require(_points[0] + _points[1] + _points[2] <= 1e6, "Point error");
        bqlPoint = _points[0];
        feePoint = _points[1];
        randomPoint = _points[2];
    }

    function setOwner(address _owner) external onlyAdmin {
        require(_owner != address(0), "Owner can't be zero address");
        owner = _owner;
    }

    function setRewardToken(address _rewardToken) external onlyAdmin {
        require(totalReward == 0, "Reward tokens are fixed");
        rewardToken = _rewardToken;
    }

    function setRewardBalance(address[] calldata _users, uint256[] calldata _amounts, uint8 _type) external onlyAdmin {
        if (_type == 0) {
            for (uint256 i = 0; i < _users.length; i++) {
                userFeePool[_users[i]] = userFeePool[_users[i]].add(_amounts[i]);
            }
        } else if (_type == 1) {
            for (uint256 i = 0; i < _users.length; i++) {
                userBqlPool[_users[i]] = userBqlPool[_users[i]].add(_amounts[i]);
            }
        } else if (_type == 2) {
            for (uint256 i = 0; i < _users.length; i++) {
                userFeePool[_users[i]] = userFeePool[_users[i]].sub(_amounts[i]);
            }
        } else if (_type == 3) {
            for (uint256 i = 0; i < _users.length; i++) {
                userBqlPool[_users[i]] = userBqlPool[_users[i]].sub(_amounts[i]);
            }
        }
    }

    function poolDistribute(uint256 epoch, uint256 amount) external payable {
        require(amount > 0, "Reward token amount can't be zero");
        if (rewardToken == _ZERO_ADDRESS) {
            require(msg.value == amount, "Amount is wrong");
        } else {
            require(IERC20(rewardToken).balanceOf(msg.sender) >= amount, "Amount is wrong");
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        randomPool = randomPool.add(amount.mul(randomPoint).div(1e6));
        totalReward = totalReward.add(amount);
        totalRandomPool = totalRandomPool.add(amount.mul(randomPoint).div(1e6));
        epochBqlPool[epoch] = epochBqlPool[epoch].add(amount.mul(bqlPoint).div(1e6));
        epochFeePool[epoch] = epochFeePool[epoch].add(amount.mul(feePoint).div(1e6));
    }

    function claimRandomPool(address receiver, string calldata network, string calldata txid) external onlyAdmin returns(uint256 amount) {
        require(randomPool > 0, "Random pool is empty");

        amount = randomPool;
        randomPool = 0;

        if (rewardToken == _ZERO_ADDRESS) {
            payable(receiver).transfer(amount);
        } else {
            IERC20(rewardToken).safeTransfer(receiver, amount);
        }

        emit ClaimReward(receiver, amount, "random");
        emit ClaimRandomPool(receiver, amount, network, txid);
    }

    function claimFeeReward() external returns(uint256 amount) {
        uint256 amount = userFeePool[msg.sender];
        require(amount > 0, "No reward for current address");

        userFeePool[msg.sender] = 0;
        if (rewardToken == _ZERO_ADDRESS) {
            require(payable(this).balance >= amount, "Insufficient balance by pool");
            payable(msg.sender).transfer(amount);

        } else {
            require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Insufficient balance by pool");
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        emit ClaimReward(msg.sender, amount, "fee");
    }

    function claimBqlReward() external returns(uint256 amount) {
        uint256 amount = userBqlPool[msg.sender];
        require(amount > 0, "No reward for current address");

        userBqlPool[msg.sender] = 0;
        if (rewardToken == _ZERO_ADDRESS) {
            require(payable(this).balance >= amount, "Insufficient balance by pool");
            payable(msg.sender).transfer(amount);

        } else {
            require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Insufficient balance by pool");
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        emit ClaimReward(msg.sender, amount, "bql");
    }

    function GetInitializeData(address _owner, address _rewardToken, uint256[] calldata _points) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,uint256[])", _owner, _rewardToken, _points);
    }
}
