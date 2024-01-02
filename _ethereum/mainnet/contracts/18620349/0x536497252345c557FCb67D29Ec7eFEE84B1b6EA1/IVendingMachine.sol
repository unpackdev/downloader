pragma solidity ^0.8.2;

import "IERC1155.sol";

interface IVendingMachine  is IERC1155{

	function NFTMachineFor(uint256 NFTId, address _recipient) external;
}