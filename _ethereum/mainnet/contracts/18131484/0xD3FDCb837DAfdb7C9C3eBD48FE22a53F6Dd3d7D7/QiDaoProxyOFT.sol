// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ProxyOFTV2.sol";

contract QiDaoProxyOFT is ProxyOFTV2 {

    struct RateLimit {
        uint256 amountInFlight;
        uint256 lastDepositTime;
        uint256 limit;
        uint256 window;
    }

    struct RateLimitConfig {
        uint16 dstChainId;
        uint256 limit;
        uint256 window;
    }

    mapping(uint16 => RateLimit) public rateLimits;

    constructor(
        RateLimitConfig[] memory _rateLimitConfigs,
        address _token,
        uint8 _sharedDecimals,
        address _lzEndpoint
    ) ProxyOFTV2(_token, _sharedDecimals, _lzEndpoint) {
        _setRateLimits(_rateLimitConfigs);
    }

    function setRateLimits(RateLimitConfig[] calldata _rateLimitConfigs) external onlyOwner {
        _setRateLimits(_rateLimitConfigs);
    }

    function _setRateLimits(RateLimitConfig[] memory _rateLimitConfigs) internal {
        unchecked {
            for (uint256 i = 0; i < _rateLimitConfigs.length; i++) {
                RateLimit storage rl = rateLimits[_rateLimitConfigs[i].dstChainId];

                // @dev does NOT reset the amountInFlight/lastDepositTime of an existing rate limit
                rl.limit = _rateLimitConfigs[i].limit;
                rl.window = _rateLimitConfigs[i].window;
            }
        }
    }

    // @dev returns 0 for currentAmountInFlight and amountCanBeSent if rate
    function getAmountCanBeSent(uint16 _dstChainId) external view returns (uint256 currentAmountInFlight, uint256 amountCanBeSent) {
        RateLimit memory rl = rateLimits[_dstChainId];
        return _amountCanBeSent(rl.amountInFlight, rl.lastDepositTime, rl.limit, rl.window);
    }

    function _amountCanBeSent(
        uint256 amountInFlight,
        uint256 lastDepositTime,
        uint256 limit,
        uint256 window
    ) internal view returns (uint256 currentAmountInFlight, uint256 amountCanBeSent) {
        uint256 timeSinceLastDeposit = block.timestamp - lastDepositTime;

        if (timeSinceLastDeposit >= window) {
            currentAmountInFlight = 0;
            amountCanBeSent = limit;
        } else {
            // @dev presumes linear decay
            uint256 decay = (limit * timeSinceLastDeposit) / window;
            currentAmountInFlight = amountInFlight <= decay ? 0 : amountInFlight - decay;
            // @dev in the event the limit is lowered, and the 'in-flight' amount is higher than the limit, set to 0
            amountCanBeSent = limit <= currentAmountInFlight ? 0 : limit - currentAmountInFlight;
        }
    }

    function _checkAndUpdateRateLimit(uint16 _dstChainId, uint256 _amount) internal {
        // @dev by default dstChain ids that have not been explicitly set will return amountCanBeSent == 0
        RateLimit storage rl = rateLimits[_dstChainId];

        (uint256 currentAmountInFlight, uint256 amountCanBeSent) = _amountCanBeSent(rl.amountInFlight, rl.lastDepositTime, rl.limit, rl.window);
        require(_amount <= amountCanBeSent, "QiDaoProxyOFT: max inflight reached");

        // update the storage to contain the new amount and current timestamp
        rl.amountInFlight = currentAmountInFlight + _amount;
        rl.lastDepositTime = block.timestamp;
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        // @dev adds this check compared to regular proxyOFT
        _checkAndUpdateRateLimit(_dstChainId, _amount);
        return super._debitFrom(_from, _dstChainId, _toAddress, _amount);
    }
}
