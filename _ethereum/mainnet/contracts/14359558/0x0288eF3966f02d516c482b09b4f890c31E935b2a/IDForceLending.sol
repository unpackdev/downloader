//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a iToken asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(IiToken _iToken) external returns (uint256);

    /**
     * @notice Get the price of a underlying asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable and whether the price is valid.
     */
    function getUnderlyingPriceAndStatus(IiToken _iToken) external returns (uint256, bool);
}

interface IController {
    function priceOracle() external view returns (IPriceOracle);
}

interface IiToken {

    function isSupported() external view returns (bool);

    function isiToken() external view returns (bool);

    function decimals() external view returns (uint8);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);


    function accrualBlockNumber() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function reserveRatio() external view returns (uint256);
    
    function borrowRatePerBlock() external view returns (uint256);


    function underlying() external view returns (address);

    function controller() external view returns (IController);

}
