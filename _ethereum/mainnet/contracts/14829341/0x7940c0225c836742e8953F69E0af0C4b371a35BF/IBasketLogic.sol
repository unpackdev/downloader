// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IBasketLogic {
    function getAssetsAndBalances()
        external
        view
        returns (address[] memory, uint256[] memory);

    /// @notice Gets the amount of assets backing each Basket token
    /// @return (the addresses of the assets,
    ///          the amount of backing 1 Basket token)
    function getOne()
        external
        view
        returns (address[] memory, uint256[] memory);

    /// @notice Gets the fees and the fee recipient
    /// @return (mint fee, burn fee, recipient)
    function getFees()
        external
        view
        returns (
            uint256,
            uint256,
            address
        );

    // **** Mint/Burn functionality **** //

    /// @notice Mints a new Basket token
    /// @param  _amountOut  Amount of Basket tokens to mint
    function mint(uint256 _amountOut) external;

    /// @notice Previews the corresponding assets and amount required to mint `_amountOut` Basket tokens
    /// @param  _amountOut  Amount of Basket tokens to mint
    function viewMint(uint256 _amountOut)
        external
        view
        returns (uint256[] memory _amountsIn);

    /// @notice Burns the basket token and retrieves
    /// @param  _amount  Amount of Basket tokens to burn
    function burn(uint256 _amount) external;
}
