// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "./IFuseMarginController.sol";

/// @author Ganesh Gautham Elango
/// @title Position interface
interface IPositionProxy {
    /// @dev Points to immutable FuseMarginController instance
    function fuseMarginController() external view returns (IFuseMarginController);

    /// @dev Delegate call, to be called only from FuseMargin contracts
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @return Return bytes
    function execute(address _target, bytes memory _data) external payable returns (bytes memory);

    /// @dev Delegate call, to be called only from position owner
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @param tokenId tokenId of this position
    /// @return Return bytes
    function execute(
        address _target,
        bytes memory _data,
        uint256 tokenId
    ) external payable returns (bytes memory);
}
