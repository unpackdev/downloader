//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ClaimVaultLib.sol";
//import "./AccessibleCommon.sol";
//import "./VaultEvent.sol";
//import "./BaseVaultStorage.sol";
import "./VaultClaimStorage.sol";

import "./BaseVault.sol";

import "./console.sol";

contract DesignedVault is BaseVault, VaultClaimStorage {
    using SafeERC20 for IERC20;

    ///@dev constructor
    ///@param _name Vault's name
    ///@param _tos Allocated tos address
    constructor(
        string memory _name,
        address _tos,
        uint256 _inputMaxOnce
    ) {
        name = _name;
        tos = _tos;
        claimer = msg.sender;
        maxInputOnceTime = _inputMaxOnce;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _totalClaims total available claim count
    ///@param _totalTgeCount   total tge count
    ///@param _startTime start time
    ///@param _periodTimesPerClaim period time per claim
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _totalClaims,
        uint256 _totalTgeCount,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    ) external onlyOwner {
        initializeBase(
            _totalAllocatedAmount,
            _totalClaims,
            _totalTgeCount,
            _startTime,
            _periodTimesPerClaim
        );
    }

    ///@dev set claimer
    ///@param _newClaimer new claimer
    function setClaimer(address _newClaimer)
        external
        onlyOwner
        nonZeroAddress(_newClaimer)
        nonSameAddress(claimer, _newClaimer)
    {
        claimer = _newClaimer;

        emit SetNewClaimer(_newClaimer);
    }

    ///@dev allocate amount for each round
    ///@param round  it is the period unit can claim once
    ///@param amount total claimable amount
    function allocateAmount(uint256 round, uint256 amount)
        external
        onlyOwner
        nonZero(round)
        nonZero(amount)
        validTgeRound(round)
    {
        require(
            totalTgeAmount + amount <= totalAllocatedAmount,
            "DesignedVault: exceed total allocated amount"
        );

        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.allocated, "DesignedVault: already allocated");
        tgeinfo.allocated = true;
        tgeinfo.allocatedAmount = amount;
        totalTgeAmount += amount;

        emit AllocatedAmount(round, amount);
    }

    ///@dev start round, Calculate how much the whitelisted people in the round can claim.
    ///@param round  it is the period unit can claim once
    function startRound(uint256 round)
        external
        onlyOwner
        nonZero(round)
        nonZero(totalClaims)
        validTgeRound(round)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(tgeinfo.allocated, "DesignedVault: no allocated");
        require(!tgeinfo.started, "DesignedVault: already started");
        tgeinfo.started = true;
        if (tgeinfo.allocatedAmount > 0 && tgeinfo.whitelist.length > 0)
            tgeinfo.amount = tgeinfo.allocatedAmount / tgeinfo.whitelist.length;
        else tgeinfo.amount = tgeinfo.allocatedAmount;

        emit StartedRound(round);
    }

    ///@dev start round for claimer , The amount charged at one time is determined.
    function start() external onlyOwner nonZero(totalClaims) {
        require(!startedByClaimer, "DesignedVault: already started by claimer");
        for (uint256 i = 1; i <= totalTgeCount; i++) {
            require(
                tgeInfos[i].allocated,
                "DesignedVault: previous round did't be allocated yet."
            );
        }
        startedByClaimer = true;

        if(totalClaims > totalTgeCount) oneClaimAmountByClaimer = (totalAllocatedAmount - totalTgeAmount) / (totalClaims - totalTgeCount);
        else oneClaimAmountByClaimer = 0;

        emit Started();
    }

    ///@dev next claimable start time
    function nextClaimStartTime() external view returns (uint256 nextTime) {
        nextTime = startTime + (periodTimesPerClaim * lastClaimedRound);
        if (endTime < nextTime) nextTime = 0;
    }

    ///@dev next claimable round
    function nextClaimRound() external view returns (uint256 nextRound) {
        nextRound = lastClaimedRound + 1;
        if (totalClaims < nextRound) nextRound = 0;
    }

    ///@dev number of unclaimed
    function unclaimedInfos(address _user)
        external
        view
        returns (uint256 count, uint256 amount)
    {
        count = 0;
        amount = 0;
        if (block.timestamp > startTime) {
            uint256 curRound = currentRound();
            if (_user == claimer) {
                if (curRound > totalTgeCount) {
                    if (lastClaimedRound >= totalTgeCount) {
                        count = curRound - lastClaimedRound;
                    } else {
                        count = curRound - totalTgeCount;
                    }
                }
                if (count > 0) amount = count * oneClaimAmountByClaimer;
            }

            for (uint256 i = 1; i <= totalTgeCount; i++) {
                if (curRound >= i) {
                    ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                    if (tgeinfo.started) {
                        if (
                            tgeinfo.claimedTime[_user].joined &&
                            tgeinfo.claimedTime[_user].claimedTime == 0
                        ) {
                            count++;
                            amount += tgeinfo.amount;
                        }
                    }
                }
            }

        }
    }

    ///@dev claim
    function claim() external {
        uint256 count = 0;
        uint256 amount = 0;
        require(block.timestamp > startTime, "DesignedVault: not started yet");

        uint256 curRound = currentRound();

        if(claimer == msg.sender) {
            if (lastClaimedRound > totalTgeCount) {
                if (lastClaimedRound < curRound) {
                    count = curRound - lastClaimedRound;
                }
            } else {
                if (totalTgeCount < curRound) {
                    count = curRound - totalTgeCount;
                }
            }
            amount = count * oneClaimAmountByClaimer;

            if(amount > 0){
                totalClaimedCountByClaimer++;
                claimedTimesOfRoundByCliamer[curRound] = block.timestamp;
            }
        }

        //===== TGE ROUNDS
        for (uint256 i = 1; i <= totalTgeCount; i++) {
            if (curRound >= i) {
                ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                if (tgeinfo.started  &&
                    tgeinfo.claimedTime[msg.sender].joined &&
                    tgeinfo.claimedTime[msg.sender].claimedTime == 0
                ) {
                    tgeinfo.claimedTime[msg.sender].claimedTime = block.timestamp;
                    tgeinfo.claimedCount++;
                    amount += tgeinfo.amount;
                    count++;
                }
            }
        }

        //=====
        require(amount > 0, "DesignedVault: no claimable amount");
        totalClaimedAmount += amount;
        userClaimedAmount[msg.sender] += amount;

        if(lastClaimedRound < curRound) lastClaimedRound = curRound;

        require(
            IERC20(tos).transfer(msg.sender, amount),
            "DesignedVault: transfer fail"
        );

        emit Claimed(msg.sender, amount, totalClaimedAmount);
    }

}
