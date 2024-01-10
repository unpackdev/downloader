//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFactoryElement {
    function factoryCreated(address _factory, address _owner) external;
    function factory() external returns(address);
    function owner() external returns(address);
}

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
/// @notice a contract factory. Can create an instance of a new contract and return elements from that list to callers
interface IFactory {

    /// @notice a contract instance.
    struct Instance {
        address factory;
        address contractAddress;
    }

    /// @dev emitted when a new contract instance has been craeted
    event InstanceCreated(
        address factory,
        address contractAddress,
        Instance data
    );

    /// @notice a set of requirements. used for random access
    struct FactoryInstanceSet {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Instance[] valueList;
    }

    struct FactoryData {
        FactoryInstanceSet instances;
    }

    struct FactorySettings {
        FactoryData data;
    }

    /// @notice returns the contract bytecode
    /// @return _instances the contract bytecode
    function contractBytes() external view returns (bytes memory _instances);

    /// @notice returns the contract instances as a list of instances
    /// @return _instances the contract instances
    function instances() external view returns (Instance[] memory _instances);

    /// @notice returns the contract instance at the given index
    /// @param idx the index of the instance to return
    /// @return instance the instance at the given index
    function at(uint256 idx) external view returns (Instance memory instance);

    /// @notice returns the length of the already-created contracts list
    /// @return _length the length of the list
    function count() external view returns (uint256 _length);

    /// @notice creates a new contract instance
    /// @param owner the owner of the new contract
    /// @param salt the salt to use for the new contract
    /// @return instanceOut the address of the new contract
    function create(address owner, uint256 salt)
        external
        returns (Instance memory instanceOut);

}
