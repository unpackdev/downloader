//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TypeCVaultStorage.sol";

import "./ProxyAccessCommon.sol";
import "./ITypeCVault.sol";
import "./VaultStorage.sol";

contract TypeCVault is TypeCVaultStorage, VaultStorage, ProxyAccessCommon, ITypeCVault {
    using SafeERC20 for IERC20;

    event Claimed(
        address indexed caller,
        uint256 amount,
        uint256 totalClaimedAmount
    );

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Vault: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "Vault: zero value");
        _;
    }


    ///@dev constructor
    constructor() {

    }

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _claimCounts total claim Counts
    ///@param _claimTimes each claimTime
    ///@param _claimAmounts each claimAmount
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts
    ) 
        external
        override 
        onlyOwner 
    {
        require(1 ether <= _totalAllocatedAmount, "need the totalAmount 1 token");
        require(_totalAllocatedAmount <= IERC20(token).balanceOf(address(this)), "need to input the token");
        require(set != true, "already set");

        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaimCounts = _claimCounts;
        uint256 i = 0;
        uint256 amountCheck = 0;
        for(i = 0; i < _claimCounts; i++) {
            claimTimes.push(_claimTimes[i]);
            claimAmounts.push(_claimAmounts[i]);
            amountCheck += _claimAmounts[i];
        }
        require(_totalAllocatedAmount == amountCheck, "diff totalAmount");
        set = true;
    }

    function ownerSetting(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts
    ) 
        external 
        override
        onlyProxyOwner 
    {
        require(1 ether <= _totalAllocatedAmount, "need the totalAmount 1 token");
        require(_totalAllocatedAmount <= IERC20(token).balanceOf(address(this)), "need to input the token");

        if(set == true) {
            delete claimTimes;
            delete claimAmounts;
        }
        
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaimCounts = _claimCounts;
        uint256 i;
        uint256 amountCheck = 0;

        for(i = 0; i < _claimCounts; i++) {
            claimTimes.push(_claimTimes[i]);
            claimAmounts.push(_claimAmounts[i]);
            amountCheck += _claimAmounts[i];
        }

        require(_totalAllocatedAmount == amountCheck, "diff totalAmount");
    }

    function changeReceiveAddr(
        address _receive
    ) external override onlyOwner {
        owner = _receive;
    }

    function changeAddr(
        address _token
    ) external override onlyProxyOwner {
        token = _token;
    }

    function currentRound() public override view returns (uint256 round) {
        for(uint256 i = totalClaimCounts; i > 0; i--) {
            if(block.timestamp < claimTimes[0]){
                round = 0;
            } else if(block.timestamp < claimTimes[i-1] && i != 0) {
                round = i-1;
            } else if (block.timestamp > claimTimes[totalClaimCounts-1]) {
                round = totalClaimCounts;
            }
        }
    }

    function calcalClaimAmount(uint256 _round) public override view returns (uint256 amount) {
        uint256 expectedClaimAmount;
        for(uint256 i = 0; i < _round; i++) {
           expectedClaimAmount = expectedClaimAmount + claimAmounts[i];
        }
        if(_round == 1 ) {
            amount = claimAmounts[0] - totalClaimsAmount;
        } else if(totalClaimCounts == _round) {
            amount = totalAllocatedAmount - totalClaimsAmount;
        } else {
            amount = expectedClaimAmount - totalClaimsAmount;
        }
    }

    function claim()
        external
        override
    {
        require(block.timestamp > claimTimes[0], "Vault: not started yet");
        require(totalAllocatedAmount > totalClaimsAmount,"Vault: already All get");

        uint256 curRound = currentRound();

        uint256 amount = calcalClaimAmount(curRound);

        require(IERC20(token).balanceOf(address(this)) >= amount,"Vault: dont have token");
        nowClaimRound = curRound;
        totalClaimsAmount = totalClaimsAmount + amount;
        IERC20(token).safeTransfer(owner, amount);

        emit Claimed(msg.sender, amount, totalClaimsAmount);
    }
}