// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMetadataRegistry {
  struct Document {
		address writer;
		string text;
		uint256 creationTime;
	}

  function tokenIdToDocument(uint256 tokenId, string memory key) external view returns (Document memory);
}