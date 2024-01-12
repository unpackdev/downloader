// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./BaseContract.sol";

contract RoyaltyFacet is BaseContract
{
	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		public view virtual returns (address, uint256)
	{
		tokenId;
        uint256 royaltyAmount = (salePrice * getState().royaltyBasisPoints) / 10_000;
        return (getState().royaltyWalletAddress, royaltyAmount);
    }

	function setRoyaltyWallet(address walletAddress)
		public onlyOwner
	{
		getState().royaltyWalletAddress = walletAddress;
	}

	function setRoyaltyBasisPoints(uint96 basisPoints)
		public onlyOwner
	{
		getState().royaltyBasisPoints = basisPoints;
	}


}