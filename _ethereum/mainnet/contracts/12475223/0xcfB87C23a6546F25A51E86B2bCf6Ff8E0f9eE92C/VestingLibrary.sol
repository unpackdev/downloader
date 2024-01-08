// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";

library VestingLibrary {
    using SafeMath for uint256;

    uint32 constant internal FULL_PERCENTAGE = 10000;  // 释放比例基数，精确到小数点后两位
    uint8 constant internal CLAIM_TYPE_LINEAR = 0;
    uint8 constant internal CLAIM_TYPE_SINGLE = 1;
    uint8 constant internal CLAIM_TYPE_MULTI = 2;

    struct Vesting {
        uint8 claimType; //0: 线性释放, 1: 单点释放, 2: 多点释放
        uint64 term; // 0 : Non-fixed term , 1 - N : fixed term in seconds
        uint64[] maturities; //到期时间（秒）
        uint32[] percentages;  //到期释放比例
        bool isValid; //是否有效
        uint256 vestingAmount;
        uint256 principal;
        string originalInvestor;
    }

    function mint(
        Vesting storage self,
        uint8 claimType,
        uint64 term,
        uint256 amount,
        uint64[] memory maturities,
        uint32[] memory percentages,
        string memory originalInvestor
    ) internal returns (uint256, uint256) {
        require(! self.isValid, "vesting already exists");
        self.term = term;
        self.maturities = maturities;
        self.percentages = percentages;
        self.claimType = claimType;
        self.vestingAmount = amount;
        self.principal = amount;
        self.originalInvestor = originalInvestor;
        self.isValid = true;
        return (self.vestingAmount, self.principal);
    }

    function claim(Vesting storage self, uint256 amount) internal {
        require(self.isValid, "vesting not exists");
        self.principal = self.principal.sub(amount, "insufficient principal");
    }

    function merge(Vesting storage self, Vesting storage target) internal returns (uint256 mergeVestingAmount, uint256 mergePrincipal) {
        require(self.isValid && target.isValid, "vesting not exists");
        mergeVestingAmount = self.vestingAmount;
        mergePrincipal = self.principal;
        require(mergePrincipal <= mergeVestingAmount, "balance error");
        self.vestingAmount = 0;
        self.principal = 0;
        target.vestingAmount = target.vestingAmount.add(mergeVestingAmount);
        target.principal = target.principal.add(mergePrincipal);
        self.isValid = false;
        return (mergeVestingAmount, mergePrincipal);
    }

    function split(Vesting storage source, Vesting storage create, uint256 amount) internal returns (uint256 splitVestingAmount, uint256 splitPrincipal){
        require(source.isValid, "vesting not exists");
        require(source.principal <= source.vestingAmount, "balance error");
        splitVestingAmount = source.vestingAmount.mul(amount).div(source.principal);
        source.vestingAmount = source.vestingAmount.sub(splitVestingAmount, "split excess vestingAmount");
        source.principal = source.principal.sub(amount, "split excess principal");
        mint(create, source.claimType, source.term, 0, source.maturities, source.percentages, source.originalInvestor);
        create.vestingAmount = splitVestingAmount;
        create.principal = amount;
        return (splitVestingAmount, amount);
    }

    function transfer(Vesting storage source, Vesting storage target, uint256 amount ) internal returns (uint256 transferVestingAmount, uint256 transferPrincipal){
        require(source.isValid, "vesting not exists");
        transferPrincipal = amount;
        transferVestingAmount = source.vestingAmount.mul(transferPrincipal).div(source.principal);
        source.principal = source.principal.sub(transferPrincipal, "transfer excess principal");
        source.vestingAmount = source.vestingAmount.sub(transferVestingAmount, "transfer excess vestingAmount");
        if (! target.isValid) {
            mint(target, source.claimType, source.term, 0, source.maturities, source.percentages, "");
        }
        target.vestingAmount = target.vestingAmount.add(transferVestingAmount);
        target.principal = target.principal.add(transferPrincipal);
        return (transferVestingAmount, transferPrincipal);
    }
}