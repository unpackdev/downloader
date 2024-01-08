// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Context.sol";

import "./IOracle.sol";

contract Oracle is IOracle, Context {
    struct DataPoint {
        uint256 value;
        uint256 timestamp;
    }
    mapping(address => DataPoint) public data;

    address public immutable factory;

    uint256 public immutable maxTimeout;

    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // solhint-disable-next-line func-visibility
    constructor(uint256 _maxTimeout, address _factory) {
        maxTimeout = _maxTimeout;
        factory = _factory;
    }

    modifier onlyManagerOrAdmin virtual {
        address sender = _msgSender();
        require(
            AccessControl(factory).hasRole(MANAGER_ROLE, sender) ||
                AccessControl(factory).hasRole(0x00, sender),
            "Access error"
        );
        _;
    }

    function uploadData(address[] calldata tokens, uint256[] calldata values)
        external
        override
        onlyManagerOrAdmin
    {
        require(tokens.length == values.length, "Oracle: Error inputs");

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        for (uint256 i = 0; i < tokens.length; i++) {
            data[tokens[i]].value = values[i];
            data[tokens[i]].timestamp = timestamp;
        }
    }

    function getData(address[] calldata tokens)
        external
        view
        override
        returns (bool[] memory isValidValue, uint256[] memory tokensPrices)
    {
        isValidValue = new bool[](tokens.length);
        tokensPrices = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            DataPoint memory _data = data[tokens[i]];

            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp - maxTimeout < _data.timestamp) {
                isValidValue[i] = true;
                tokensPrices[i] = _data.value;
            } else {
                isValidValue[i] = false;
            }
        }
    }

    function getTimestampsOfLastUploads(address[] calldata tokens)
        external
        view
        override
        returns (uint256[] memory timestamps)
    {
        timestamps = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            timestamps[i] = data[tokens[i]].timestamp;
        }
    }
}
