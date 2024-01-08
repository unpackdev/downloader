// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//import "./console.sol";
import "./ABDKMath64x64.sol";
import "./ChainlinkVRF.sol";
import "./IERC721Enumerable.sol";
import "./Roles.sol";


interface IERC721Adapter {
    function _totalSupply() external view returns (uint256);
    function _tokenByIndex(uint256 index) external view  returns (uint256);
    function _isDisabled() external view returns (bool);
}

abstract contract Randomness is ChainlinkVRF, IERC721Adapter {
    using SafeMath for uint256;

    // Configuration Chainlink VRF
    struct VRFConfig {
        address coordinator;
        address token;
        bytes32 keyHash;
        uint256 price;
    }

    event RollInProgress(
        int128 probability
    );

    event RollComplete();

    uint probabilityPerSecond;
    uint public constant denominator           = 10000000000000000; // 100%

    uint256 randomSeedBlock = 0;
    int128 public rollProbability = 0;
    uint256 public lastRollTime = 0;

    bytes32 chainlinkRequestId = 0;
    uint256 chainlinkRandomNumber = 0;
    bytes32 internal chainlinkKeyHash;
    uint256 internal chainlinkFee;

    constructor(VRFConfig memory config, uint _probabilityPerSecond, uint initRollTime) ChainlinkVRF(config.coordinator, config.token) {
        chainlinkFee = config.price;
        chainlinkKeyHash = config.keyHash;

        lastRollTime = initRollTime;
        probabilityPerSecond = _probabilityPerSecond;
    }

    // Will return the probability of a (non-)diagnosis for an individual NFT, assuming the roll will happen at
    // `timestamp`. This will be based on the last time a roll happened, targeting a certain total probability
    // over the period the project is running.
    // Will return 0.80 to indicate that the probability of a diagnosis is 20%.
    function getProbability(uint256 timestamp) public view returns (int128 probability) {
        uint256 secondsSinceLastRoll = timestamp.sub(lastRollTime);

        // Say we want totalProbability = 20% over the course of the project's runtime.
        // If we roll 12 times, what should be the probability of each roll so they compound to 20%?
        //    (1 - x) ** 12 = (1 - 20%)
        // Or generalized:
        //    (1 - x) ** numTries = (1 - totalProbability)
        // Solve by x:
        //     x = 1 - (1 - totalProbability) ** (1/numTries)
        //

        // We use the 64.64 fixed point math library here. More info about this kind of math in Solidity:
        // https://medium.com/hackernoon/10x-better-fixed-point-math-in-solidity-32441fd25d43
        // https://ethereum.stackexchange.com/questions/83785/what-fixed-or-float-point-math-libraries-are-available-in-solidity

        // We already pre-calculated the probability for a 1-second interval
        int128 _denominator = ABDKMath64x64.fromUInt(denominator);
        int128 _probabilityPerSecond = ABDKMath64x64.fromUInt(probabilityPerSecond);

        // From the *probability per second* number, calculate the probability for this dice roll based on
        // the number of seconds since the last roll. randomNumber must be larger than this.
        probability = ABDKMath64x64.pow(
        // Convert from our fraction using our denominator, to a 64.64 fixed point number
            ABDKMath64x64.div(
            // reverse-probability of x: (1-x)
                ABDKMath64x64.sub(
                    _denominator,
                    _probabilityPerSecond
                ),
                _denominator
            ),
            secondsSinceLastRoll
        );

        // `randomNumber / (2**64)` would now give us the random number as a 10-base decimal number.
        // To show it in Solidity, which does not support non-integers, we could multiply to shift the
        // decimal point, for example:
        //    console.log("randomNumber",
        //      uint256(ABDKMath64x64.toUInt(
        //        ABDKMath64x64.mul(randomNumber, ABDKMath64x64.fromUInt(1000000))
        //      ))
        //    );
    }

    // Anyone can roll, but the beneficiary is incentivized to do so.
    //
    // # When using Chainlink VRF:
    // Make sure you have previously funded the contract with LINK. Since anyone can start a request at
    // any time, do not prefund the contract; send the tokens when you want to enable a roll.
    //
    // # When using the blockhash-based fallback method:
    // A future block is picked, whose hash will provide the randomness.
    // We accept as low-impact that a miner mining this block could withhold it. A user seed/reveal system
    // to counteract miner withholding introduces too much complexity (need to penalize users etc).
    function requestRoll(bool useFallback) external {
        require(!this._isDisabled(), "rng-disabled");

        // If a roll is already scheduled, do nothing.
        if (isRolling()) { return; }

        if (useFallback) {
            // Two blocks from now, the block hash will provide the randomness to decide the outcome
            randomSeedBlock = block.number + 2;
        }
        else {
            chainlinkRequestId = requestRandomness(chainlinkKeyHash, chainlinkFee, block.timestamp);
        }

        // Calculate the probability for this roll, based on the current lastRollTime, before we update the latter.
        rollProbability = getProbability(block.timestamp);

        // Set the last roll time, which "consumes" parts of the total probability for a diagnosis
        lastRollTime = block.timestamp;

        emit RollInProgress(rollProbability);
    }

    // Callback: randomness is returned from Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == chainlinkRequestId, "invalid-request");
        chainlinkRandomNumber = randomness;
    }

    // Apply the results of the roll (run the randomness function, update NFTs).
    //
    // When using the block-hash based fallback randomness function:
    // If this is not called within 250 odd blocks, the hash of that block will no longer be accessible to us.
    // The roller thus has a possible reason *not* to call apply(), if the outcome is not as they desire.
    // We counteract this as follows:
    // - We consider an incomplete roll as a completed (which did not cause a state chance) for purposes of the
    //   compound probability. That is, you cannot increase the chance of any of the NFTs being diagnosed, you
    //   can only prevent it from happening. A caller looking to manipulate a roll would presumably desire a
    //   diagnosis, as they otherwise would simply do nothing.
    // - We counteract grieving (the repeated calling of pre-roll without calling apply, thus resetting the
    //   probability of a diagnosis) by letting anyone call `apply`, and emitting an event on `preroll`, to make
    //   it easy to watch for that.
    //
    // When using Chainlink VRF:
    //
    // In case we do not get a response from Chainlink within 2 hours, this can be called.
    //
    function applyRoll() external {
        require(isRolling(), "no-roll");

        bytes32 randomness;

        // Roll was started using the fallback random method based on the block hash
        if (randomSeedBlock > 0) {
            require(block.number > randomSeedBlock, "too-early");
            randomness = blockhash(randomSeedBlock);

            // The seed block is no longer available. We act as if the roll led to zero diagnoses.
            if (randomness <= 0) {
                resetRoll();
                return;
            }
        }

        // Roll was started using Chainlink VRF
        else {
            // No response from Chainlink
            if (chainlinkRandomNumber == 0 && block.timestamp - lastRollTime > 2 hours) {
                resetRoll();
                return;
            }

            require(chainlinkRandomNumber > 0, "too-early");
            randomness = bytes32(chainlinkRandomNumber);
        }

        _applyRandomness(randomness);
        resetRoll();
    }

    function _applyRandomness(bytes32 randomness) internal {
        for (uint i=0; i<this._totalSupply(); i++) {
            uint256 tokenId = this._tokenByIndex(i);

            // For each token, mix in the token id to get a new random number
            bytes32 hash = keccak256(abi.encodePacked(randomness, tokenId));

            // Now we want to convert the token hash to a number between 0 and 1.
            // - 64.64-bit fixed point is a int128  which represents the fraction `{int128}/(64**2)`.
            // - Thus, the lowest 64 bits of the int128 are essentially what is after the decimal point -
            //   the fractional part of the number.
            // - So taking only the lowest 64 bits from a token hash essentially gives us a random number
            //   between 0 and 1.

            // block hash is 256 bits - shift the left-most 64 bits into the right-most position, essentially
            // giving us a 64-bit number. Stored as an int128, this represents a fractional value between 0 and 1
            // in the format used by the 64.64 - fixed point library.
            int128 randomNumber = int128(uint256(hash) >> 192);
            //console.log("RANDOMNUMBER", uint256(randomNumber));

            if (randomNumber > rollProbability) {
                onDiagnosed(tokenId);
            }
        }
    }

    function resetRoll() internal {
        randomSeedBlock = 0;
        rollProbability = 0;
        chainlinkRequestId = 0;
        chainlinkRandomNumber = 0;
        emit RollComplete();
    }

    function isRolling() public view returns (bool) {
        return (randomSeedBlock > 0) || (chainlinkRequestId > 0);
    }

    function onDiagnosed(uint256 tokenId) internal virtual;
}
