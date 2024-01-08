// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC20.sol";

contract DIASourceNFT is Ownable, ERC1155 {

	address public paymentToken;
	mapping (address => bool) public dataNFTContractAddresses;

	struct SourceNFTMetadata {
		uint256 claimablePayout;
		bool exists;
		address admin;
		uint256[] parentIds;
		uint256[] parentPayoutShares;
		uint256 payoutShare;
		uint256 sourcePoolAmount;
	}

	mapping (uint256 => SourceNFTMetadata) public sourceNfts;

	constructor(address newOwner) ERC1155("https://api.diadata.org/v1/nft/source_{id}.json") {
		transferOwnership(newOwner);
	}

	function getSourcePoolAmount(uint256 sourceNftId) external view returns (uint256) {
		return sourceNfts[sourceNftId].sourcePoolAmount;
	}
	
	function setSourcePoolAmount(uint256 sourceNftId, uint256 newAmount) external {
	    require(sourceNfts[sourceNftId].admin == msg.sender, "Source Pool Amount can only be set by the sART admin");
	    sourceNfts[sourceNftId].sourcePoolAmount = newAmount;
	}

	function addDataNFTContractAddress(address newAddress) onlyOwner external {
		require(newAddress != address(0), "New address is 0.");
		dataNFTContractAddresses[newAddress] = true;
	}

	function removeDataNFTContractAddress(address oldAddress) onlyOwner external {
		require(oldAddress != address(0), "Removed address is 0.");
		dataNFTContractAddresses[oldAddress] = false;
	}

	function updateAdmin(uint256 sourceNftId, address newAdmin) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		sourceNfts[sourceNftId].admin = newAdmin;
	}

	function addParent(uint256 sourceNftId, uint256 parentId, uint256 payoutShare) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		require(sourceNfts[sourceNftId].payoutShare >= payoutShare);
		require(sourceNfts[parentId].exists, "Parent NFT does not exist!");

		sourceNfts[sourceNftId].payoutShare -= payoutShare;
		sourceNfts[sourceNftId].parentPayoutShares.push(payoutShare);
		sourceNfts[sourceNftId].parentIds.push(parentId);
	}

	function updateParentPayoutShare(uint256 sourceNftId, uint256 parentId, uint256 newPayoutShare) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		
		uint256 arrayIndex = (2**256) - 1;
		// find parent ID in payout shares
		for (uint256 i = 0; i < sourceNfts[sourceNftId].parentPayoutShares.length; i++) {
			if (sourceNfts[sourceNftId].parentIds[i] == parentId) {
				arrayIndex = i;
				break;
			}
		}

		uint256 payoutDelta;
		// Check if we can distribute enough payout shares
		if (newPayoutShare >= sourceNfts[sourceNftId].parentPayoutShares[arrayIndex]) {
			payoutDelta = newPayoutShare - sourceNfts[sourceNftId].parentPayoutShares[arrayIndex];
			require(sourceNfts[sourceNftId].payoutShare >= payoutDelta, "Error: Not enough shares left to increase payout!");
			sourceNfts[sourceNftId].payoutShare -= payoutDelta;
			sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] += payoutDelta;
		} else {
			payoutDelta = sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] - newPayoutShare;
			require(sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] >= payoutDelta, "Error: Not enough shares left to decrease payout!");
			sourceNfts[sourceNftId].payoutShare += payoutDelta;
			sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] -= payoutDelta;
		}
	}

	function generateSourceToken(uint256 sourceNftId, address receiver) external onlyOwner {
		sourceNfts[sourceNftId].exists = true;
		sourceNfts[sourceNftId].admin = msg.sender;
		sourceNfts[sourceNftId].payoutShare = 10000;

		_mint(receiver, sourceNftId, 1, ""); 
	}

	function notifyDataNFTMint(uint256 sourceNftId) external {
		require(dataNFTContractAddresses[msg.sender], "notifyDataNFTMint: Only data NFT contracts can be used to mint data NFTs");
		require(sourceNfts[sourceNftId].exists, "notifyDataNFTMint: Source NFT does not exist!");
		for (uint256 i = 0; i < sourceNfts[sourceNftId].parentIds.length; i++) {
			uint256 currentParentId = sourceNfts[sourceNftId].parentIds[i];
			sourceNfts[currentParentId].claimablePayout += (sourceNfts[sourceNftId].parentPayoutShares[i] * sourceNfts[sourceNftId].sourcePoolAmount) / 10000;
		}
		sourceNfts[sourceNftId].claimablePayout += (sourceNfts[sourceNftId].payoutShare * sourceNfts[sourceNftId].sourcePoolAmount) / 10000;
	}

	function claimRewards(uint256 sourceNftId) external {
		address claimer = msg.sender;
		require(sourceNfts[sourceNftId].admin == claimer);
		uint256 payoutDataTokens = sourceNfts[sourceNftId].claimablePayout;

		require(ERC20(paymentToken).transfer(claimer, payoutDataTokens), "Token transfer failed.");
		sourceNfts[sourceNftId].claimablePayout = 0;
	}
}
