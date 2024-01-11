// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./WattsBurnerUpgradable.sol";

contract SlotiePokerGame is WattsBurnerUpgradable {
    
    bool public active;
    uint256 public generateFee;

    event CreateCode(address indexed creator, uint32 indexed code);

    constructor(address[] memory _admins, address _watts, address _transferExtender)
    WattsBurnerUpgradable(_admins, _watts, _transferExtender) {}

    function initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
       watts_burner_initialize(_admins, _watts, _transferExtender);
       generateFee = 100 ether;
       active = true;
    }

    function GenerateCode() external returns (uint32 code) {
        require(active, "Poker game inactive");
        code = uint32(uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, block.coinbase, msg.sender))));
        _burnWatts(generateFee);
        emit CreateCode(msg.sender, code);
    }

    function changeSettings(bool _active, uint256 _fee) external onlyRole(GameAdminRole) {
        active = _active;
        generateFee = _fee;
    }
}