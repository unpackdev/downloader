pragma solidity 0.8.19;

interface IStableSwap {
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function fee() external view returns (uint256);
}

interface IAggregatorStablePrice {
    function price() external view returns (int256);
}

contract SpotOracle {
    IStableSwap public constant MKUSD_CRVUSD = IStableSwap(0x3de254A0f838a844F727fee81040e0FA7884B935);
    IAggregatorStablePrice public constant CRVUSD_USD =
        IAggregatorStablePrice(0xe5Afcf332a5457E8FafCD668BcE3dF953762Dfe7);

    /**
        @notice Get the spot price of mkUSD from the Curve mkUSD/crvUSD pool,
                expressed as a whole number with a precision of 1e18
        @dev THIS ORACLE IS EASILY MANIPULATED! IT IS NOT ACCEPTABLE FOR ON-CHAIN USE!
     */
    function getPrice() external view returns (uint256) {
        // amount received from swaping 1 mkUSD -> crvUSD, normalized to 1e18
        uint256 dy = MKUSD_CRVUSD.get_dy(0, 1, 1e18);

        // mkusd/fraxbp fee, normalized to 1e18
        uint256 fee = (MKUSD_CRVUSD.fee() + 1e10) * 1e8;

        // crvUSD price, normalized to 1e18
        uint256 crvusd = uint256(CRVUSD_USD.price());

        return (dy * fee * crvusd) / 1e36;
    }
}
