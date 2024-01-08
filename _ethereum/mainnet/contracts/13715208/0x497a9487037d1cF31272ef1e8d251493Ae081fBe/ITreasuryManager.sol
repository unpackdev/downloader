// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface ITreasuryManager is ILazyInitCapableElement {

    struct TransferEntry {
        address token;
        uint256[] objectIds;
        uint256[] values;
        address receiver;
        bool safe;
        bool batch;
        bool withData;
        bytes data;
    }

    function transfer(address token, uint256 value, address receiver, uint256 tokenType, uint256 objectId, bool safe, bool withData, bytes calldata data) external returns(bool result, bytes memory returnData);
    function batchTransfer(TransferEntry[] calldata transferEntries) external returns(bool[] memory results, bytes[] memory returnDatas);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);

    function setAdditionalFunction(bytes4 selector, address newServer, bool log) external returns (address oldServer);
    event AdditionalFunction(address caller, bytes4 indexed selector, address indexed oldServer, address indexed newServer);
}