// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";

import "./IChainLinkFeed.sol";
import "./IUniswapV2SlidingOracle.sol";
import "./IKeep3rV1Mini.sol";

contract Keep3rV1HelperLegacy is Ownable{
    using SafeMath for uint;

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep3rV1Mini public KP3R;
    IUniswapV2SlidingOracle public constant UV2SO = IUniswapV2SlidingOracle(0xAbC29C8bF08F311DAdFdd8B220f1d1FCF6C64C8D);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint constant public MAX = 11;
    uint constant public BASE = 10;
    uint constant public SWAP = 300000;
    uint constant public TARGETBOND = 200e18;

    function quote(uint eth) public view returns (uint) {
        return UV2SO.current(address(WETH), eth, address(KP3R));
    }

    function setToken(address keepertoken) public onlyOwner{
        KP3R = IKeep3rV1Mini(keepertoken);
    }

    function getFastGas() external view returns (uint) {
        return uint(FASTGAS.latestAnswer());
    }

    function bonds(address keeper) public view returns (uint) {
        return KP3R.bonds(keeper, address(KP3R)).add(KP3R.votes(keeper));
    }

    function getQuoteLimitFor(address origin, uint gasUsed) public view returns (uint) {
        uint _min = quote((gasUsed.add(SWAP)).mul(uint(FASTGAS.latestAnswer())));
        uint _boost = _min.mul(MAX).div(BASE);
        uint _bond = Math.min(bonds(origin), TARGETBOND);
        return Math.max(_min, _boost.mul(_bond).div(TARGETBOND));
    }

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        return getQuoteLimitFor(tx.origin, gasUsed);
    }
}
