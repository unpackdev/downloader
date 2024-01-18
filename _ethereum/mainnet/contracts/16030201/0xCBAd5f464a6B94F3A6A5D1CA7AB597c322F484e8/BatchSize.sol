// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Initializable.sol";

import "./IBatchSize.sol";

/**
 * @title Base contract for handling the general batch size limit
 * @author Shane van Coller, Jonas Sota
 */
abstract contract BatchSize is IBatchSize, Ownable, Initializable {
    uint16 public maxBatchSize;

    // solhint-disable-next-line func-name-mixedcase
    function __BatchSize_init(uint16 maxBatchSize_) internal onlyInitializing {
        maxBatchSize = maxBatchSize_;
    }

    function updateBatchSize(uint16 batchSize_) external onlyOwner {
        maxBatchSize = batchSize_;
    }

    /**
     * @notice Validates that the given list is of length `maxBatchSize` or less
     *
     * @param addresses_ List of addresses
     */
    modifier _checkBatchSizeAddr(address[] calldata addresses_) {
        require(addresses_.length <= maxBatchSize, "LC:BATCH_SIZE_TOO_BIG");
        _;
    }

    /**
     * @notice Validates that the given list is of length `maxBatchSize` or less
     *
     * @param ids_ List of uints, most likely representing id's
     */
    modifier _checkBatchSizeUint(uint256[] calldata ids_) {
        require(ids_.length <= maxBatchSize, "LC:BATCH_SIZE_TOO_BIG");
        _;
    }

    uint256[9] private __gap;
}
