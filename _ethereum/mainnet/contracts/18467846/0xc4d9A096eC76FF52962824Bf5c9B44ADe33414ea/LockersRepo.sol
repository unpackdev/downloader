// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library LockersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Head {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        uint128 value;
    }
    struct Body {
        address counterLocker;
        bytes payload;
    }
    struct Locker {
        Head head;
        Body body;
    }

    struct Repo {
        // hashLock => locker
        mapping (bytes32 => Locker) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    //#################
    //##    Write    ##
    //#################

    function headSnParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            from: uint40(_sn >> 216),
            to: uint40(_sn >> 176),
            expireDate: uint48(_sn >> 128),
            value: uint128(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 headSn) {
        bytes memory _sn = abi.encodePacked(
                            head.from,
                            head.to,
                            head.expireDate,
                            head.value);
        assembly {
            headSn := mload(add(_sn, 0x20))
        }
    }

    function lockPoints(
        Repo storage repo,
        Head memory head,
        bytes32 hashLock
    ) public {
        Body memory body;
        lockConsideration(repo, head, body, hashLock);        
    }

    function lockConsideration(
        Repo storage repo,
        Head memory head,
        Body memory body,
        bytes32 hashLock
    ) public {       
        if (repo.snList.add(hashLock)) {            
            Locker storage locker = repo.lockers[hashLock];      
            locker.head = head;
            locker.body = body;
        } else revert ("LR.lockConsideration: occupied");
    }

    function pickupPoints(
        Repo storage repo,
        bytes32 hashLock,
        string memory hashKey,
        uint caller
    ) public returns(Head memory head) {
        
        bytes memory key = bytes(hashKey);

        require(hashLock == keccak256(key),
            "LR.pickupPoints: wrong key");

        Locker storage locker = repo.lockers[hashLock];

        require(block.timestamp < locker.head.expireDate, 
            "LR.pickupPoints: locker expired");

        bool flag = true;

        if (locker.body.counterLocker != address(0)) {
            require(locker.head.to == caller, 
                "LR.pickupPoints: wrong caller");

            uint len = key.length;
            bytes memory zero = new bytes(32 - (len % 32));

            bytes memory payload = abi.encodePacked(locker.body.payload, len, key, zero);
            (flag, ) = locker.body.counterLocker.call(payload);
        }

        if (flag) {
            head = locker.head;
            delete repo.lockers[hashLock];
            repo.snList.remove(hashLock);
        }
    }

    function withdrawDeposit(
        Repo storage repo,
        bytes32 hashLock,
        uint256 caller
    ) public returns(Head memory head) {

        Locker memory locker = repo.lockers[hashLock];

        require(block.timestamp >= locker.head.expireDate, 
            "LR.withdrawDeposit: locker not expired");

        require(locker.head.from == caller, 
            "LR.withdrawDeposit: wrong caller");

        if (repo.snList.remove(hashLock)) {
            head = locker.head;
            delete repo.lockers[hashLock];
        } revert ("LR.withdrawDeposit: locker not exist");
    }

    //#################
    //##    Read     ##
    //#################

    function getHeadOfLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Head memory head) {
        return repo.lockers[hashLock].head;
    }

    function getLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Locker memory) {
        return repo.lockers[hashLock];
    }

    function getSnList(
        Repo storage repo
    ) public view returns (bytes32[] memory ) {
        return repo.snList.values();
    }
}
