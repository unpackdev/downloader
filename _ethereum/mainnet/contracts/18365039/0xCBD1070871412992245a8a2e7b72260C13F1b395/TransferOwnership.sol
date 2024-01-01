// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./LibDiamond.sol";

contract TransferOwnership {
    function setDiamondOwner(address newOwner) external {
        LibDiamond.setContractOwner(newOwner);
    }
}