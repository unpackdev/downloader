//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";

contract NDS0ShellConverter is ReentrancyGuard {

    /// @dev This event is fired when converting shells
    /// @param tokenIds  The ids of the Shell items that were deposited into the contract.
    event ConvertShells(
        uint256[] tokenIds,
        address sender,
        string uuid
    );

    address public ndShellsAddress = 0x1276dce965ADA590E42d62B3953dDc1DDCeB0392;

    /**
     * @dev Allows a user to convert shells from season zero to season one, monitored by oracle
     *
     * @param tokenIds - array containing the token ids to wrap
     *
     * Requirements:
     * 1) either setApproval for each tokenId or setApprovalForAll must be called on this contract
     */
    function convertShells(
        uint256[] calldata tokenIds,
        string calldata uuid
    ) external nonReentrant {
        require(tokenIds.length > 0, "At least one token ID required.");

        IERC721 ndShells = IERC721(ndShellsAddress);
        for (uint256 idx = 0; idx < tokenIds.length; idx++) {
            require(tokenIds[idx] > 1, "Can't convert Baus");
            ndShells.transferFrom(
                msg.sender,    // transfer from sender
                address(this), // to this contract
                tokenIds[idx]  // shell id
            );
        }

        emit ConvertShells(tokenIds, msg.sender, uuid);
    }

    /**
     * @dev do not accept value sent directly to contract
     */
    receive() external payable {
        revert("No value accepted");
    }
}
