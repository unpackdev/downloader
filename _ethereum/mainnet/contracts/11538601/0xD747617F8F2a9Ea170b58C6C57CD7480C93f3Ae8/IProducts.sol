pragma solidity ^0.7.3;

interface IProducts {

	function getMaxLeverage(bytes32 symbol, bool checkDisabled) external view returns (uint256);
	function getFundingRate(bytes32 symbol) external view returns (uint256);
	function getSpread(bytes32 symbol) external view returns (uint256);

}