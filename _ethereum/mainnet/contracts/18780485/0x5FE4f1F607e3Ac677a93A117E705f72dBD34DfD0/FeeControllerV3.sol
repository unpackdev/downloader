// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./FeeControllerV3I.sol";

//todo stew this should be an upgradeable contract so that all our configurations can be maintained across versions.

/// @notice Fee configuration for a FundingCollection
contract FeeControllerV3 is FeeControllerV3I, Ownable {

    uint256 private openEditionFee;
    uint256 private adminAirdropFee;
    uint256 private paidMintFeeBp; // basis points out of 10000
    uint256 private minimumPriceForScalingFee;
    address private feePayoutAddress; // lore fees go here
    mapping(address => uint256) public feeDiscountsBp;
    uint256 private feeSplitToCreatorBp;
    mapping(address => uint256) public feeSplitToCreatorOverrideBp;

    constructor(address owner, address _feePayoutAddress) {
        _transferOwnership(owner);
        openEditionFee = 0.000777 ether;
        paidMintFeeBp = 250;//2.5%
        minimumPriceForScalingFee = 0.03108 ether;
        feePayoutAddress = _feePayoutAddress;
        feeSplitToCreatorBp = 5714;
        adminAirdropFee = 0.000777 ether;
    }

    function setPaidMintFeeBp(uint256 _paidMintFeeBp) external onlyOwner {
        paidMintFeeBp = _paidMintFeeBp;
    }

    function setOpenEditionFee(uint256 _openEditionFee) external onlyOwner {
        openEditionFee = _openEditionFee;
    }

    function setAdminAirdropFee(uint256 _adminAirdropFee) external onlyOwner {
        adminAirdropFee = _adminAirdropFee;
    }

    function setMinimumPriceForScalingFee(uint256 _minimumPriceForScalingFee) external onlyOwner {
        minimumPriceForScalingFee = _minimumPriceForScalingFee;
    }

    // 50% = 5000
    function setFeeDiscountBp(address nft, uint256 discountBp) external onlyOwner {
        feeDiscountsBp[nft] = discountBp;
    }

    function setFeePayoutAddress(address _feePayoutAddress) external onlyOwner {
        feePayoutAddress = _feePayoutAddress;
    }

    function setFeeSplitToCreatorBp(uint256 _feeSplitToCreatorBp) external onlyOwner {
        require(_feeSplitToCreatorBp <= 10000, "FeeController: _feeSplitToCreatorBp must be <= 10000");
        feeSplitToCreatorBp = _feeSplitToCreatorBp;
    }

    function setFeeSplitToCreatorOverrideBp(address nft, uint256 _feeSplitToCreatorOverrideBp) external onlyOwner {
        require(_feeSplitToCreatorOverrideBp <= 10000, "FeeController: feeSplitToCreatorOverrideBp must be <= 10000");
        feeSplitToCreatorOverrideBp[nft] = _feeSplitToCreatorOverrideBp;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    function getPaidMintFeeBp(address nft) external view returns (uint256){
        uint256 discountBp = feeDiscountsBp[nft];

        if (discountBp > 0) {
            return paidMintFeeBp * discountBp / 10_000;
        }
        return paidMintFeeBp;
    }

    function getMintFee(address nft, uint256 price, uint256 quantity) external view returns (uint256){
        uint256 discountBp = feeDiscountsBp[nft];
        uint256 fee;
        uint256 totalPrice = price * quantity;
        if (totalPrice <= minimumPriceForScalingFee) {
            fee = openEditionFee * quantity;
        } else {
            fee = paidMintFeeBp * totalPrice / 10_000;
        }
        if (discountBp > 0) {
            return fee * discountBp / 10_000;
        }
        return fee;
    }

    function getMinimumPriceForScalingFee() external view returns (uint256){
        return minimumPriceForScalingFee;
    }

    function getFeePayoutAddress() external view returns (address) {
        return feePayoutAddress;
    }

    function getFeeSplitToCreatorBp() external view returns (uint256) {
        return feeSplitToCreatorBp;
    }

    function getFeeSplitToCreator(address nft, uint256 fee) external view returns (uint256) {
        uint256 overrideBp = feeSplitToCreatorOverrideBp[nft];
        if (overrideBp > 0) {
            return fee * overrideBp / 10_000;
        }
        return fee * feeSplitToCreatorBp / 10_000;
    }
}
