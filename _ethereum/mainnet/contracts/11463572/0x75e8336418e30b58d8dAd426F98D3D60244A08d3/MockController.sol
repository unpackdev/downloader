// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./IController.sol";

/* solium-disable */
contract MockController is IController {
    bytes32 public constant override ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant override HARVESTER_ROLE =
        keccak256(abi.encodePacked("HARVESTER"));

    address public override admin;
    address public override treasury;

    constructor(address _treasury) public {
        admin = msg.sender;
        treasury = _treasury;
    }

    function setAdmin(address _admin) external override {}

    function setTreasury(address _treasury) external override {}

    function grantRole(bytes32 _role, address _addr) external override {}

    function revokeRole(bytes32 _role, address _addr) external override {}

    function invest(address _vault) external override {}

    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external override {}

    function harvest(address _strategy) external override {}

    function skim(address _strategy) external override {}

    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    ) external override {}

    function withdrawAll(address _strategy, uint _min) external override {}

    function exit(address _strategy, uint _min) external override {}

    /* test helper */
    function _setTreasury_(address _treasury) external {
        treasury = _treasury;
    }
}
