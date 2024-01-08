// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./IERC721.sol";
import "./IPositionProxy.sol";
import "./CErc20Interface.sol";
import "./IFuseMarginController.sol";
import "./ComptrollerInterface.sol";

/// @author Ganesh Gautham Elango
/// @title Position contract based on DSProxy, to be cloned for each position
contract PositionProxy is IPositionProxy {
    /// @dev Points to immutable FuseMarginController instance
    IFuseMarginController public immutable override fuseMarginController;
    /// @dev FuseMarginController contract ERC721 interface
    IERC721 private immutable fuseMarginERC721;

    /// @param _fuseMarginController Address of FuseMarginController
    constructor(address _fuseMarginController) {
        fuseMarginController = IFuseMarginController(_fuseMarginController);
        fuseMarginERC721 = IERC721(_fuseMarginController);
    }

    /// @dev Fallback for reciving Ether
    receive() external payable {}

    /// @dev Delegate call, to be called only from FuseMargin contracts
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @return Return bytes
    function execute(address _target, bytes memory _data) external payable override returns (bytes memory) {
        require(fuseMarginController.approvedContracts(msg.sender), "PositionProxy: Not approved contract");
        (bool success, bytes memory response) = _target.delegatecall(_data);
        require(success, "PositionProxy: delegatecall failed");
        return response;
    }

    /// @dev Delegate call, to be called only from position owner
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @param tokenId tokenId of this position
    /// @return Return bytes
    function execute(
        address _target,
        bytes memory _data,
        uint256 tokenId
    ) external payable override returns (bytes memory) {
        require(address(this) == fuseMarginController.positions(tokenId), "PositionProxy: Invalid position");
        require(msg.sender == fuseMarginERC721.ownerOf(tokenId), "PositionProxy: Not approved user");
        require(fuseMarginController.approvedConnectors(_target), "PositionProxy: Not valid connector");
        (bool success, bytes memory response) = _target.delegatecall(_data);
        require(success, "PositionProxy: delegatecall failed");
        return response;
    }
}
