// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IS7NSAvatar {
	
    function nonces(uint256 _tokenId, address _account) external view returns (uint256);

	/**
       	@notice Mint Avatar to `_beneficiary`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiary			Address of Beneficiary
		@param	_fromID					Start of TokenID
		@param	_amount					Amount of NFTs to be minted
    */
	function print(address _beneficiary, uint256 _fromID, uint256 _amount) external;
	/**
       	@notice Burn Avatars from `msg.sender`
       	@dev  Caller can be ANY
		@param	_ids				A list of `tokenIds` to be burned
		
		Note: MINTER_ROLE is granted a priviledge to burn NFTs
    */
	function burn(uint256[] calldata _ids) external;
}
