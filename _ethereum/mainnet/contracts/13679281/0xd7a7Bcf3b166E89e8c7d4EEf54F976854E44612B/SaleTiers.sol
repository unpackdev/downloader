//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract SaleTiers is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint amount;
        uint claimed;
    }

    IERC20 public immutable offeringToken;
    bytes32 public merkleRoot;
    uint public startTime;
    uint public endTime;
    uint public offeringAmount;
    uint public raisingAmount;
    bool public paused;
    bool public finalized;
    uint public totalAmount;
    uint public totalUsers;
    mapping(address => UserInfo) public userInfos;

    event SetAmounts(uint offering, uint raising);
    event SetTimes(uint start, uint end);
    event SetMerkleRoot(bytes32 merkleRoot);
    event SetPaused(bool paused);
    event SetFinalized();
    event Deposit(address indexed user, uint amount);
    event Harvest(address indexed user, uint amount);

    constructor(
        address _offeringToken,
        bytes32 _merkleRoot,
        uint _startTime,
        uint _endTime,
        uint _offeringAmount,
        uint _raisingAmount
    ) Ownable() {
        offeringToken = IERC20(_offeringToken);
        merkleRoot = _merkleRoot;
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        require(_offeringAmount > 0, "offering > 0");
        require(_raisingAmount > 0, "raising > 0");
        require(_startTime > block.timestamp, "start > now");
        require(_startTime < _endTime, "start < end");
        require(_startTime < 1e10, "start time not unix");
        require(_endTime < 1e10, "start time not unix");
        emit SetAmounts(_offeringAmount, _raisingAmount);
    }

    function setAmounts(uint offering, uint raising) external onlyOwner {
      offeringAmount = offering;
      raisingAmount = raising;
      emit SetAmounts(offering, raising);
    }

    function setTimes(uint _startTime, uint _endTime) external onlyOwner {
      startTime = _startTime;
      endTime = _endTime;
      emit SetTimes(_startTime, _endTime);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot(_merkleRoot);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPaused(_paused);
    }

    function setFinalized() external onlyOwner {
        finalized = true;
        emit SetFinalized();
    }

    function getParams() external view returns (uint, uint, uint, uint, uint, bool, bool) {
        return (startTime, endTime, raisingAmount, offeringAmount, totalAmount, paused, finalized);
    }

    function getUserInfo(address _user) public view returns (uint, uint, uint, uint) {
        UserInfo memory userInfo = userInfos[_user];
        uint owed = (userInfo.amount * offeringAmount) / raisingAmount;
        uint claimable = owed / 4;
        if (block.timestamp > endTime + 30 days) { claimable += owed / 4; }
        if (block.timestamp > endTime + 60 days) { claimable += owed / 4; }
        if (block.timestamp > endTime + 90 days) { claimable += owed / 4; }
        return (userInfo.amount, userInfo.claimed, owed, claimable);
    }

    function deposit(uint allocation, bytes32[] calldata merkleProof) public payable nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];

        require(!paused, "paused");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "sale not active");
        require(msg.value > 0, "need amount > 0");
        require(userInfo.amount + msg.value <= allocation, "over allocation");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, allocation));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "invalid proof");

        if (userInfo.amount == 0) {
            totalUsers += 1;
        }
        userInfo.amount = userInfo.amount + msg.value;
        totalAmount = totalAmount + msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function harvest() external nonReentrant {
        (uint contributed, uint claimed, uint total, uint claimable) = getUserInfo(msg.sender);

        require(!paused, "paused");
        require(block.timestamp > endTime, "sale not ended");
        require(finalized, "not finalized");
        require(contributed > 0, "have you participated?");

        uint amount = claimable - claimed;
        require(amount > 0, "no amount available for claiming");

        userInfos[msg.sender].claimed += amount;
        offeringToken.safeTransfer(address(msg.sender), amount);
        emit Harvest(msg.sender, amount);
    }

    function withdrawToken(address token, uint amount) external onlyOwner {
        if (token == address(0)) {
            (bool sent,) = msg.sender.call{value: amount}("");
            require(sent, "failed to send");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }
}
