// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// interface
import "./IFirstPhase.sol";
import "./IERC20.sol";

// library
import "./SafeERC20.sol";
import "./Release.sol";
import "./Time.sol";

// contracts
import "./Operation.sol";
import "./DateTime.sol";

contract FirstPhase is IFirstPhase, Operation, DateTime {
    using SafeERC20 for IERC20;

    using Time for Time.Timestamp;
    Time.Timestamp private _timestamp;

    using Release for Release.Data;
    mapping(address => Release.Data) private _release;

    IERC20 public immutable Token;

    uint256 public immutable TotalMonth;

    constructor(
        address e,
        uint256 total_month,
        address[2] memory owners
    ) payable Ownables(owners) {
        Token = IERC20(e);
        TotalMonth = total_month;
    }

    uint256 private locked;
    modifier lock() {
        require(locked == 0, "FirstPhase: LOCKED");
        locked = 1;
        _;
        locked = 0;
    }

    modifier Authorization(bytes32 opHash) {
        _checkAuthorization(opHash);
        _;
    }

    function getRecordHash(
        address account,
        uint256 amount,
        uint16 lockMon
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount, lockMon));
    }

    function getRecordBatchHash(
        address[] memory accounts,
        uint256[] memory amounts,
        uint16[] memory lockMons
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(accounts, amounts, lockMons));
    }

    function record(
        address account,
        uint256 amount,
        uint16 lockMon
    ) public lock Authorization(getRecordHash(account, amount, lockMon)) {
        _record(account, amount, lockMon);
        emit Record(account, amount);
    }

    function recordBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        uint16[] memory lockMons
    ) public lock Authorization(getRecordBatchHash(accounts, amounts, lockMons)) {
        uint256 aci = accounts.length;
        require(aci == accounts.length && aci == lockMons.length, "FirstPhase: data is not legitimate");
        for (uint256 i = 0; i < aci; i++) {
            _record(accounts[i], amounts[i], lockMons[i]);
        }
        emit Records(accounts, amounts);
    }

    function withdraw() public lock {
        _withdraw(_msgSender());
    }

    function withdrawWith(address account) public lock {
        _withdraw(account);
    }

    function _record(
        address account,
        uint256 amount,
        uint16 lockMon
    ) private {
        _release[account]._record(amount, _timestamp._getCurrentTime(), lockMon, _msgSender());
    }

    function _withdraw(address account) private {
        uint256 currentDay = _timestamp._getCurrentTime();
        uint256 amount = _calculate(account, currentDay);
        require(amount > uint256(0), "FirstPhase: insufficient available assets");
        _release[account]._withdraw(amount, currentDay, account);
        Token.safeTransfer(account, amount);
        emit Withdraw(account, amount);
    }

    function _calculate(address account, uint256 currentDay) private returns (uint256) {
        uint256 len = _release[account]._deposits.length;
        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 diff_month = differenceSeveralMonths(currentDay, _release[account]._recent_timemap);
            (uint256 amount, bool finish) = _release[account]._calculateRelease(diff_month, TotalMonth, i);
            if (amount == 0) continue;
            _release[account]._extract(i, amount);
            if (finish) _release[account]._finish(i);
            total += amount;
        }
        return total;
    }

    function setTestTime(uint256 test_time) external onlyOwner {
        _timestamp._setCurrentTime(test_time);
    }

    function getTime() public view returns (uint256) {
        return _timestamp._getCurrentTime();
    }
}
