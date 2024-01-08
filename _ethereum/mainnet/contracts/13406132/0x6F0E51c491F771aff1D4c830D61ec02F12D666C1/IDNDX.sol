// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IDNDX {
	function withdrawableDividendsOf(address account) external view returns (uint256);

	function withdrawnDividendsOf(address account) external view returns (uint256);

	function cumulativeDividendsOf(address account) external view returns (uint256);

	event DividendsDistributed(address indexed by, uint256 dividendsDistributed);

	event DividendsWithdrawn(address indexed by, uint256 fundsWithdrawn);

  function distribute(uint256) external;

  function distribute() external payable;
}