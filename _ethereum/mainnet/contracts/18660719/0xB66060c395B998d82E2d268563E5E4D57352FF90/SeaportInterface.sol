// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./SeaportStructs.sol";


interface SeaportInterface {
  
function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

}