//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MintingStation.sol";

/// @title VerticalCrypto
/// @author Simon Fremaux (@dievardump)
contract VerticalCrypto is MintingStation {
    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_,
        address[] memory minters
    )
        ERC721Ownable(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        )
    {
        if (minters.length > 0) {
            _addMinters(minters);
        }
    }
}
