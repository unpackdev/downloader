// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICloneFactoryV2 {
    /// @notice New Implementation Event
    /// @param implementation Address of the implementation
    /// @param creator Address of the creator
    /// @return index Index inside implementations array (starts at 0)
    event ImplementationNew(address indexed implementation, address indexed creator, uint256 index);

    /// @notice Set Template Event
    /// @param templateName Name of the template
    /// @param template Address of the template
    event TemplateSet(string indexed templateName, address indexed template);

    /// @notice Set Template
    /// @param templateName Name of the template
    /// @param template Address of the template
    function templateSet(string calldata templateName, address template) external;

    /// @notice Add Implementation
    /// @param implementationToAdd Addresses of implementations to add
    function implementationsAdd(address[] calldata implementationToAdd) external;

    /// @notice Get Template
    /// @param templateName Name of the template
    /// @param template Address of the template
    function templates(string calldata templateName) external view returns (address template);

    /// @notice Count Implementations
    /// @return count Number of implementations
    function implementationsCount() external view returns (uint256 count);

    /// @notice Get Implementation from Implementations array
    /// @param index Index of implementation
    /// @return implementation Address of implementation
    function implementations(uint256 index) external view returns (address implementation);
}
