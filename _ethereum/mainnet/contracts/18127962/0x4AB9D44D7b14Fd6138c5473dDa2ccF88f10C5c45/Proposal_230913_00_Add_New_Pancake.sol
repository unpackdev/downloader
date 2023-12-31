// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IProposal.sol";
import "./ISingleAssetVault.sol";

/// @title This proposal should be executed on Mainnet and adds new Pancake V3 USDT/TUSD strategy to USDT single asset vault
contract Proposal_230913_00_Add_New_Pancake is IProposal
{
	function execute() external
	{
		ISingleAssetVault sav = ISingleAssetVault(0x85983B29Ee3795559d654cF210a089CD66876fce);
        sav.addVault(0x3BD6b26C7F805E24fCCF8164302b8d72A728Edf7);
	}
}
