// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "./NutDistributor.sol";
import "./SafeERC20.sol";

// @notice This contract is a version of NutDistributor that allows
// the epoch intervals to be changed for testing

contract TestNutDistributor is NutDistributor {
    using SafeMath for uint;
    function initialize (
        address nutAddr,
        address _governor,
        uint blocks_per_epoch
    ) external initializer {
        initialize(nutAddr, _governor);
	BLOCKS_PER_EPOCH = blocks_per_epoch;

        // config echoMap which indicates how many tokens will be distributed at each epoch
        for (uint i = 0; i < NUM_EPOCH; i++) {
            Echo storage echo =  echoMap[i];
            echo.id = i;
            echo.endBlock = DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(i.add(1)));
            uint amount = DIST_START_AMOUNT.div(i.add(1));
            if (amount < DIST_MIN_AMOUNT) {
                amount = DIST_MIN_AMOUNT;
            }
            echo.amount = amount;
        }
    }

    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "test.nutdistrib";
   }
}
