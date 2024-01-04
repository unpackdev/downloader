//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";

import "./Interfaces.sol";
import "./Math.sol";

// Implements the TRBBalancer interface and
// returns a user balancer in TRB.
contract BPool is DSMath, TRBBalancer {
    // BPoolPair public pair;

    address public burnBeneficiary;

    constructor(address _burnBeneficiary) {
        require(
            _burnBeneficiary != address(0),
            "_burnBeneficiary can't be the zero address"
        );

        // pair = BPoolPair(_pair);
        burnBeneficiary = _burnBeneficiary;
    }

    function trbBalanceOf(address poolAddress, address holder)
        external
        view
        override
        returns (uint256)
    {
        BPoolPair pair = BPoolPair(poolAddress);
        uint256 userBalance = pair.balanceOf(holder);
        uint256 totalSupply = pair.totalSupply();
        uint256 poolShare = wdiv(userBalance, totalSupply);

        uint256 trbTotalBalance =
            pair.getBalance(0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5);

        uint256 trbAddrBalance = wmul(trbTotalBalance, poolShare);
        // How much extra TRB need to print for the other lost tokens.
        // For example if the pool is 25% DAI, 50% ETH, 25% TRB
        // need to print 1/weight * trbAmount
        // So for a user that had 10 TRB this is
        // (1/0.25) * 10 = 40
        uint256 multiplier =
            wdiv(
                10**18,
                pair.getNormalizedWeight(
                    0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5
                )
            );
        trbAddrBalance = wmul(multiplier, trbAddrBalance);
        return trbAddrBalance;
    }

    function burn(address poolAddress, address holder)
        external
        override
        returns (bool)
    {
        BPoolPair pair = BPoolPair(poolAddress);
        uint256 balance = pair.balanceOf(holder);
        // Transfer all tokens to the devshare address.
        // This is so that if uniswap drops Uni tokens the team can claim these
        // on behalf of the original LP providers.
        return pair.transferFrom(holder, burnBeneficiary, balance);
    }
}
