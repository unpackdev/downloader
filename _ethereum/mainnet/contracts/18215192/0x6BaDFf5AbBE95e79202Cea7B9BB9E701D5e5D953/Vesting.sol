// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint public startTime;
    uint public duration;

    address public treasury;

    mapping(address => uint) public allocation;
    mapping(address => uint) public claimed;

    mapping(address => uint) public tgeAmount;
    mapping(address => bool) public tgeClaimed;

    constructor(IERC20 token_, address treasury_) {
        token = token_;
        treasury = treasury_;
    }

    function setAllocations(
        address[] memory recipients_,
        uint[] memory allocations_
    ) external onlyTreasury {
        for (uint i = 0; i < recipients_.length; i++) {
            uint256 amount = allocations_[i];
            address recipient = recipients_[i];
            tgeAmount[recipient] = amount / 4;
            allocation[recipient] = amount - tgeAmount[recipient];
        }
    }

    function increaseAllocation(
        address recipient_,
        uint amount_
    ) external onlyTreasury {
        tgeAmount[recipient_] += amount_ / 4;
        allocation[recipient_] += amount_ - amount_ / 4;
    }

    function claimTgeAllocation() external {
        require(!tgeClaimed[msg.sender], "LinearVesting: already claimed");
        tgeClaimed[msg.sender] = true;
        token.safeTransfer(msg.sender, tgeAmount[msg.sender]);
    }

    function setStartTime(uint startTime_) external onlyOwner {
        startTime = startTime_;
    }

    function setStartTimeNow() external onlyOwner {
        startTime = block.timestamp;
    }

    function withdraw() external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function setToken(IERC20 token_) external onlyOwner {
        token = token_;
    }

    function claim() external {
        require(block.timestamp >= startTime, "LinearVesting: has not started");
        uint amount = _available(msg.sender);
        token.safeTransfer(msg.sender, amount);
        claimed[msg.sender] += amount;
    }

    function available(address address_) external view returns (uint) {
        return _available(address_);
    }

    function released(address address_) external view returns (uint) {
        return _released(address_);
    }

    function outstanding(address address_) external view returns (uint) {
        return allocation[address_] - _released(address_);
    }

    function _available(address address_) internal view returns (uint) {
        return _released(address_) - claimed[address_];
    }

    function _released(address address_) internal view returns (uint) {
        if (block.timestamp < startTime) {
            return 0;
        } else {
            uint256 baseAllocation = allocation[address_];
            if (block.timestamp > startTime + duration) {
                return baseAllocation;
            } else {
                return
                    (baseAllocation * (block.timestamp - startTime)) / duration;
            }
        }
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    modifier onlyTreasury() {
        require(
            msg.sender == treasury || msg.sender == owner(),
            "Only treasury can call this"
        );
        _;
    }
}
