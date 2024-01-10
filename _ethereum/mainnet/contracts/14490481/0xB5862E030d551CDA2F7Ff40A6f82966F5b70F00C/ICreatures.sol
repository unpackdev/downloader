//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ICreaturesTypes.sol";

interface ICreatures is ICreaturesTypes {
    function tokensForOwner(address user)
        external
        view
        returns (uint256[] memory ids);
}
