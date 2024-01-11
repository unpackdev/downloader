//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITOSFactory {

    /// @dev Create a TOSFactory
    /// @param _name name
    /// @param _token token Address
    /// @param _owner  owner Address
    /// @return created TOSFactory contract address
    function create(
        string calldata _name,
        address _token,
        address _owner
    )
        external
        returns (address);

    /// @dev set the dividedPool address
    /// @param _dividedPool set PoolAddress
    function setinfo(
        address _dividedPool
    ) 
        external;
}
