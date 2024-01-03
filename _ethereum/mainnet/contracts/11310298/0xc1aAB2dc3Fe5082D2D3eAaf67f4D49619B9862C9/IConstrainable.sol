pragma solidity 0.6.6;

import "./IConstraintModule.sol";


/**
 * @author Simon Dosch
 * @title IConstrainable
 * @dev Constrainable interface
 */
interface IConstrainable {
	event ModulesByPartitionSet(
		address indexed caller,
		bytes32 indexed partition,
		IConstraintModule[] newModules
	);

	/**
	 * @dev Returns all modules for requested partition
	 * @param partition Partition to get modules for
	 * @return IConstraintModule[]
	 */
	function getModulesByPartition(bytes32 partition)
		external
		view
		returns (IConstraintModule[] memory);

	/**
	 * @dev Sets all modules for partition
	 * @param partition Partition to set modules for
	 * @param newModules IConstraintModule[] array of new modules for this partition
	 */
	function setModulesByPartition(
		bytes32 partition,
		IConstraintModule[] calldata newModules
	) external;
}
