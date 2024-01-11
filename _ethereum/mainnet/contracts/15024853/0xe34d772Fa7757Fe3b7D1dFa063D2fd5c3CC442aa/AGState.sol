// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IAGStakeFull.sol";
import "./IAlphaGangGenerative.sol";

contract AGState {
    IAGStake constant AGStake =
        IAGStake(0xdb7a1FFCB7beE3b161279c370383c0a3D0459865);
    IAlphaGangGenerative constant AlphaGangG2 =
        IAlphaGangGenerative(0x125808292F4Bb11Bf2D01b070d94E19490f7f4Dc);

    function stakedG2TokensOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256 supply = AlphaGangG2.totalSupply();

        uint256 ownerStakedTokenCount = AGStake.ownerG2StakedCount(account);
        uint256[] memory tokens = new uint256[](ownerStakedTokenCount);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (AGStake.vaultG2(account, tokenId) > 0) {
                tokens[index] = tokenId;
                index++;
            }
        }
        return tokens;
    }
}
