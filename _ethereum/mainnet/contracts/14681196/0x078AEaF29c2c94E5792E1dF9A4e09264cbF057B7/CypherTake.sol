// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC1155Tradable.sol";

/**
 * @title CypherTakes
 * @author The Cypherverse Ltd
 */
contract CypherTake is ERC1155Tradable {
    /** @dev Initial Contract URI */
    string private CONTRACT_URI;

    constructor(
        string memory _tokenUri,
        string memory _contractURI,
        address _proxyRegistryAddress,
        address _minterRole
    )
        public
        ERC1155Tradable(
            "CypherTakes",
            "CVT",
            _tokenUri,
            _proxyRegistryAddress,
            _minterRole
        )
    {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing the Contract URI to be updated
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing Contract URI to be obtained
     */
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /**
     * @notice Compat for factory interfaces on OpenSea
     * @dev Indicates that this contract can return balances for
     * @dev tokens that haven't been minted yet
     */
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC1155.
     * @dev See {ERC1155Pausable}.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     */
    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }
}
