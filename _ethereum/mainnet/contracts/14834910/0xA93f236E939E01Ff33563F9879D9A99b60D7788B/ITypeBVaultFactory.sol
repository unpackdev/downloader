//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITypeBVaultFactory {

    /// @dev Create a createTypeB
    /// @param _name name
    /// @param _token token Address
    /// @param _owner  owner Address
    /// @return created typeBvault contract address
    function createTypeB(
        string calldata _name,
        address _token,
        address _owner
    )
        external
        returns (address);
}
