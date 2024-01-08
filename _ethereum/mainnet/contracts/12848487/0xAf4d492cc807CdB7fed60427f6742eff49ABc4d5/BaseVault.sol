//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ClaimVaultLib.sol";

import "./AccessibleCommon.sol";
import "./BaseVaultStorage.sol";
import "./VaultEvent.sol";

contract BaseVault is BaseVaultStorage, AccessibleCommon, VaultEvent {
    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _totalTgeCount   total tge count
    ///@param _startTime start time
    ///@param _periodTimesPerClaim period time per claim
    function initializeBase(
        uint256 _totalAllocatedAmount,
        uint256 _totalClaims,
        uint256 _totalTgeCount,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    )
        public
        onlyOwner
        nonZero(_totalAllocatedAmount)
        nonZero(_totalClaims)
        nonZero(_startTime)
        nonZero(_periodTimesPerClaim)
    {
        require(
            IERC20(tos).balanceOf(address(this)) >= _totalAllocatedAmount,
            "BaseVault: balanceOf is insuffient"
        );

        require(totalAllocatedAmount == 0, "BaseVault: already initialized");
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaims = _totalClaims;
        totalTgeCount = _totalTgeCount;
        startTime = _startTime;
        periodTimesPerClaim = _periodTimesPerClaim;
        endTime = _startTime + (_periodTimesPerClaim * _totalClaims);
    }

    receive() external payable {
        revert("cannot receive Ether");
    }

    ///@dev set max input at once time of whitelist
    ///@param _maxInputOnceTime  max input at once time
    function setMaxInputOnceTimeWhitelist(uint256 _maxInputOnceTime)
        external
        onlyOwner
        nonZero(_maxInputOnceTime)
        nonSame(maxInputOnceTime, _maxInputOnceTime)
    {
        maxInputOnceTime = _maxInputOnceTime;
    }

    ///@dev Register the white list for the round.
    ///@param round  it is the period unit can claim once
    ///@param users people who can claim in that round
    function addWhitelist(uint256 round, address[] calldata users)
        external
        onlyOwner
        nonZero(round)
        validTgeRound(round)
        validMaxInputOnceTime(users.length)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.started, "BaseVault: already started");

        for (uint256 i = 0; i < users.length; i++) {
            if (
                users[i] != address(0) && !tgeinfo.claimedTime[users[i]].joined
            ) {
                tgeinfo.claimedTime[users[i]].joined = true;
                tgeinfo.whitelist.push(users[i]);
            }
        }

        emit AddedWhitelist(round, users);
    }

    function currentRound() public view returns (uint256 round) {
        if (block.timestamp < startTime) {
            round = 0;
        } else {
            round = (block.timestamp - startTime) / periodTimesPerClaim;
            round++;
        }
    }

    ///@dev Amount that can be withdrawn by the owner
    function availableWithdrawAmount() public view returns (uint256 amount) {
        uint256 balance = IERC20(tos).balanceOf(address(this));
        uint256 remainSendAmount = totalAllocatedAmount - totalClaimedAmount;
        require(balance >= remainSendAmount, "BaseVault: insufficent");
        amount = balance - remainSendAmount;
    }

    ///@dev withdraw to whom
    ///@param to to address to send
    function withdraw(address to) external onlyOwner nonZeroAddress(to) {
        uint256 amount = availableWithdrawAmount();
        require(amount > 0, "BaseVault: no withdrawable amount");
        require(
            IERC20(tos).transfer(to, amount),
            "BaseVault: transfer fail"
        );

        emit Withdrawal(msg.sender, amount);
    }

    ///@dev get Tge infos
    ///@param round  it is the period unit can claim once
    ///@return allocated whether allocated
    ///@return started whether started
    ///@return allocatedAmount allocated amount
    ///@return claimedCount claimed  count
    ///@return amount the claimeable amount by person in TGE period
    ///@return whitelist who can claim in TGE period
    function getTgeInfos(uint256 round)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (
            bool allocated,
            bool started,
            uint256 allocatedAmount,
            uint256 claimedCount,
            uint256 amount,
            address[] memory whitelist
        )
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];

        return (
            tgeinfo.allocated,
            tgeinfo.started,
            tgeinfo.allocatedAmount,
            tgeinfo.claimedCount,
            tgeinfo.amount,
            tgeinfo.whitelist
        );
    }

    ///@dev get the claim info of whitelist's person
    ///@param round  it is the period unit can claim once
    ///@param user person in whitelist
    ///@return joined whether joined
    ///@return claimedTime the claimed time
    function getWhitelistInfo(uint256 round, address user)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (bool joined, uint256 claimedTime)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        if (tgeinfo.claimedTime[user].joined)
            return (
                tgeinfo.claimedTime[user].joined,
                tgeinfo.claimedTime[user].claimedTime
            );
    }

    ///@dev get the total count of whitelist in round
    ///@param round  it is the period unit can claim once
    ///@return total the total count of whitelist in round
    function totalWhitelist(uint256 round)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (uint256 total)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        total = tgeinfo.whitelist.length;
    }
}
