// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBoardroom.sol";

interface IVaultBoardroom is IBoardroom {
    function bondingHistory(address who, uint256 epoch)
        external
        view
        returns (BondingSnapshot memory);

    function directors(address who) external view returns (Boardseat memory);
}
