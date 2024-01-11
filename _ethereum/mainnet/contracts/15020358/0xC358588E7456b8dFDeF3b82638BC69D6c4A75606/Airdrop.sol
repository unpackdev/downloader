//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface ERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

contract Airdrop is Ownable, ReentrancyGuard {
    bool private _paused;

    error ApprovalError();
    error ArraySizeError();
    error PausedError();

    function name() external pure returns (string memory) {
        return "Airdrop";
    }

    function getPaused() external view returns (bool) {
        return _paused;
    }

    function setPaused(bool paused) external onlyOwner {
        _paused = paused;
    }

    function balanceOf(
        address targetContract,
        address account,
        uint256 id
    ) external view returns (uint256) {
        return ERC1155(targetContract).balanceOf(account, id);
    }

    function isApprovedForAll(address targetContract, address account)
        external
        view
        returns (bool)
    {
        return ERC1155(targetContract).isApprovedForAll(account, address(this));
    }

    function doAirdrop(
        address targetContract,
        address[] memory accounts,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external nonReentrant {
        if (_paused) {
            revert PausedError();
        }

        bool isApproved = ERC1155(targetContract).isApprovedForAll(
            msg.sender,
            address(this)
        );

        if (!isApproved) {
            revert ApprovalError();
        }

        if (
            accounts.length == 0 ||
            tokenIds.length == 0 ||
            tokenIds.length != amounts.length
        ) {
            revert ArraySizeError();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            ERC1155(targetContract).safeBatchTransferFrom(
                msg.sender,
                accounts[i],
                tokenIds,
                amounts,
                ""
            );
        }
    }
}

// ╔════════════════════╗
// ║   Smart Contract   ║
// ║         by         ║
// ║     King Tide      ║
// ╚════════════════════╝

