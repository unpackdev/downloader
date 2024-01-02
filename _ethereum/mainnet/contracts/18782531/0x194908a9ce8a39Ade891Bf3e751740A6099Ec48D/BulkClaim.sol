// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface smurfcatNFT {
	function claim(address _account, uint256 _tokens, bytes32[] calldata _proof) external;
	function hasFreeMinted(address _user) external view returns (bool);
}

contract BulkClaim {
	
	smurfcatNFT constant public NFT = smurfcatNFT(0x1687d6c8b66a3ba2C0dfA08067fBa2CAFD6D370f);

	function bulkClaim(address[] calldata _accounts, uint256[] calldata _tokens, bytes32[][] calldata _proofs) external {
		require(_accounts.length == _tokens.length && _tokens.length == _proofs.length);
		for (uint256 i = 0; i < _accounts.length; i++) {
			if (!NFT.hasFreeMinted(_accounts[i])) {
				NFT.claim(_accounts[i], _tokens[i], _proofs[i]);
			}
		}
	}
}