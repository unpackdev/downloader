// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRoyaltyFeeRegistry.sol";
import "./IRoyaltyFeeManager.sol";
import "./ITransferSelectorNFT.sol";

interface IRoyaltyFeeManagerExtended is IRoyaltyFeeManager {
    function royaltyFeeRegistry() external view returns (IRoyaltyFeeRegistry);
}

interface ITransferSelectorNFTExtended is ITransferSelectorNFT {
    function TRANSFER_MANAGER_ERC721() external view returns (address);

    function TRANSFER_MANAGER_ERC1155() external view returns (address);

    function transferManagerSelectorForCollection(address collection) external view returns (address);
}
