pragma solidity ^0.6.10;

interface  IGMXReader {
 function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong) external view returns(uint256[] memory);
}
