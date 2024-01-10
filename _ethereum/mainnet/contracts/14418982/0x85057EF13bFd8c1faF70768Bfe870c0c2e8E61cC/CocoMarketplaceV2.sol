// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICoco.sol";
import "./Ownable.sol";
            
// @author 0xBori <https://twitter.com/0xBori>   
contract CocoMarketplaceV2 is Ownable {

    uint256 public whitelistCounter;
    uint256 public raffleCounter;
    uint256 public whitelistTimer;
    uint256 public raffleTimer;
    address public cocoAddress;
    mapping(uint => Whitelist) whitelists;
    mapping(uint => Raffle) raffles;
    mapping(uint => mapping(address => bool)) _hasPurchasedWL;
    mapping(uint => mapping(address => bool)) _hasPurchasedRaffle;

    struct Whitelist {
        uint256 price;
        uint256 amount;
        uint256 timestamp;
    }

    struct Raffle {
        uint256 price;
        uint256 endTime;
        bool capped;
    }

    event PurchaseWL (uint256 indexed _id, address indexed _address, string _name);
    event EnterRaffle (uint256 indexed _id, address indexed _address, uint256 _amount, string _name);

    constructor() { 
        cocoAddress = 0x133B7c4A6B3FDb1392411d8AADd5b8B006ad69a4;
        whitelistCounter = 33;
        whitelistTimer = 60 * 60 * 24;
        raffleTimer = whitelistTimer;
    }

    function enterRaffle(uint256 _id, uint256 _amount, string memory _name) public {
        require(
            block.timestamp < raffles[_id].endTime,
            "Raffle ended."
        );

        if (raffles[_id].capped) {
            require(
                !_hasPurchasedRaffle[_id][msg.sender],
                "Already entered"
            );
            _hasPurchasedRaffle[_id][msg.sender] = true;
        }

        ICoco(cocoAddress).burnFrom(msg.sender, raffles[_id].price * _amount);
        emit EnterRaffle(_id, msg.sender, _amount, _name);
    }

    function purchase(uint256 _id, string memory _name) public {
        require(
            block.timestamp > whitelists[_id].timestamp,
            "Not live yet."
        );
        require(
            whitelists[_id].amount != 0,
            "No spots left"
        );
       require(
           !_hasPurchasedWL[_id][msg.sender],
           "Address has already purchased");

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchasedWL[_id][msg.sender] = true;
        ICoco(cocoAddress).burnFrom(msg.sender, whitelists[_id].price);

        emit PurchaseWL(_id, msg.sender, _name);
    }

    function addWhitelist(uint256 _amount, uint256 _price) external onlyOwner {
        whitelists[whitelistCounter++] = Whitelist(
            _price * 10 ** 18,
            _amount,
            block.timestamp + whitelistTimer
        );
    }

    function addRaffle(uint256 _price, bool _capped) external onlyOwner {
        raffles[raffleCounter++] = Raffle(
            _price * 10 ** 18,
            block.timestamp + raffleTimer,
            _capped
        );
    }

    function editWhitelist(uint256 _id, uint256 _amount, uint256 _price, uint256 _timestamp) external onlyOwner {
        whitelists[_id].amount = _amount;
        whitelists[_id].price = _price * 10 ** 18;
        whitelists[_id].timestamp = _timestamp;
    }

    function editWLAmount(uint256 _id, uint256 _amount) external onlyOwner {
        whitelists[_id].amount = _amount;
    }

    function editWLPrice(uint256 _id, uint256 _price) external onlyOwner {
        whitelists[_id].price = _price * 10 ** 18;
    }

    function editWLTimestamp(uint256 _id, uint256 _timestamp) external onlyOwner {
        whitelists[_id].timestamp = _timestamp;
    }

    function editRaffle(uint256 _id, uint256 _price, bool _capped, uint256 _timestamp) external onlyOwner {
        raffles[_id].price = _price * 10 ** 18;
        raffles[_id].capped = _capped;
        raffles[_id].endTime = _timestamp;
    }

    function editRaffleAmount(uint256 _id, bool _capped) external onlyOwner {
        raffles[_id].capped = _capped;
    }

    function editRafflePrice(uint256 _id, uint256 _price) external onlyOwner {
        raffles[_id].price = _price * 10 ** 18;
    }

    function editRaffleEnd(uint256 _id, uint256 _timestamp) external onlyOwner {
        raffles[_id].endTime = _timestamp;
    }

    function skipRaffleIndex() external onlyOwner {
        // Extremely unlikely this overflows
        unchecked {
            ++raffleCounter;
        }
    }

    function setCocoAddress(address _cocoAddress) public onlyOwner {
        cocoAddress = _cocoAddress;
    }

    function setWhitelistTimer(uint256 _time) external onlyOwner {
        whitelistTimer = _time;
    }

    function setRaffleTimer(uint256 _time) external onlyOwner {
        raffleTimer = _time;
    }

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function getRaffle(uint256 _id) public view returns (Raffle memory) {
        return raffles[_id];
    }

    function hasPurchasedWL(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchasedWL[_id][_address];
    }

    function hasPurchasedRaffle(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchasedRaffle[_id][_address];
    }

    function isCappedRaffle(uint256 _id) public view returns (bool) {
        return raffles[_id].capped;
    }
}
