pragma solidity ^0.5.16;

import "./CErc20.sol";
import "./AggregatorV2V3Interface.sol";

/**
 * @title Compound's CPoR (Proof of Reserves) Contract
 * @notice CToken which checks reserves before minting
 * @author Chainlink
 */
contract CPoR is CErc20, CPoRInterface {
    /**
     * @notice User supplies assets into the market and receives cTokens in exchange
     * @dev Overrides CErc20's mintFresh function to check the proof of reserves
     * @dev This check can be skipped if the feed is set to the zero address
     * @param account The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintFresh(address account, uint mintAmount) internal returns (uint, uint) {
        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(feed);
        if (address(aggregator) == address(0)) {
            return super.mintFresh(account, mintAmount);
        }

        MathError mathErr;
        // Get the latest details from the feed
        (,int answer,,uint updatedAt,) = aggregator.latestRoundData();
        if (answer < 0) {
            return (fail(Error.TOKEN_MINT_ERROR, FailureInfo.MINT_FEED_INVALID_ANSWER), 0);
        }

        uint oldestAllowed;
        // Use MAX_AGE if heartbeat is not explicitly set
        uint heartbeat_ = heartbeat;
        (mathErr, oldestAllowed) = subUInt(block.timestamp, heartbeat_ == 0 ? MAX_AGE : heartbeat_);
        if (mathErr != MathError.NO_ERROR) {
            return (fail(Error.MATH_ERROR, FailureInfo.MINT_FEED_INVALID_TIMESTAMP), 0);
        }

        // Check that the feed's answer is updated within the heartbeat
        if (oldestAllowed > updatedAt) {
            return (fail(Error.TOKEN_MINT_ERROR, FailureInfo.MINT_FEED_HEARTBEAT_CHECK), 0);
        }

        // Get required info
        EIP20Interface underlyingErc20 = EIP20Interface(underlying);
        uint underlyingSupply = underlyingErc20.totalSupply();
        uint8 underlyingDecimals = underlyingErc20.decimals();
        uint8 feedDecimals = aggregator.decimals();
        uint reserves = uint(answer);

        // Check that the feed and underlying token decimals are equivalent and normalize if not
        if (underlyingDecimals < feedDecimals) {
            (mathErr, underlyingSupply) = mulUInt(underlyingSupply, 10 ** uint(feedDecimals - underlyingDecimals));
        } else if (feedDecimals < underlyingDecimals) {
            (mathErr, reserves) = mulUInt(reserves, 10 ** uint(underlyingDecimals - feedDecimals));
        }

        if (mathErr != MathError.NO_ERROR) {
            return (fail(Error.MATH_ERROR, FailureInfo.MINT_FEED_INVALID_DECIMALS), 0);
        }

        // Ensure that the current supply of underlying tokens is not greater than the reported reserves
        if (underlyingSupply > reserves) {
            return (fail(Error.TOKEN_MINT_ERROR, FailureInfo.MINT_FEED_SUPPLY_CHECK), 0);
        }

        return super.mintFresh(account, mintAmount);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new feed address
     * @dev Admin function to set a new feed
     * @param newFeed Address of the new feed
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setFeed(address newFeed) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FEED_ADMIN_OWNER_CHECK);
        }

        emit NewFeed(feed, newFeed);

        feed = newFeed;

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets the feed's heartbeat expectation
     * @dev Admin function to set the heartbeat
     * @param newHeartbeat Value of the age of the latest update from the feed
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setHeartbeat(uint newHeartbeat) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FEED_HEARTBEAT_ADMIN_OWNER_CHECK);
        }

        // Check newHeartbeat input
        if (newHeartbeat > MAX_AGE) {
            return fail(Error.BAD_INPUT, FailureInfo.SET_FEED_HEARTBEAT_INPUT_CHECK);
        }

        emit NewHeartbeat(heartbeat, newHeartbeat);

        heartbeat = newHeartbeat;

        return uint(Error.NO_ERROR);
    }
}
