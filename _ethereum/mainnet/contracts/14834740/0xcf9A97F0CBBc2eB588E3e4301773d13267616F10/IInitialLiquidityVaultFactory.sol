//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IInitialLiquidityVaultFactory {

    event CreatedInitialLiquidityVault(address contractAddress, string name);


    /// ###### only admin ######

    /// @dev set unoswap address , token address and pools addresses
    /// @param addrs [uniswapV3Factory, nonfungiblePositionManager]
    /// @param _tos  tos address
    /// @param _fee the pool's fee
    function setUniswapInfoNTokens(
        address[2] calldata addrs,
        address _tos,
        uint24 _fee
    )   external;


    /// ### anybody can use

    /// @dev Create a InitialLiquidityVaultProxy
    /// @param _name name
    /// @param _token token address
    /// @param _admin  admin address
    /// @param tosPrice  tosPrice
    /// @param tokenPrice  atokenPrice
    /// @return created InitialLiquidityVaultProxy contract address
    function create(
        string calldata _name,
        address _token,
        address _admin,
        uint256 tosPrice,
        uint256 tokenPrice
    )
        external
        returns (address);
}
