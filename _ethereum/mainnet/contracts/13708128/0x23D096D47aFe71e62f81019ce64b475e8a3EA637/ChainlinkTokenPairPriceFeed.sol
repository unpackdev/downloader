// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./SafeCast.sol";

import "./IChainlinkAggregator.sol";
import "./IENS.sol";
import "./ITokenPairPriceFeed.sol";

abstract contract ChainlinkTokenPairPriceFeed is ITokenPairPriceFeed {
    // The ENS registry (same for mainnet and all major testnets)
    //
    // See https://docs.chain.link/docs/ens/. This may need to be updated should Chainlink deploy
    // on other networks with a different ENS address.
    IENS private constant ENS = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function getRate(bytes32 chainlinkAggregatorNodeHash)
        public
        view
        override
        returns (uint256 rate, uint256 rateDenominator)
    {
        IENSResolver ensResolver = ENS.resolver(chainlinkAggregatorNodeHash);
        IChainlinkAggregator chainLinkAggregator = IChainlinkAggregator(ensResolver.addr(chainlinkAggregatorNodeHash));

        (, int256 latestRate, , , ) = chainLinkAggregator.latestRoundData();

        return (SafeCast.toUint256(latestRate), 10**chainLinkAggregator.decimals());
    }
}
