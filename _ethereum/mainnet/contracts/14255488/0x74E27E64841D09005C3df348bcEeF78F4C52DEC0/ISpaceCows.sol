// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISpaceCows {
	function getMintingRate(address _address) external view returns(uint256);
    function mint(address _user, uint256 _tokenId, uint256 _tier, uint256 _rate) external;
}