// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract LockerFactory is Ownable {
    CloneFactory public immutable CLONE_CONTRACT;
    Locker public immutable LOCKER;
    IERC20 public immutable MFT;
    uint256 public counter;
    mapping(uint256 => address) public lockers;
    struct LockInfo {
        uint256 amount;
        uint256 unlockDate;
    }
    constructor(address mft_) {
        MFT = IERC20(mft_);
        CLONE_CONTRACT = new CloneFactory();
        LOCKER = new Locker(address(this));
    }

    function batchLock(LockInfo[] calldata _lokers) public onlyOwner {
        for (uint256 i = 0; i < _lokers.length; i++) {
            address locker = CLONE_CONTRACT.createClone(address(LOCKER));
            MFT.transferFrom(msg.sender, locker, _lokers[i].amount);
            Locker(locker).init(address(MFT), _lokers[i].amount, _lokers[i].unlockDate);
            lockers[counter] = locker;
            counter++;
        }
    }

    function claim(uint256 _id) public onlyOwner {
        Locker(lockers[_id]).claim(msg.sender);
    }

    function getLocker(uint256 _id) view public returns(LockInfo memory) {
        LockInfo memory info;
        info.amount = MFT.balanceOf(lockers[_id]);
        info.unlockDate = Locker(lockers[_id]).UNLOCK_DATE();
        return info;
    }
}

contract Locker {
    address public immutable FACTORY;
    IERC20 public MFT;
    uint256 public UNLOCK_DATE;
    bool public isInitialized;

    constructor(address factory_) {
        FACTORY = factory_;
    }

    function init(address mft_, uint256 amount_, uint256 unlockDate_) public {
        require(!isInitialized, "Already initialized");
        require(msg.sender == FACTORY, "Not Factory");
        require(IERC20(mft_).balanceOf(address(this)) == amount_, "Locked Balance Insufficient");
        MFT = IERC20(mft_);
        UNLOCK_DATE = unlockDate_;
        isInitialized = true;
    }

    function claim(address _to) public {
        require(isInitialized, "Not initialized");
        require(msg.sender == FACTORY, "Not Factory");
        require(block.timestamp >= UNLOCK_DATE, "Lock period active");
        uint256 amount = MFT.balanceOf(address(this));
        MFT.transfer(_to, amount);
    }
}

contract CloneFactory {
    function createClone(address target) public returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}
