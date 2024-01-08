//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
//import "./Ownable.sol";
import "./ClaimVaultLib.sol";
import "./BaseVault.sol";
import "./VaultWhitelistStorage.sol";

//import "./console.sol";

contract WhitelistVault is BaseVault, VaultWhitelistStorage {
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
        maxInputOnceTime = _inputMaxOnce;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _totalTgeCount   total tge count
    ///@param _startTime start time
    ///@param _periodTimesPerClaim period time per claim
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _totalTgeCount,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    ) external onlyOwner {

        initializeBase(
            _totalAllocatedAmount,
            _totalTgeCount,
            _totalTgeCount,
            _startTime,
            _periodTimesPerClaim
        );

    }

    ///@dev allocate amount for first round (TGE)
    ///@param amount total claimable amount
    function allocateAmountTGE(uint256 amount)
        external
        onlyOwner
        nonZero(amount)
        validTgeRound(1)
    {
        require(
            totalTgeAmount + amount <= totalAllocatedAmount,
            "WhitelistVault: exceed total allocated amount"
        );
        uint256 round = 1;
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.allocated, "WhitelistVault: already allocated");
        tgeinfo.allocated = true;
        tgeinfo.allocatedAmount = amount;
        totalTgeAmount += amount;
        lastClaimedRound = round;

        if(totalTgeCount > 1 )  allocatedAmountForRound =  (totalAllocatedAmount - amount) / (totalTgeCount - 1);

        emit AllocatedAmount(round, amount);
    }

    ///@dev allocate amount for each round (except TGE)
    ///@param round  it is the period unit can claim once
    function allocateAmountRound(uint256 round)
        internal
        nonZero(lastClaimedRound)
        nonZero(allocatedAmountForRound)
    {
        require(
            round > 1 && round <= totalTgeCount ,
            "WhitelistVault: no available round"
        );

        uint256 calcRound = (block.timestamp - startTime) / periodTimesPerClaim;

        /// It can be set only during each round.
        require(round == calcRound+1, "WhitelistVault: no current round period");


        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.allocated, "WhitelistVault: already allocated");

        uint256 amount = (round - lastClaimedRound) * allocatedAmountForRound;
        tgeinfo.allocated = true;
        tgeinfo.allocatedAmount = amount ;
        totalTgeAmount += amount;
        lastClaimedRound = round;

        emit AllocatedAmount(round, amount);
    }

    ///@dev start round, Calculate how much the whitelisted people in the round can claim.
    function startRound()
        external
        onlyOwner
        nonZero(totalTgeCount)
    {
        uint256 round = currentRound();
        require(round > 0 && round <= totalTgeCount, "WhitelistVault: non-valid round");

        if(round > 1) allocateAmountRound(round);

        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(
            tgeinfo.allocated && tgeinfo.allocatedAmount > 0,
            "WhitelistVault: no allocated"
        );
        require(!tgeinfo.started, "WhitelistVault: already started");
        require(tgeinfo.whitelist.length > 0, "WhitelistVault: no whitelist");

        tgeinfo.started = true;
        tgeinfo.amount = tgeinfo.allocatedAmount / tgeinfo.whitelist.length;

        emit StartedRound(round);
    }

    ///@dev next claimable start time
    function startRoundTime(uint256 round)
        external
        view
        returns (uint256 start)
    {
        if (round > 0 && round <= totalTgeCount)
            start = startTime + (periodTimesPerClaim * (round - 1));
    }

    ///@dev number of unclaimed
    function unclaimedInfos(address _user)
        public
        view
        returns (uint256 count, uint256 amount)
    {
        count = 0;
        amount = 0;
        if (block.timestamp > startTime) {
            uint256 curRound = currentRound();
            for (uint256 i = 1; i <= curRound; i++) {
                if (curRound >= i) {
                    ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                    if (tgeinfo.started &&
                        tgeinfo.claimedTime[_user].joined &&
                        tgeinfo.claimedTime[_user].claimedTime == 0)
                    {
                            count++;
                            amount += tgeinfo.amount;
                    }
                }
            }
        }
    }

    ///@dev number of unclaimed
    function unclaimedInfosDetails(address _user)
        external
        view
        returns (uint256[] memory _rounds, uint256[] memory _amounts)
    {

        (uint256 size,) = unclaimedInfos(_user);
        uint256[] memory counts = new uint256[](size);
        uint256[] memory amounts = new uint256[](size);

        if(size > 0){
            uint256 k = 0;
            if (block.timestamp > startTime) {
                uint256 curRound = currentRound();
                for (uint256 i = 1; i <= curRound; i++) {
                    if (curRound >= i) {
                        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                        if (tgeinfo.started &&
                            tgeinfo.claimedTime[_user].joined &&
                            tgeinfo.claimedTime[_user].claimedTime == 0
                        ) {
                            counts[k] = i;
                            amounts[k] = tgeinfo.amount;
                            k++;
                        }
                    }
                }
            }
        }
        return (counts, amounts);
    }


    ///@dev claim
    function claim() external {

        uint256 amount = 0;
        require(block.timestamp > startTime, "WhitelistVault: not started yet");

        uint256 curRound = currentRound();
        for (uint256 i = 1; i <= curRound; i++) {
            if (curRound >= i) {
                ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                if (tgeinfo.started &&
                    tgeinfo.claimedTime[msg.sender].joined &&
                    tgeinfo.claimedTime[msg.sender].claimedTime == 0
                ) {
                    tgeinfo.claimedTime[msg.sender].claimedTime = block.timestamp;
                    tgeinfo.claimedCount++;
                    amount += tgeinfo.amount;
                }
            }
        }

        require(amount > 0, "WhitelistVault: no claimable amount");
        totalClaimedAmount += amount;

        userClaimedAmount[msg.sender] += amount;

        require(
            IERC20(tos).transfer(msg.sender, amount),
            "WhitelistVault: transfer fail"
        );

        emit Claimed(msg.sender, amount, totalClaimedAmount);
    }
}
