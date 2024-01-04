pragma solidity ^0.5.16;

import "./IPriceOracle.sol";

interface IComptroller {
    function oracle() external view returns (IPriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}