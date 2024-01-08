//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEarlyBirdRegistry
/// @author Simon Fremaux (@dievardump)
interface IEarlyBirdRegistry {
    /// @notice allows anyone to register a new project that accepts Early Birds registrations
    /// @param open if the early bird registration is open or only creator can register addresses
    /// @param endRegistration unix epoch timestamp of registration closing
    /// @param maxRegistration the max registration count
    /// @return projectId the project Id (useful if called by a contract)
    function registerProject(
        bool open,
        uint256 endRegistration,
        uint256 maxRegistration
    ) external returns (uint256 projectId);

    /// @notice tells if a project exists
    /// @param projectId project id to check
    /// @return if the project exists
    function exists(uint256 projectId) external view returns (bool);

    /// @notice Helper to paginate all address registered for a project
    /// @param projectId the project id
    /// @param offset index where to start
    /// @param limit how many to grab
    /// @return list of registered addresses
    function listRegistrations(
        uint256 projectId,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory list);

    /// @notice Helper to know how many address registered to a project
    /// @param projectId the project id
    /// @return how many people registered
    function registeredCount(uint256 projectId) external view returns (uint256);

    /// @notice Helper to check if an address is registered for a project id
    /// @param check the address to check
    /// @param projectId the project id
    /// @return if the address was registered as an early bird
    function isRegistered(address check, uint256 projectId)
        external
        view
        returns (bool);

    /// @notice Allows a project creator to add early birds in Batch
    /// @dev msg.sender must be the projectId creator
    /// @param projectId to add to
    /// @param birds all addresses to add
    function registerBatchTo(uint256 projectId, address[] memory birds)
        external;
}
