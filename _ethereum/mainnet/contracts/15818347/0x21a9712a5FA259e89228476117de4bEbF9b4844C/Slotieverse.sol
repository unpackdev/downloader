// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./WattsBurnerUpgradable.sol";
import "./PausableUpgradeable.sol";

contract Slotieverse is WattsBurnerUpgradable, PausableUpgradeable {
    mapping(uint256 => uint256) public ammoPrice;

    event BuyAmmo(address indexed buyer, uint256 indexed ammoId, uint256 indexed amount, uint256 wattsBurned);
    event AddAmmoIdEvent(address indexed sender, uint256 indexed ammoId, uint256 indexed ammoPrice, bytes32 identifier);
    event UpdateAmmoIdEvent(address indexed sender, uint256 indexed ammoId, uint256 indexed ammoPrice, bytes32 identifier);
    event RemoveAmmoIdEvent(address indexed sender, uint256 indexed ammoId, bytes32 identifier);

    constructor(address[] memory _admins, address _watts, address _transferExtender)
    WattsBurnerUpgradable(_admins, _watts, _transferExtender) {}

    modifier validAmmo(uint256 ammoId) {
        require(ammoPrice[ammoId] > 0, "Invalid ammo Id");
        _;
    }

    function initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
       watts_burner_initialize(_admins, _watts, _transferExtender);
       __Pausable_init();
    }

    function PurchaseAmmo(uint256 ammoId, uint256 amount) external whenNotPaused() validAmmo(ammoId) {
        uint256 burnFee = ammoPrice[ammoId] * amount;
        _burnWatts(burnFee);
        emit BuyAmmo(msg.sender, ammoId, amount, burnFee);
    }

    function AddAmmoId(uint256 ammoId, uint256 price, bytes32 identifier) external onlyRole(GameAdminRole) {
        require(ammoPrice[ammoId] == 0, "Ammo ID already registered. Please call update function");
        ammoPrice[ammoId] = price;
        emit AddAmmoIdEvent(msg.sender, ammoId, price, identifier);        
    }

    function UpdateAmmoId(uint256 ammoId, uint256 price, bytes32 identifier) external onlyRole(GameAdminRole) validAmmo(ammoId) {
        require(price > 0, "Price cannot be zero. Please call delete function");
        ammoPrice[ammoId] = price;
        emit UpdateAmmoIdEvent(msg.sender, ammoId, price, identifier);        
    }

    function DeleteAmmoId(uint256 ammoId, bytes32 identifier) external onlyRole(GameAdminRole) validAmmo(ammoId) {
        delete ammoPrice[ammoId];
        emit RemoveAmmoIdEvent(msg.sender, ammoId, identifier);        
    }

    function pauseContract() external onlyRole(GameAdminRole) {
        _pause();
    }

    function unpauseContract() external onlyRole(GameAdminRole) {
        _unpause();
    }
}