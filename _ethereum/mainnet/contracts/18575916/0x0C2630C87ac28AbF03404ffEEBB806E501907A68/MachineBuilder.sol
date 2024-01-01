// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./IERC1155Mintable.sol";
import "./AccessProtected.sol";
import "./LimitPerWallet.sol";
import "./RandomGenerator.sol";
import "./SignatureProtected.sol";
import "./TimeProtected.sol";
import "./MachineParts.sol";
import "./console.sol";

contract MachineBuilder is AccessProtected, TimeProtected, Ownable {
    IERC1155Mintable public erc1155Contract;
    MachineParts public machinePartsContract;

    uint256 public fromTimestamp;
    uint256 public toTimestamp;

    constructor(address _erc1155Address, address _machinePartsContract) {
        erc1155Contract = IERC1155Mintable(_erc1155Address);
        machinePartsContract = MachineParts(_machinePartsContract);
    }

    function setFromTimestamp(uint256 _fromTimestamp) external onlyOwner {
        fromTimestamp = _fromTimestamp;
    }

    function setToTimestamp(uint256 _toTimestamp) external onlyOwner {
        toTimestamp = _toTimestamp;
    }

    function mint(
        uint256 _primaryCore,
        uint256 _controlUnit,
        uint256 _thermoJuice,
        uint256 _originator
    ) external onlyUser {
        isMintOpen(fromTimestamp, toTimestamp);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        burn(_primaryCore, _controlUnit, _thermoJuice, _originator);

        ids[0] = (_primaryCore << 6) | ((_controlUnit - 4) << 4) | ((_thermoJuice - 8) << 2) | (_originator - 12);
        amounts[0] = 1;

        erc1155Contract.mint(msg.sender, ids, amounts);
    }

    function burn(uint256 _primaryCore, uint256 _controlUnit, uint256 _thermoJuice, uint256 _originator) internal {
        require(_primaryCore >= 0 && _primaryCore <= 3, "Invalid Primary Core");
        require(_controlUnit >= 4 && _controlUnit <= 7, "Invalid Control Unit");
        require(_thermoJuice >= 8 && _thermoJuice <= 11, "Invalid Thermo Juice");
        require(_originator >= 12 && _originator <= 15, "Invalid Originator");

        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);

        ids[0] = _primaryCore;
        ids[1] = _controlUnit;
        ids[2] = _thermoJuice;
        ids[3] = _originator;

        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;

        machinePartsContract.burn(msg.sender, ids, amounts);
    }
}
