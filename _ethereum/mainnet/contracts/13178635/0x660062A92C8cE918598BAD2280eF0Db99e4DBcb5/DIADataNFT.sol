// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./DIASourceNFT.sol";
import "./Strings.sol";

contract DIADataNFT is Ownable, ERC1155 {

	using Math for uint256;
	using Strings for string;

	address public DIASourceNFTAddr;
	DIASourceNFT public diaSourceNFTImpl = DIASourceNFT(DIASourceNFTAddr);

	address public DIAGenesisMinterAddr;

	uint256 public constant NUM_PRIVILEGED_RANKS = 10;

	uint256 public numMintedNFTs;
	mapping (uint256 => address) rankMinter;
	mapping (uint256 => uint256) rankClaims;
	mapping (uint256 => uint) lastClaimPayout;
	bool public exists;
	bool public started;
	bool public genesisPhase;
	uint256 public sourceNFTId;
	mapping (address => uint256) public mintsPerWallet;
	uint256 public maxMintsPerWallet = 3;

	address public paymentToken;
	address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);
	uint256 public burnAmount;
	uint256 public mintingPoolAmount;

	constructor(address _paymentToken, uint256 _burnAmount, uint256 _mintingPoolAmount, address _DIAGenesisMinterAddr, bytes memory metadataURI) ERC1155(string(metadataURI)) {
		require(_paymentToken != address(0), "Payment token address is 0.");
		paymentToken = _paymentToken;
		burnAmount = _burnAmount;
		mintingPoolAmount = _mintingPoolAmount;
		DIAGenesisMinterAddr = _DIAGenesisMinterAddr;
	}

	event NewDataNFTCategory(uint256 sourceNFTId);
	event MintedDataNFT(address owner, uint256 numMinted, uint256 newRank);
	event ClaimedMintingPoolReward(uint256 rank, address claimer);

	function uri(uint256 _id) public view override returns (string memory) {
		if (_id > NUM_PRIVILEGED_RANKS) {
			_id = NUM_PRIVILEGED_RANKS;
		}
		return string(abi.encodePacked(
			super.uri(_id),
			Strings.uint2str(_id),
			".json"
		));
	}

	function finishGenesisPhase() external onlyOwner {
		genesisPhase = false;
	}

	function startMinting() external onlyOwner {
		started = true;
	}

	function updateMaxMintsPerWallet(uint256 newValue) external onlyOwner {
		maxMintsPerWallet = newValue;
	}

	function updateDIAGenesisMinterAddr(address newAddress) external onlyOwner {
		DIAGenesisMinterAddr = newAddress;
	}

	function setSrcNFT(address _newAddress) external onlyOwner {
		DIASourceNFTAddr = _newAddress;
		diaSourceNFTImpl = DIASourceNFT(DIASourceNFTAddr);
	}

	function generateDataNFTCategory(uint256 _sourceNFTId) external {
		require(diaSourceNFTImpl.balanceOf(msg.sender, _sourceNFTId) > 0);
		exists = true;
		genesisPhase = true;
		started = false;
		sourceNFTId = _sourceNFTId;
		emit NewDataNFTCategory(_sourceNFTId);
	}

	function getRankClaim(uint256 newRank, uint256 max) public view returns (uint256) {
		// 1. Get tetrahedron sum of token units to distribute
		uint256 totalClaimsForMint = getTetrahedronSum(max);
		// 2. Get raw claim from the rank of an NFT
		uint256 rawRankClaim = (getInverseTetrahedronNumber(newRank, max) * mintingPoolAmount) / totalClaimsForMint;
		// 3. Special cases: privileged ranks
		if (newRank == 1 || newRank == 2) {
			return ((getInverseTetrahedronNumber(1, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(2, max) * mintingPoolAmount) / totalClaimsForMint) / 2;
		} else if (newRank == 3 || newRank == 4 || newRank == 5) {
			return ((getInverseTetrahedronNumber(3, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(4, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(5, max) * mintingPoolAmount) / totalClaimsForMint) / 3;
		} else if (newRank == 6 || newRank == 7 || newRank == 8 || newRank == 9) {
			return ((getInverseTetrahedronNumber(6, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(7, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(8, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(9, max) * mintingPoolAmount) / totalClaimsForMint) / 4;
		}
		return rawRankClaim;
	}

	function _mintDataNFT(address _origin, uint256 _newRank) public returns (uint256) {
		require(msg.sender == DIAGenesisMinterAddr, "Only callable from the genesis minter contract");
		// Check that category exists
		require(exists, "_mintDataNFT.Category must exist");
		// Get current number minted of the NFT
		uint256 numMinted = numMintedNFTs;

		if (numMinted < NUM_PRIVILEGED_RANKS) {
			while (rankMinter[_newRank] != address(0)) {
				_newRank = (_newRank + 1) % NUM_PRIVILEGED_RANKS;
			}
		} else {
			_newRank = numMinted;
		}

		for (uint256 i = 0; i < Math.max(NUM_PRIVILEGED_RANKS, numMinted); i++) {
			rankClaims[i] += getRankClaim(i, Math.max(NUM_PRIVILEGED_RANKS, numMinted));
		}

		// Check that the wallet is still allowed to mint
		require(mintsPerWallet[_origin] < maxMintsPerWallet, "Sender has used all its mints");

		// Mint data NFT
		_mint(_origin, _newRank, 1, "");

		// Update data struct
		rankMinter[_newRank] = _origin;
		numMintedNFTs = numMinted + 1;

		// Update Source NFT data
		uint256 currSourceNFTId = sourceNFTId;

		diaSourceNFTImpl.notifyDataNFTMint(currSourceNFTId);

		mintsPerWallet[_origin] += 1;
		emit MintedDataNFT(_origin, numMinted, _newRank);
		return _newRank;
	}

	function getRankMinter(uint256 rank) external view returns (address) {
	    return rankMinter[rank];
	}

	function getLastClaimPayout(uint256 rank) external view returns (uint) {
	    return lastClaimPayout[rank];
	}

	function claimMintingPoolReward(uint256 rank) public {
		require(!genesisPhase);
		address claimer = msg.sender;
		require(balanceOf(claimer, rank) > 0);

		uint256 reward = rankClaims[rank];

		// transfer reward to claimer
		require(ERC20(paymentToken).transfer(claimer, reward));
		// Set claim to 0 for rank
		rankClaims[rank] = 0;
		emit ClaimedMintingPoolReward(rank, claimer);
	}

	function getRewardAmount(uint256 rank) public view returns (uint) {
		return rankClaims[rank];
	}

	// Returns the n-th tetrahedron number
	function getTetrahedronNumber(uint256 n) internal pure returns (uint256) {
		return (n * (n + 1) * (n + 2))/ 6;
	}

	// Returns the n-th tetrahedron number from above
	function getInverseTetrahedronNumber(uint256 n, uint256 max) internal pure returns (uint256) {
		return getTetrahedronNumber(max - n);
	}

	function getTetrahedronSum(uint256 n) internal pure returns (uint256) {
		uint256 acc = 0;
		// Start at 1 so that the last minter doesn't get 0
		for (uint256 i = 1; i <= n; i++) {
			acc += getTetrahedronNumber(i);
		}
		return acc;
	}

	function getMintedNFTs() external view returns (uint) {
		return numMintedNFTs;
	}

	/*function getErcRank(uint256 internalRank) public pure returns (uint256) {
		// Translate rank to ERC1155 ID "rank" info
		uint256 ercRank = 0;
		if (internalRank == 0) { ercRank = 0; }
		else if (internalRank == 1 || internalRank == 2) { ercRank = 1; }
		else if (internalRank == 3 || internalRank == 4 || internalRank == 5) { ercRank = 2; }
		else if (internalRank == 6 || internalRank == 7 || internalRank == 8 || internalRank == 9) { ercRank = 3; }
		else { ercRank = 4; }
		return ercRank;
	}*/
}
