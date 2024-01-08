pragma solidity ^0.5.7;

import "./ZapInBaseV1.sol";

contract MockZapIn is ZapInBaseV1 {
    constructor(uint256 goodwill, uint256 affiliateSplit)
        public
        ZapBaseV1(goodwill, affiliateSplit)
    {}

    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address affiliate
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        if (fromToken == address(0)) {
            msg.sender.transfer(toInvest);
        } else {
            IERC20(fromToken).safeTransfer(address(0), toInvest);
        }
    }
}
