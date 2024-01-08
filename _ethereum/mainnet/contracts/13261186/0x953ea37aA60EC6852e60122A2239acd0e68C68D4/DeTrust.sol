//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "./IDeTrust.sol";
import "./Initializable.sol";

contract DeTrust is IDeTrust, Initializable {

    uint private trustId;

    /*
      Paid directly would be here.
    */
    mapping(address => uint) private settlorBalance;

    mapping(uint => Trust) private trusts;

    mapping(address => uint[]) private settlorToTrustIds;

    mapping(address => uint[]) private beneficiaryToTrustIds;


    uint private unlocked;

    modifier lock() {
        require(unlocked == 1, 'Trust: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * constructor replaced by initialize with timelock upgrade
     */
    function initialize() external initializer {
        unlocked = 1;
    }

    /**
     * If ppl send the ether to this contract directly
     */
    receive() external payable {
        require(msg.value > 0, "msg.value is 0");
        settlorBalance[msg.sender] += msg.value;
    }

    function getBalance(address account)
        external
        view
        override
        returns (uint balance)
    {
        return settlorBalance[account];
    }

    function sendBalanceTo(address to, uint amount) external override {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        require(payable(to).send(amount), "send balance failed");
    }

    function getTrustListAsBeneficiary(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = beneficiaryToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsBeneficiary = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsBeneficiary[i] = t;
        }
        return trustsAsBeneficiary;
    }

    function getTrustListAsSettlor(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = settlorToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsSettlor = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsSettlor[i] = t;
        }
        return trustsAsSettlor;
    }

    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        override
        lock
        returns (uint tId)
    {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= totalAmount, "balance insufficient");

        settlorBalance[settlor] -= totalAmount;

        return _addTrust(
            name,
            beneficiary,
            settlor,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        override
        lock returns (uint tId)
    {
        uint totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");

        return _addTrust(
            name,
            beneficiary,
            msg.sender,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function setIrrevocable(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        if (!t.revocable) {
            return;
        }
        t.revocable = false;
    }

    function revoke(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        require(t.revocable, "trust irrevocable");
        _deleteTrust(tId, t.beneficiary, t.settlor);

        require(payable(msg.sender).send(totalAmount), "revoke failed");
        emit TrustRevoked(tId);
    }

    function topUp(uint tId) external payable override lock {
        uint amount = msg.value;
        require(amount > 0, "msg.value is 0");
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function topUpFromBalance(uint tId, uint amount) external override lock {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function release(uint tId) external override lock {
        address beneficiary = msg.sender;
        _release(tId, beneficiary, beneficiary);
    }

    function releaseTo(uint tId, address to) external override lock {
        _release(tId, msg.sender, to);
    }

    function releaseAll() external override lock {
        address beneficiary = msg.sender;
        _releaseAll(beneficiary, beneficiary);
    }

    function releaseAllTo(address to) external override lock {
        _releaseAll(msg.sender, to);
    }

    // internal functions

    function _release(uint tId, address beneficiary, address to) internal {
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        require(t.beneficiary == beneficiary, "beneficiary error");
        uint releaseAmount = _releaseTrust(t);
        if (releaseAmount == 0) {
            revert("nothing to release");
        }
        bool isDeleted = (t.totalAmount == 0);
        if (isDeleted) {
            _deleteTrust(tId, t.beneficiary, t.settlor);
            emit TrustFinished(tId);
        }
        require(payable(to).send(releaseAmount), "release failed");
        emit Release(beneficiary, releaseAmount);
    }

    function _releaseAll(address beneficiary, address to) internal {
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        require(trustIds.length > 0, "nothing to release");
        uint i;
        uint j;
        uint totalReleaseAmount;
        uint tId;
        bool isDeleted;
        uint length = trustIds.length;
        for (i = 0; i < length && trustIds.length > 0; i++) {
            tId = trustIds[j];
            Trust storage t = trusts[tId];
            uint releaseAmount = _releaseTrust(t);
            if (releaseAmount != 0) {
                totalReleaseAmount += releaseAmount;
            }
            isDeleted = (t.totalAmount == 0);
            if (isDeleted) {
                _deleteTrust(tId, t.beneficiary, t.settlor);
                emit TrustFinished(tId);
            } else {
                j++;
            }
        }
        if (totalReleaseAmount == 0) {
            revert("nothing to release");
        }

        require(payable(to).send(totalReleaseAmount), "release failed");
        emit Release(beneficiary, totalReleaseAmount);
    }

    function _deleteTrust(uint tId, address beneficiary, address settlor) internal {
        delete trusts[tId];
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        if (trustIds.length == 1) {
            trustIds.pop();
        } else {
            uint i;
            for (i = 0; i < trustIds.length; i++) {
                if (trustIds[i] == tId) {
                    if (i != trustIds.length - 1) {
                        trustIds[i] = trustIds[trustIds.length - 1];
                    }
                    trustIds.pop();
                }
            }
        }
        uint[] storage settlorTIds = settlorToTrustIds[settlor];
        if (settlorTIds.length == 1) {
            settlorTIds.pop();
            return;
        }
        uint k;
        for (k = 0; k < settlorTIds.length; k++) {
            if (settlorTIds[k] == tId) {
                if (k != settlorTIds.length - 1) {
                    settlorTIds[k] = settlorTIds[settlorTIds.length - 1];
                }
                settlorTIds.pop();
            }
        }
    }

    function _addTrust(
        string memory name,
        address beneficiary,
        address settlor,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        internal
        returns (uint _id)
    {
        require(timeInterval != 0, "timeInterval should be positive");
        _id = ++trustId;
        trusts[_id].id = _id;
        trusts[_id].name = name;
        trusts[_id].settlor = settlor;
        trusts[_id].beneficiary = beneficiary;
        trusts[_id].nextReleaseTime = startReleaseTime;
        trusts[_id].timeInterval = timeInterval;
        trusts[_id].amountPerTimeInterval = amountPerTimeInterval;
        trusts[_id].totalAmount = totalAmount;
        trusts[_id].revocable = revocable;

        settlorToTrustIds[settlor].push(_id);
        beneficiaryToTrustIds[beneficiary].push(_id);

        emit TrustAdded(
            name,
            settlor,
            beneficiary,
            _id,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );

        return _id;
    }

    function _releaseTrust(Trust storage t) internal returns (uint) {
        uint nowTimestamp = block.timestamp;
        if (t.nextReleaseTime > nowTimestamp) {
            return 0;
        }
        uint distributionAmount = (nowTimestamp - t.nextReleaseTime) / t.timeInterval + 1;
        uint releaseAmount = distributionAmount * t.amountPerTimeInterval;
        if (releaseAmount >= t.totalAmount) {
            releaseAmount = t.totalAmount;
            t.totalAmount = 0;
        } else {
            t.totalAmount -= releaseAmount;
            t.nextReleaseTime += distributionAmount * t.timeInterval;
        }
        emit TrustReleased(t.id, t.beneficiary, releaseAmount, t.nextReleaseTime);
        return releaseAmount;
    }

}
