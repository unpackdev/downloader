// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma abicoder v2;

import "./IWavemintV1DataAndEvents.sol";

interface IWavemintV1Info is IWavemintV1DataAndEvents {

    /**
     * @notice Get the total number of orders ever created in the Wavemint
     * @return The number of orders
     */
    function getOrderCount() external view returns (uint256);

    /**
     * @notice Get order information of a given order
     * @param _orderHash The id of the order, should be less than `getOrderCount`
     * @return Order information
     */
    function getOrderByHash(bytes32 _orderHash) external view returns (OrderStatus memory);


    function tokenInfo(address _token)
        external
        view
        returns (string memory _uri);

    function updateTokenInfo(
        address _token,
        string calldata _uri,
        address _royaltyOwners,
        uint96 _royaltyRates
    ) external;
}