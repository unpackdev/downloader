// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./TellorMaster.sol";
import "./UsingTellor.sol";

/**
 * @title Tellor Lens
 * @dev A contract to aggregate and simplify calls to the Tellor oracle.
 **/
contract Lens is UsingTellor {
    TellorMaster public proxy;

    /*Constructor*/
    /**
     * @dev the constructor sets the storage address and owner
     * @param _master is the Tellor proxy contract address.
     */
    constructor(address payable _master) public UsingTellor(_master) {
        proxy = TellorMaster(_master);
    }

    /**
     * @return Returns the current reward amount.
        TODO remove once https://github.com/proxy-io/TellorCore/issues/109 is implemented and deployed.
     */
    function currentReward() external view returns (uint256) {
        uint256 timeDiff = now -
            proxy.getUintVar(keccak256("timeOfLastNewValue"));
        uint256 rewardAmount = 1e18;

        uint256 rewardAccumulated = (timeDiff * rewardAmount) / 300; // 1TRB every 6 minutes.

        uint256 tip = proxy.getUintVar(keccak256("currentTotalTips")) / 10; // Half of the tips are burnt.
        return rewardAccumulated + tip;
    }

    struct value {
        uint256 timestamp;
        uint256 value;
    }

    /**
     * @param requestID is the ID for which the function returns the values for.
     * @param count is the number of last values to return.
     * @return Returns the last N values for a request ID.
     */
    function getLastNewValues(uint256 requestID, uint256 count)
        external
        view
        returns (value[] memory)
    {
        uint256 totalCount = proxy.getNewValueCountbyRequestId(requestID);
        if (count > totalCount) {
            count = totalCount;
        }
        value[] memory values = new value[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 ts = proxy.getTimestampbyRequestIDandIndex(
                requestID,
                totalCount - i - 1
            );
            uint256 v = proxy.retrieveData(requestID, ts);
            values[i] = value({timestamp: ts, value: v});
        }

        return values;
    }

    /**
     * @return Returns the contract owner that can do things at will.
     */
    function _deity() external view returns (address) {
        return proxy.getAddressVars(keccak256("_deity"));
    }

    /**
     * @return Returns the contract owner address.
     */
    function _owner() external view returns (address) {
        return proxy.getAddressVars(keccak256("_owner"));
    }

    /**
     * @return Returns the contract pending owner.
     */
    function pending_owner() external view returns (address) {
        return proxy.getAddressVars(keccak256("pending_owner"));
    }

    /**
     * @return Returns the contract address that executes all proxy calls.
     */
    function tellorContract() external view returns (address) {
        return proxy.getAddressVars(keccak256("tellorContract"));
    }

    /**
     * @param requestID is the ID for which the function returns the total tips.
     * @return Returns the current tips for a give request ID.
     */
    function totalTip(uint256 requestID) external view returns (uint256) {
        return proxy.getRequestUintVars(requestID, keccak256("totalTip"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the last time when a value was submitted.
     */
    function timeOfLastNewValue() external view returns (uint256) {
        return proxy.getUintVar(keccak256("timeOfLastNewValue"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the total number of requests from user thorugh the addTip function.
     */
    function requestCount() external view returns (uint256) {
        return proxy.getUintVar(keccak256("requestCount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the total oracle blocks.
     */
    function _tBlock() external view returns (uint256) {
        return proxy.getUintVar(keccak256("_tBlock"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the current block difficulty.
     *
     */
    function difficulty() external view returns (uint256) {
        return proxy.getUintVar(keccak256("difficulty"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable is used to calculate the block difficulty based on
     * the time diff since the last oracle block.
     */
    function timeTarget() external view returns (uint256) {
        return proxy.getUintVar(keccak256("timeTarget"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the highest api/timestamp PayoutPool.
     */
    function currentTotalTips() external view returns (uint256) {
        return proxy.getUintVar(keccak256("currentTotalTips"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the number of miners who have mined this value so far.
     */
    function slotProgress() external view returns (uint256) {
        return proxy.getUintVar(keccak256("slotProgress"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the cost to dispute a mined value.
     */
    function disputeFee() external view returns (uint256) {
        return proxy.getUintVar(keccak256("disputeFee"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     */
    function disputeCount() external view returns (uint256) {
        return proxy.getUintVar(keccak256("disputeCount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks stake amount required to become a miner.
     */
    function stakeAmount() external view returns (uint256) {
        return proxy.getUintVar(keccak256("stakeAmount"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the number of parties currently staked.
     */
    function stakerCount() external view returns (uint256) {
        return proxy.getUintVar(keccak256("stakerCount"));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function concat(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(bytes(a), bytes(b)));
    }
}
