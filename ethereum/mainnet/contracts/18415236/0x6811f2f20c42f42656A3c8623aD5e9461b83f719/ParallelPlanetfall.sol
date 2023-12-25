pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "./Pausable.sol";

import "./ERC1155Invoke.sol";

/// @title The ParallelPlanetfall contract.
/// @notice Used for parallel planetfall nfts.
contract ParallelPlanetfall is ERC1155Invoke, Pausable {
    constructor()
        ERC1155Invoke(
            false,
            "https://nftdata.parallelnft.com/api/parallel-planetfall/ipfs/",
            "ParallelPlanetfall",
            "LLPF"
        )
    {
        _pause();
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(
            !paused() ||
                from == address(0) ||
                to == address(0) ||
                hasRole(MINTER_ROLE, from),
            "ERC1155Pausable: token transfer while paused"
        );
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be the minter.
     */
    function unpause() external onlyMinter {
        _unpause();
    }
}
