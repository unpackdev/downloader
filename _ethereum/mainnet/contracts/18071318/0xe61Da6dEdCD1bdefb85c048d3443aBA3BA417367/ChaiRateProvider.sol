pragma solidity ^0.8.19;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface IPot {
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function dsr() external view returns (uint256);
}

/**
 * @title Chai Rate Provider
 * @notice Returns the value of CHAI in terms of DAI
 */
contract ChaiRateProvider is IRateProvider {
    IPot public constant pot = IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);

    /**
     * @return the value of CHAI in terms of DAI
     */
    function getRate() external view override returns (uint256) {
        return (block.timestamp > pot.rho()) ? _dripPreview() : pot.chi();
    }

    function _dripPreview() internal view returns (uint256) {
        return rmul(rpow(pot.dsr(), block.timestamp - pot.rho(), ONE), pot.chi());
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}