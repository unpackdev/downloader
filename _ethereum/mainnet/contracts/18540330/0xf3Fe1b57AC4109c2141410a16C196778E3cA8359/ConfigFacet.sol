// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LibAppStorage.sol";
import "./IRouterClient.sol";

contract ConfigFacet is Modifiers {
    /**
     * @notice Retrieves the addresses of the bot, manager, and storage contracts.
     * @dev This function returns the current configuration of these three addresses.
     * @return botAddr The address of the bot (wallet use by our backend)
     * @return managerAddr The address of the manager contract (on Polygon).
     * @return storageAddr The address of the storage contract (this contract).
     */
    function getGeneralConfig() external view returns (address botAddr, address managerAddr, address storageAddr) {
        return (s.botAddress, s.managerAddress, s.storageAddress);
    }

    /**
     * @notice Retrieves the price associated with a given quantity.
     * @return price The price associated with the given quantity.
     */
    function getPrice() external view returns (uint256 price) {
        return s.price;
    }

    /**
     * @notice Updates the address of the storage contract (this contract)
     * @dev This function can only be called by the bot or the owner of the contract.
     * @param newAddr The new address for the storage contract.
     */
    function setStorage(address newAddr) external onlyBotOrOwner {
        s.storageAddress = newAddr;
    }

    function setLinkTokenAddress(address _newAddress) external onlyBotOrOwner {
        s.linkTokenAddr = _newAddress;
    }

    function getLinkTokenAddress() external view returns (address) {
        return s.linkTokenAddr;
    }

    function setManagerAddress(address _newAddress) external onlyBotOrOwner {
        s.managerAddress = _newAddress;
        s.CCIPReceiver = _newAddress;
    }

    function setCCIPRouter(address _newAddress) external onlyBotOrOwner {
        s.CCIPRouter = IRouterClient(_newAddress);
    }

    function setPrice(uint256 newPrice) external onlyBotOrOwner {
        s.price = newPrice;
    }
}
