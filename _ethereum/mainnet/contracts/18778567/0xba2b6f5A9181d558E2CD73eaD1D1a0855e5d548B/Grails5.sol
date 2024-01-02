// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity ^0.8.15;

import "./Address.sol";

import "./IGenArt721CoreContractV3_Mintable.sol";
import "./ArtblocksProjectPoolSellable.sol";

/**
 * @notice Grails V
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract Grails5 is ArtblocksWithMinterFilterV2ProjectPoolSellable {
    using Address for address payable;

    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    uint256 internal immutable _project13ArtblocksProjectId;

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    address payable public primaryReceiver;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    constructor(
        ProjectPoolSellable.Init memory init,
        GenArt721CoreV3_Engine_Flex_PROOF flex_,
        MinterFilterV2 filter_,
        address payable primaryReceiver_,
        uint256 project13ArtblocksProjectId
    ) ArtblocksWithMinterFilterV2ProjectPoolSellable(init, flex_, filter_) {
        primaryReceiver = primaryReceiver_;
        _project13ArtblocksProjectId = project13ArtblocksProjectId;
    }

    /**
     * @inheritdoc ArtblocksProjectPoolSellable
     */
    function _isLongformProject(uint128 projectId) internal view virtual override returns (bool) {
        return projectId == 13;
    }

    function isLongformProject(uint128 projectId) external view returns (bool) {
        return _isLongformProject(projectId);
    }

    /**
     * @inheritdoc ArtblocksProjectPoolSellable
     * @dev This function is tightly coupled to the implementation of `_isLongformProject`. Any changes there MUST be
     * reflected here.
     */
    function _artblocksProjectId(uint128 projectId) internal view virtual override returns (uint256) {
        assert(_isLongformProject(projectId));

        // This is safe since we only have one ArtBlock project.
        return _project13ArtblocksProjectId;
    }

    function artblocksProjectId(uint128 projectId) external view returns (uint256) {
        return _artblocksProjectId(projectId);
    }

    /**
     * @inheritdoc ProjectPoolSellable
     */
    function _numProjects() internal view virtual override returns (uint128) {
        return 18;
    }

    /**
     * @notice Returns the number of projects.
     */
    function numProjects() external view returns (uint128) {
        return _numProjects();
    }

    /**
     * @inheritdoc ProjectPoolSellable
     */
    function _maxNumPerProject(uint128 projectId) internal view virtual override returns (uint64) {
        return [180, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 36, 150, 50, 50, 50, 150][projectId];
    }

    /**
     * @notice Returns the max number of tokens per project.
     */
    function maxNumPerProject(uint128 projectId) external view returns (uint64) {
        return _maxNumPerProject(projectId);
    }

    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        super._handleSale(to, num, data);
        primaryReceiver.sendValue(msg.value);
    }

    /**
     * @notice Set the primary receiver of funds
     */
    function setPrimaryReceiver(address payable newPrimaryReceiver) public onlyRole(DEFAULT_STEERING_ROLE) {
        primaryReceiver = newPrimaryReceiver;
    }
}
