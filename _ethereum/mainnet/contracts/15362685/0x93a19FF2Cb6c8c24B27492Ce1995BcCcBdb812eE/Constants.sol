// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Constants {
	// uint256 public constant MAX_SUPPLY = 9999;
	uint256 public constant MAX_FREE_MINT_SUPPLY = 7000;
	uint256 public constant MAX_PROOF_MINT_SUPPLY = 1000;
	uint256 public constant MAX_PROJECTPARTY_SUPPLY = 1999;

	// proof config
	// proof NFT is the DIA contract address 
	address public constant PROOF_TOKEN = 0x50a0566425246C8904f0458E6404DEc32F302dfa; 

	// royalty 
	// Address for royalties
	address public constant ROYALTY_WALLET_ADDRESS = 0x86C2A94F4C5e95b114381f9C24E390272A46dCA1; 
	uint96 public constant ROYALTY_BASIS_POINTS = 900;

	// Whitelist signing addresses
	address public constant WHITELISTING_SIGNATURE_ADDRESS = 0x441b289cE6487C72A5a150c6444F66f2c5F22251; 

	// After decentralization
	address public constant DEFAULT_MINT_PROOF_ADDRESS = 0x41d8FfcfdBb32bbf984B952cBe0e658f49109A10;
	address public constant DEFAULT_MINT_PROJECT_PARTY_ADDRESS = 0x4813f9d89B5cc2922f5799A38cCC8aC3D3e459D2;

	// Maximum number of castings at one time
	uint256 public constant MAX_MINT_PER_WALLET = 9;
	// The minimum ETH balance verification in the minter's account is 0.3
	uint256 public constant MIN_ETH_BALANCE = 0.3 ether;

	// The mask is valid for 7 days and turns to timestamp 604800
	uint256 public constant MASK_VALIDITY_TIME = 604800;

	// Basic information of NFT
	string public constant NAME = "GemFi.vip";
	string public constant SYMBOL = "Mask";
	string public constant VERSION = "1.0.0";
	string public constant DESCRIPTION = "Satoshi Mask";

	// The address of the project party casting and partner casting to obtain NFT,
	//   After the contract is released, it is necessary to call the function in the contract to add the address and how many can be minted.


}