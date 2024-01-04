// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";

interface GameForthInterface {
    function pushReport(uint256 payload) external;

    function purgeReports() external;
}

/**
 * @title TokenManualConsumer is a contract which is given data by a server
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract TokenManualConsumer is Ownable {
    int256 public currentAnswer;
    uint256 public updatedHeight;
    GameForthInterface public gameForth;
    mapping(address => bool) public authorizedRequesters;

    /**
     * @notice Deploy the contract
     * @dev Sets the storage for the specified addresses
     * @param _gameforth The Ampleforth contract to call
     */
    constructor(address _gameforth) public {
        _updateRequestDetails(_gameforth);
    }

    function updateRequestDetails(address _gameforth) external onlyOwner() {
        _updateRequestDetails(_gameforth);
    }

    function _updateRequestDetails(address _gameforth) private {
        require(_gameforth != address(0), "Cannot use zero address");
        gameForth = GameForthInterface(_gameforth);
    }

    /**
     * @notice Calls the Ampleforth contract's pushReport method with the response
     * from the oracle
     * @param _data The answer provided by the oracle, rGME/USD with 9 decimal points
     */
    function fulfillPushReport(int256 _data) external onlyOwner() {
        currentAnswer = _data;
        updatedHeight = block.number;
        GameForthInterface(gameForth).pushReport(uint256(_data));
    }

    /**
     * @notice Calls Ampleforth contract's purge function
     */
    function purgeReports() external onlyOwner() {
        GameForthInterface(gameForth).purgeReports();
    }
}
