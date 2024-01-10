// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155Tradable.sol";
import "./Pausable.sol";

/**
 * @title CypherLegends
 * @dev CypherLegends - A fungibility-agnostic NFT contract for Legends of the Cypherverse
 * @author The Cypherverse Ltd
 */
contract CypherLegends is ERC1155Tradable, Pausable {
    // Initial Contract URI
    string private CONTRACT_URI;

    constructor(address _proxyRegistryAddress)
        public
        ERC1155Tradable("CypherLegends", "CVL", "https://api.cypherverse.io/os/collections/cypherlegends/{id}", _proxyRegistryAddress)
    {
		CONTRACT_URI = "https://api.cypherverse.io/os/collections/cypherlegends";
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing the Contract URI to be updated
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function setContractURI(string memory _contractURI) public onlyOwner() {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing Contract URI to be obtained
    */
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

	/**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	/**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override(Context)
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
