// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/** 
    Waterfall Mint
    Author: 0xInuarashi
    Library: CypherMate

    In the waterfall mint, there are 3 time-conditions:

        1/ If the time hasn't started yet, the supply MUST be in-bounds.
        2/ If the time is in-bounds, the supply MUST not be above END.
        3/ If the time has ended, the waterfall has ENDED.

    In a waterfall mint, we have the following parameters:
    
        currentTokenId_: The current Token ID to be minted
        mintAmount_: The amount to be minted with incremental Token ID
        timeStart_: The unix timestamp to start the waterfall on a TIME TRIGGER
        timeEnd_: The unix timestamp to end all activity on the waterfall
        tokenIdStart_: The Token ID to start the waterfall on a TOKEN ID TRIGGER 
        tokenIdEnd_: The Token ID to end all activity the waterfall

    _checkWaterfallState throws an error due to require-statements when the conditions
    are not fulfilled.

    _returnWaterfallState does not throw and returns a boolean instead. This is useful
    for making your own custom errors OR returning states for front-end functions to use.

    BOTH should always result in the same state 
    (if require throws, _return should be false)
*/


abstract contract WaterfallMint {
    
    function _checkWaterfallState(uint256 currentTokenId_, uint256 mintAmount_, 
    uint256 timeStart_, uint256 timeEnd_,
    uint256 tokenIdStart_, uint256 tokenIdEnd_) internal virtual view {

        // If the time hasn't started yet, the supply must be in-bounds
        if (block.timestamp < timeStart_) {
            require(currentTokenId_ >= tokenIdStart_ &&
                    (currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1),
                    "_checkWaterfallState: State 1 conditions not met!");
        }

        // If the time is in-bounds, the supply must not be above end
        if (block.timestamp >= timeStart_ &&
            block.timestamp <= timeEnd_) {
            require((currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1),
                    "_checkWaterfallState: State 2 conditions not met!");
        }

        // If the time is above end, it's over!
        require(block.timestamp <= timeEnd_,
                "_checkWaterfallState: Waterfall has ended!");

    }

    function _returnWaterfallState(uint256 currentTokenId_, uint256 mintAmount_, 
    uint256 timeStart_, uint256 timeEnd_,
    uint256 tokenIdStart_, uint256 tokenIdEnd_) internal virtual view returns (bool) {

        // If the time hasn't started yet, the supply must be in-bounds
        if (block.timestamp < timeStart_) {
            if (currentTokenId_ >= tokenIdStart_ &&
                (currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1)) {
                return true;
            }
        }

        // If the time is in-bounds, the supply must not be above end
        if (block.timestamp >= timeStart_ &&
            block.timestamp <= timeEnd_) {
            if ((currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1)) {
                return true;
            }
        }

        // the third require is not required here, because this function is 
        // false-by-default vs true-by-default of the require statement _check
        // function above, thus, if block.timestamp is > timeEnd_, it falls to false.
        // if it's < timeEnd_, its catched by the second if-block above assuming
        // already that it is within time-bounds., which is exactly the 
        // condition we need assuming block.timestamp is < timeEnd_.
        return false;
    }
}