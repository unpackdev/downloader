// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC3525Upgradeable.sol";
import "./BaseSFTConcreteUpgradeable.sol";
import "./IMultiRechargeableConcrete.sol";

abstract contract MultiRechargeableConcrete is IMultiRechargeableConcrete, BaseSFTConcreteUpgradeable {
	mapping(uint256 => SlotRechargeInfo) private _slotRechargeInfos;
	mapping(uint256 => TokenClaimInfo) private _tokenClaimInfos;

	function rechargeOnlyDelegate(uint256 slot_, address currency_, uint256 rechargeAmount_) external payable virtual override onlyDelegate {
		require(currency_ == _currency(slot_), "MultiRechargeableConcrete: invalid currency");
		_slotRechargeInfos[slot_].rechargedAmount += rechargeAmount_;
	}

	function mintOnlyDelegate(uint256 /** tokenId_ */, uint256 slot_, uint256 value_) external virtual override onlyDelegate {
		require(_slotRechargeInfos[slot_].rechargedAmount == 0, "MultiRechargeableConcrete: already recharged");
		_slotRechargeInfos[slot_].totalValue += value_;
	}

	function claimOnlyDelegate(uint256 tokenId_, address currency_, uint256 amount_) external virtual override onlyDelegate {
		uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
		require(currency_ == _currency(slot), "MultiRechargeableConcrete: currency not supported");

		uint256 claimable = claimableAmount(tokenId_);
		require(amount_ <= claimable, "MultiRechargeableConcrete: insufficient amount to claim");
		_tokenClaimInfos[tokenId_].claimedAmount += amount_;
	}

	function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromBalance_, uint256 transferValue_) external virtual override onlyDelegate {
		uint256 transferClaimedAmount = (transferValue_ * _tokenClaimInfos[fromTokenId_].claimedAmount) / fromBalance_;
		_tokenClaimInfos[fromTokenId_].claimedAmount -= transferClaimedAmount;
		_tokenClaimInfos[toTokenId_].claimedAmount += transferClaimedAmount;
	}

	function claimableAmount(uint256 tokenId_) public view virtual override returns (uint256) {
		uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
		uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);

		SlotRechargeInfo storage slotRechargeInfo = _slotRechargeInfos[slot];
		TokenClaimInfo storage tokenClaimInfo = _tokenClaimInfos[tokenId_];
		return (balance * slotRechargeInfo.rechargedAmount) / slotRechargeInfo.totalValue - tokenClaimInfo.claimedAmount;
	}

	function totalValue(uint256 slot_) public view override returns (uint256) {
		return _slotRechargeInfos[slot_].totalValue;
	}
	function rechargedAmount(uint256 slot_) public view override returns (uint256) {
		return _slotRechargeInfos[slot_].rechargedAmount;
	}
	function claimedAmount(uint256 tokenId_) public view override returns(uint256) {
		return _tokenClaimInfos[tokenId_].claimedAmount;
	}
	
	function _afterRecharge(uint256 slot_, uint256 value_) internal virtual {}
	function _afterClaim(uint256 tokenId_, uint256 value_) internal virtual {}

	function _currency(uint256 slot_) internal view virtual returns (address);

	uint256[48] private __gap;
}