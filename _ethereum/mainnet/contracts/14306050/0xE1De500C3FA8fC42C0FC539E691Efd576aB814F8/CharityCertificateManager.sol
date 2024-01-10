// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ERC165.sol";
import "./Ownable.sol";
import "./ERC721ProjectApproveTransferManager.sol";
import "./ProjectTokenURIManager.sol";

interface IProject {
    function managerSetTokenURIPrefix(string calldata prefix) external;

    function managerSetApproveTransfer(bool enabled) external;

    function managerMintBatch(address[] calldata recipients, string[] calldata uris)
        external
        returns (uint256[] memory tokenIds);
}

/**
 * Implement this if you want your manager to approve a transfer
 */
contract CharityCertificateManager is ERC721ProjectApproveTransferManager, Ownable {
    bool public transferable;
    IProject public project;

    event LogSetTransferable(bool transferable);
    event LogSetTokenURIPrefix(string prefix);

    constructor(address _project) {
        require(_project != address(0), "bad project");
        project = IProject(_project);
        setTransferable(false);
    }

    /**
     * @dev Set whether or not the project will check the manager for approval of token transfer
     */
    function setApproveTransfer(address _project, bool _enabled) public override onlyOwner {
        require(_project == address(project), "bad _project");
        project.managerSetApproveTransfer(_enabled);
    }

    function setTokenURIPrefix(string calldata _tokenURIPrefix) external onlyOwner {
        project.managerSetTokenURIPrefix(_tokenURIPrefix);
        emit LogSetTokenURIPrefix(_tokenURIPrefix);
    }

    function setTransferable(bool _transferable) public onlyOwner {
        transferable = _transferable;
        emit LogSetTransferable(_transferable);
    }

    function mintCertificates(address[] calldata receivers, string[] calldata usernames)
        external
        onlyOwner
        returns (uint256[] memory tokenIds)
    {
        return project.managerMintBatch(receivers, usernames);
    }

    /**
     * @dev Called by project contract to approve a transfer
     */
    function approveTransfer(
        address from,
        address, /* to */
        uint256 /* tokenId */
    ) external view override returns (bool) {
        if (from == address(0)) {
            return true;
        }
        return transferable;
    }
}
