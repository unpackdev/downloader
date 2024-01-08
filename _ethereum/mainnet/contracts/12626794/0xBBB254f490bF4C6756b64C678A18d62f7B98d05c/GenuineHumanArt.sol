//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArtistCollection721.sol";

/// @title Genuine Human Art contract
/// @author Simon Fremaux (@dievardump)
/// @notice This contract is for Genuine Human Art to be able to release some of his Art on his own contract collection
/// @notice It expects each tokens to have its own URI
contract GenuineHumanArt is ArtistCollection721 {
    /// @notice Initializer function used for upgradeable contracts
    /// @dev this function will be run only the first time (checking if symbol is set) to initialize
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_
    ) public {
        // this allows to not run _initialize on the parent every time we have an update
        if (bytes(symbol()).length > 0) {
            return;
        }

        _initialize(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        );
    }
}
