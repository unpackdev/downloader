//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ClaimVaultLib.sol";

contract BaseVaultStorage {
    uint256 public maxInputOnceTime;
    ///
    string public name;
    ///
    address public tos;

    uint256 public totalAllocatedAmount;
    uint256 public totalClaimedAmount;
    // uint256 public totalClaims;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public periodTimesPerClaim;

    uint256 public totalClaims;
    uint256 public totalTgeCount;
    uint256 public totalTgeAmount;

    /// round => TgeInfo
    mapping(uint256 => ClaimVaultLib.TgeInfo) public tgeInfos;

    mapping(address => uint256) public userClaimedAmount;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "BaseVaultStorage: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "BaseVaultStorage: zero value");
        _;
    }

    modifier nonSame(uint256 _value1, uint256 _value2) {
        require(_value1 != _value2, "BaseVault: same value");
        _;
    }

    modifier nonSameAddress(address _value1, address _value2) {
        require(_value1 != _value2, "BaseVault: same address");
        _;
    }

    modifier validTgeRound(uint256 _round) {
        require(_round <= totalTgeCount, "BaseVault: exceed available round");
        _;
    }

    modifier validMaxInputOnceTime(uint256 _length) {
        require(
            _length > 0 && _length <= maxInputOnceTime,
            "BaseVault: check input count at once time"
        );
        _;
    }
}
