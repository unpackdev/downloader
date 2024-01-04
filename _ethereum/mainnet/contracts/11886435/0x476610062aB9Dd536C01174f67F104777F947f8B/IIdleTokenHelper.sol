pragma solidity 0.5.16;

contract IIdleTokenHelper {
    function getMintingPrice(address idleYieldToken)
        external
        view
        returns (uint256 mintingPrice);

    function getRedeemPrice(address idleYieldToken)
        external
        view
        returns (uint256 redeemPrice);

    function getRedeemPrice(address idleYieldToken, address user)
        external
        view
        returns (uint256 redeemPrice);
}
