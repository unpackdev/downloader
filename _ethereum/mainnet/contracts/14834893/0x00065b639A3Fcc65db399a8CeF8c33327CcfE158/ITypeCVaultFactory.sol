//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITypeCVaultFactory {

    /// @dev Create a createTypeC
    /// @param _name name
    /// @param _token token Address
    /// @param _owner  owner Address
    /// @return created typeCvault contract address
    function createTypeC(
        string calldata _name,
        address _token,
        address _owner
    )
        external
        returns (address);

}
