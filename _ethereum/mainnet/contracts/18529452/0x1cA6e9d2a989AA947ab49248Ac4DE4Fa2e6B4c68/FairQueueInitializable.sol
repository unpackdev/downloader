// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";

/**
 * @title FairQueue
 * @notice Fairly assigns a delay time to each address from a uniform distribution over [0, maxDelayTime]
 * @dev The delay is determined by calculating a distance between the user's address and a pseudorandom value based on a provided salt and a blockhash
 * using the XOR distance metric. Do not use this contract if the event is public because users could grind addresses until they find one with a low delay.
 */
contract FairQueueInitializable is Initializable {
    event SetDelay(uint160 maxDelayTime);
    /**
     * calculate a speed at which the queue is exhausted such that all users complete the queue by maxDelayTime
     */

    uint160 public distancePerSecond;
    uint160 public maxDelayTime;

    /**
     * @dev the random value from which a distance will be calculated for each address. Reset the random value
     * to shuffle the delays for all addresses.
     */
    uint160 public randomValue;

    function __FairQueue_init(uint160 _maxDelayTime, uint160 salt) internal onlyInitializing {
        _setDelay(_maxDelayTime);
        _setPseudorandomValue(salt);
    }

    /**
     * @dev internal function to set the random value. A salt (e.g. from a merkle root) is required to prevent
     * naive manipulation of the random value by validators
     */
    function _setPseudorandomValue(uint160 salt) internal {
        if (distancePerSecond == 0) {
            // there is no delay: random value is not needed
            return;
        }
        require(salt > 0, "I demand more randomness");
        randomValue = uint160(uint256(blockhash(block.number - 1))) ^ salt;
    }

    /**
     * @dev Internal function to configure delay
     * 	@param _maxDelayTime the maximum delay for any address in seconds. Set this value to 0 to disable delays entirely.
     */
    function _setDelay(uint160 _maxDelayTime) internal {
        maxDelayTime = _maxDelayTime;
        distancePerSecond = _maxDelayTime > 0 ? type(uint160).max / _maxDelayTime : 0;
        emit SetDelay(_maxDelayTime);
    }

    /**
     * @notice get a fixed delay for any address by drawing from a unform distribution over the interval [0, maxDelay]
     * 		@param user The address for which a delay should be calculated. The delay is deterministic for any given address and pseudorandom value.
     * 		@dev The delay is determined by calculating a distance between the user's address and a pseudorandom value using the XOR distance metric (c.f. Kademlia)
     *
     * 		Users cannot exploit the fair delay if:
     * 		- The event is private, i.e. an access list of some form is required
     * 		- Each eligible user gets exactly one address in the access list
     * 		- There is no collusion between event participants, block validators, and event owners
     *
     * 		The threat of collusion is likely minimal:
     * 		- the economic opportunity to validators is zero or relatively small (only specific addresses can participate in private events, and a lower delay time does not imply higher returns)
     * 		- event owners are usually trying to achieve a fair distribution of access to their event
     */
    function getFairDelayTime(address user) public view returns (uint256) {
        if (distancePerSecond == 0) {
            // there is no delay: all addresses may participate immediately
            return 0;
        }

        // calculate a distance between the random value and the user's address using the XOR distance metric (c.f. Kademlia)
        uint160 distance = uint160(user) ^ randomValue;

        // return the delay (seconds)
        return distance / distancePerSecond;
    }
}
