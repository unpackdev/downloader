/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IFactory {
    struct TemplateInfo {
        address template;
        address btemplate;
    }

    event Deployed(address deployed, address owner);
    event NewTemplate(bytes32 indexed key, address template, address beacon);
    event UpdatedTemplate(bytes32 indexed key, address template);
    event DeletedTemplate(bytes32 indexed key);
    event FeeChanged(uint256 prevFee, uint256 fee);
    event FeeToChanged(address prevFeeTo, address feeTo);

    function deploy(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function deployWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function compute(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable);

    function computeWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable);

    function clone(
        address templateAddr,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function computeClone(address templateAddr, bytes memory initializationCallData)
        external
        view
        returns (address deployable);

    function getPrice() external view returns (uint256 price);

    function addTemplate(address templateAddr) external;

    function updateTemplate(bytes32 key, address templateAddr) external;

    function removeTemplate(bytes32 key) external;

    function changeFee(uint256 newFee) external;

    function changeFeeTo(address payable newFeeTo) external;

    function collect(address tokenAddr) external;
}
