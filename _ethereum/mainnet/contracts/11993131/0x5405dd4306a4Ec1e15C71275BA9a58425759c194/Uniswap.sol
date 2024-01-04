//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";

import "./Interfaces.sol";
import "./Math.sol";

// Implements the TRBBalancer interface and
// returns a user balancer in TRB.
contract Uniswap is DSMath, TRBBalancer {
    IUniswapV2Pair public pair;
    address public burnBeneficiary;

    constructor(address _pair, address _burnBeneficiary) {
        require(
            _burnBeneficiary != address(0),
            "_burnBeneficiary can't be the zero address"
        );
        pair = IUniswapV2Pair(_pair);
        burnBeneficiary = _burnBeneficiary;
    }

    // solhint-disable-next-line
    function trbBalanceOf(
        address, /* _x */
        address holder
    ) external view override returns (uint256) {
        uint256 userBalance = pair.balanceOf(holder);
        uint256 totalSupply = pair.totalSupply();
        uint256 poolShare = wdiv(userBalance, totalSupply);

        (uint256 trbTotalBalance, , ) = pair.getReserves();

        uint256 trbAddrBalance = wmul(trbTotalBalance, poolShare);

        // The uniswap pools are always 50/50 so
        // give the addres 2 times more TRB for the lost ETH.
        trbAddrBalance = 2 * trbAddrBalance;

        return trbAddrBalance;
    }

    function burn(
        address, /* _x */
        address holder
    ) external override returns (bool) {
        uint256 balance = pair.balanceOf(holder);
        // Transfer all tokens to the devshare address.
        // This is so that if uniswap drops Uni tokens the team can claim these
        // on behalf of the original LP providers.
        return pair.transferFrom(holder, burnBeneficiary, balance);
    }
}
