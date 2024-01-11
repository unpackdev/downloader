// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./IOneWarDescriptor.sol";
import "./IOneWar.sol";
import "./NFTDescriptor.sol";
import "./Strings.sol";

contract OneWarDescriptor is IOneWarDescriptor {
    IOneWar public oneWar;

    constructor(IOneWar _oneWar) {
        oneWar = _oneWar;
    }

    function tokenURI(uint256 _settlement) external view override returns (string memory) {
        bool hasWarCountdownBegun = oneWar.hasWarCountdownBegun();
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: string(abi.encodePacked("Settlement #", Strings.toString(_settlement))),
            description: string(
                abi.encodePacked("Settlement #", Strings.toString(_settlement), " is a location in OneWar.")
            ),
            attributes: oneWar.settlementTraits(_settlement),
            extraAttributes: NFTDescriptor.ExtraAttributes({
                redeemableGold: oneWar.redeemableGold(_settlement),
                hasWarCountdownBegun: hasWarCountdownBegun,
                blocksUntilSanctuaryEnds: hasWarCountdownBegun ? oneWar.blocksUntilSanctuaryEnds(_settlement) : 0
            })
        });

        return NFTDescriptor.constructTokenURI(params);
    }
}
