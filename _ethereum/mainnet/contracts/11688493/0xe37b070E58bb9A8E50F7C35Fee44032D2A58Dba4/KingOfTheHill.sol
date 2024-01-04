// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./KOTH.sol";

contract KingOfTheHill is Ownable {
    KOTH private _koth;
    address private _wallet;
    bool private _isStrengthPowerUp;
    bool private _isDefensePowerUp;
    bool private _isAgilityPowerUp;
    uint256 private _strengthBonus;
    uint256 private _defenseBonus;
    uint256 private _agilityBonus;
    uint256 private _nbBlocksWinning; // default nbBlockLimit

    constructor(
        address owner,
        address wallet_,
        address koth_
    ) {
        _koth = KOTH(koth_);
        _wallet = wallet_;
        _nbBlocksWinning = 100;
        _strengthBonus = 10;
        _defenseBonus = 10;
        _agilityBonus = 5;
        transferOwnership(owner);
    }

    function koth() public view returns (address) {
        return address(_koth);
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function nbBlocksWinning() public view returns (uint256) {
        return _nbBlocksWinning;
    }

    function setNbBlocksWinning(uint256 nbBlocks) public onlyOwner() {
        require(nbBlocks > 0, "KingOfTheHill: nbBlocks must be greater than 0");
        _nbBlocksWinning = nbBlocks;
    }

    function strengthBonus() public view returns (uint256) {
        return _strengthBonus;
    }

    function setStrengthBonus(uint256 percentage) public onlyOwner() {
        //require("KingOfTheHill: Irration percentage")
        _strengthBonus = percentage;
    }

    function defenseBonus() public view returns (uint256) {
        return _defenseBonus;
    }

    function setDefenseBonus(uint256 percentage) public onlyOwner() {
        _defenseBonus = percentage;
    }

    function agilityBonus() public view returns (uint256) {
        return _agilityBonus;
    }

    function setAgilityBonus(uint256 nbBlock) public onlyOwner() {
        _agilityBonus = nbBlock;
    }

    function isStrengthPowerUp() public view returns (bool) {
        return _isStrengthPowerUp;
    }

    function isDefensePowerUp() public view returns (bool) {
        return _isDefensePowerUp;
    }

    function isAgilityPowerUp() public view returns (bool) {
        return _isAgilityPowerUp;
    }

    function pot() public view returns (uint256) {}

    function prize() public view returns (uint256) {}

    function buyPot() public {}

    function buyStrength() public {}

    function buyDefense() public {}

    function buyAgility() public {}

    receive() external payable {}

    // TODO REMOVE THIS AND CHANGE TEST IN KOTH
    function opSend(address recipient, uint256 amount) public {
        _koth.operatorSend(msg.sender, recipient, amount, "", "");
    }

    // TODO REMOVE THIS AND CHANGE TEST IN KOTH
    function opBurn(uint256 amount) public {
        _koth.operatorBurn(msg.sender, amount, "", "");
    }
}
