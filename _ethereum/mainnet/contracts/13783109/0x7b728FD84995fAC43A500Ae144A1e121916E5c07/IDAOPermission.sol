// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title DAO Permission Model
/// @notice This is the interface used to manage the permissions of the DAO, mainly including the OWNER and MANGER of the DAO.
interface IDAOPermission {
    /// @notice This is the owner of the DAO.
    /// @return The address of the owner of the DAO.
    function owner() external view returns (address);

    function transferOwnership(address payable _newOwner) external;

    function managers() external view returns (address[] memory);

    function isManager(address _address) external view returns (bool);

    /// @notice Add Manager to the DAO.
    /// @dev if the manager is already a manager, nothing will happen.
    /// @param manager The address of the manager.
    function addManager(address manager) external;

    /// @notice Remove Manager from the DAO.
    /// @dev if the manager is not a manager, nothing will happen.
    /// @param manager The address of the manager.
    function removeManager(address manager) external;
}
