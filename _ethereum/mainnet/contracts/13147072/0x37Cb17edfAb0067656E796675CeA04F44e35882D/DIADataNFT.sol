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
	mapping (uint256 => uint) lastClaimPayout;
	bool public exists;
	bool public started;
	bool public genesisPhase;
	uint256 public sourceNFTId;
	mapping (address => uint256) public mintsPerWallet;
	uint256 public maxMintsPerWallet = 3;

	address public paymentToken;
	address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);
	address public mintingPool;
	uint256 public burnAmount;
	uint256 public mintingPoolAmount;

	constructor(address _paymentToken, uint256 _burnAmount, uint256 _mintingPoolAmount, address _mintingPool, address _DIAGenesisMinterAddr, bytes memory metadataURI) ERC1155(string(metadataURI)) {
		require(_paymentToken != address(0), "Payment token address is 0.");
		require(_mintingPool != address(0), "Minting pool address is 0.");
		paymentToken = _paymentToken;
		burnAmount = _burnAmount;
		mintingPoolAmount = _mintingPoolAmount;
		mintingPool = _mintingPool;
		DIAGenesisMinterAddr = _DIAGenesisMinterAddr;
	}

	event NewDataNFTCategory(uint256 sourceNFTId);
	event MintedDataNFT(address owner, uint256 numMinted, uint256 newRank);
	event ClaimedMintingPoolReward(uint256 rank, address claimer);

	function uri(uint256 _id) public view override returns (string memory) {
		if (_id > 10) {
			_id = 10;
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
			_newRank = numMintedNFTs;
		}

		// Check that the wallet is still allowed to mint
		require(mintsPerWallet[_origin] < maxMintsPerWallet, "Sender has used all its mints");

		// Mint data NFT
		_mint(_origin, getErcRank(_newRank), 1, "");

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
		address claimer = msg.sender;
		require(balanceOf(claimer, getErcRank(rank)) > 0);

		uint256 reward = getRewardAmount(rank);

		// transfer reward to claimer
		require(ERC20(paymentToken).transferFrom(mintingPool, claimer, reward));
		lastClaimPayout[rank] = Math.max(NUM_PRIVILEGED_RANKS, numMintedNFTs);
		emit ClaimedMintingPoolReward(rank, claimer);
	}

	function getRewardAmount(uint256 rank) public view returns (uint) {
		require(!genesisPhase);

		//0. get maxNumMinted & numMintedLastClaim
		uint256 maxNumMinted = Math.max(NUM_PRIVILEGED_RANKS, numMintedNFTs);
		uint256 numMintedLastClaim = lastClaimPayout[rank];
		
		// 1. Calculate reward from beginning
		// Never get tetraeder(0), because that is 0 and we don't want to give no reward
		uint256 ownRawWeight = getTetraederNumber(maxNumMinted - rank);
		// Adjust for ranking system in ranks 1-10
		if (rank == 1 || rank == 2) {
			ownRawWeight = (getTetraederNumber(maxNumMinted - 1) + getTetraederNumber(maxNumMinted - 2)) / 2;
		} else if (rank == 3 || rank == 4 || rank == 5) {
			ownRawWeight = (getTetraederNumber(maxNumMinted - 3) + getTetraederNumber(maxNumMinted - 4) + getTetraederNumber(maxNumMinted - 5)) / 3;
		} else if (rank == 6 || rank == 7 || rank == 8 || rank == 9) {
			ownRawWeight = (getTetraederNumber(maxNumMinted - 6) + getTetraederNumber(maxNumMinted - 7) + getTetraederNumber(maxNumMinted - 8) + getTetraederNumber(maxNumMinted - 9)) / 4;
		}
		uint256 sumAllWeights = 0;
		for (uint256 i = 0; i < maxNumMinted; i++) {
			sumAllWeights += getTetraederNumber(i);
		}
		uint256 rawClaim = getPoolAmountAtMint(maxNumMinted) * (ownRawWeight / sumAllWeights);

		// 2. Calculate reward already paid out
		uint256 ownRawWeightLastClaim = getTetraederNumber(numMintedLastClaim - rank);
		uint256 sumAllWeightsLastClaim = 0;
		for (uint256 i = 0; i < numMintedLastClaim; i++) {
			sumAllWeightsLastClaim += getTetraederNumber(i);
		}
		uint256 rawClaimLastClaim = getPoolAmountAtMint(numMintedLastClaim) * (ownRawWeightLastClaim / sumAllWeightsLastClaim);
		return rawClaim - rawClaimLastClaim;
	}

	// Returns the n-th tetraeder number
	function getTetraederNumber(uint256 n) internal pure returns (uint) {
		return (n * (n + 1) * (n + 2))/ 6;
	}

	// Returns the amount of tokens in the minting pool after the n-th minting
	function getPoolAmountAtMint(uint256 n) internal view returns (uint) {
		return mintingPoolAmount * n;
	}

	function getMintedNFTs() external view returns (uint) {
		return numMintedNFTs;
	}

	function getErcRank(uint256 internalRank) public pure returns (uint256) {
		// Translate rank to ERC1155 ID "rank" info
		uint256 ercRank = 0;
		if (internalRank == 0) { ercRank = 0; }
		else if (internalRank == 1 || internalRank == 2) { ercRank = 1; }
		else if (internalRank == 3 || internalRank == 4 || internalRank == 5) { ercRank = 2; }
		else if (internalRank == 6 || internalRank == 7 || internalRank == 8 || internalRank == 9) { ercRank = 3; }
		else { ercRank = 4; }
		return ercRank;
	}
}
