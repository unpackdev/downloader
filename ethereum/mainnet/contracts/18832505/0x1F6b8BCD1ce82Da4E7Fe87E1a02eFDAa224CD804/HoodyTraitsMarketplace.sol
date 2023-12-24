// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IHoodyTraits {
    function listTraitsToMarketplace(uint16, uint16) external;

    function downTraitsFromMarketplace(uint16, uint16) external;

    function buyTraitFromMarketplace(uint16, uint16) external;
}

contract HoodyTraitsMarketplace is Ownable, ReentrancyGuard {
    address public hoodyTraits;

    struct TraitForSale {
        uint256 price;
        uint16 amount;
    }

    mapping(address => mapping(uint16 => TraitForSale))
        public traitsSaleInfoBySeller;

    uint8 public tradingFee = 5;

    event ListTrait(
        address indexed seller,
        uint16 indexed traitId,
        uint16 amount,
        uint256 price
    );
    event UpdateTraitPrice(
        address indexed seller,
        uint16 indexed traitId,
        uint256 price
    );
    event DownTrait(
        address indexed seller,
        uint16 indexed traitId,
        uint16 amount
    );
    event BuyTrait(
        address indexed seller,
        address indexed buyer,
        uint16 indexed traitId,
        uint16 amount
    );
    event AddTrait(
        address indexed seller,
        uint16 indexed traitId,
        uint16 amount
    );

    constructor() Ownable(msg.sender) {}

    function listNewTrait(
        uint16 _traitId,
        uint256 _price,
        uint16 _amount
    ) external {
        require(
            traitsSaleInfoBySeller[msg.sender][_traitId].amount == 0,
            "You already listed that trait."
        );
        IHoodyTraits(hoodyTraits).listTraitsToMarketplace(
            _traitId,
            _amount
        );

        traitsSaleInfoBySeller[msg.sender][_traitId] = TraitForSale(
            _price,
            _amount
        );

        emit ListTrait(msg.sender, _traitId, _amount, _price);
    }

    function addMoreTraits(uint16 _traitId, uint16 _amount) external {
        require(
            traitsSaleInfoBySeller[msg.sender][_traitId].amount > 0,
            "You didn't list that trait yet."
        );
        IHoodyTraits(hoodyTraits).listTraitsToMarketplace(
            _traitId,
            _amount
        );

        traitsSaleInfoBySeller[msg.sender][_traitId].amount += _amount;

        emit AddTrait(msg.sender, _traitId, _amount);
    }

    function buyTrait(
        address _seller,
        uint16 _traitId,
        uint16 _amount
    ) internal {
        require(_amount > 0, "Invalid amount.");
        require(
            traitsSaleInfoBySeller[_seller][_traitId].amount >= _amount,
            "Not enough amount."
        );

        traitsSaleInfoBySeller[_seller][_traitId].amount -= _amount;

        IHoodyTraits(hoodyTraits).buyTraitFromMarketplace(
            _traitId,
            _amount
        );

        emit BuyTrait(_seller, msg.sender, _traitId, _amount);
    }

    function buyTraits(
        address[] memory _sellers,
        uint16[] memory _traitIds,
        uint16[] memory _amounts
    ) external payable nonReentrant {
        require(_sellers.length == _traitIds.length, "Invalid param length!");
        require(_sellers.length == _amounts.length, "Invalid param length!");

        uint256 totalAmount = 0;
        for (uint i; i < _sellers.length; i++) {
            uint256 cost = traitsSaleInfoBySeller[_sellers[i]][_traitIds[i]]
                .price * _amounts[i];
            totalAmount += cost;
            buyTrait(_sellers[i], _traitIds[i], _amounts[i]);
            payable(_sellers[i]).transfer(cost * (100 - tradingFee) / 100);
        }

        require(totalAmount <= msg.value, "Not enough eth balance!");
        if (msg.value > totalAmount) {
            payable(msg.sender).transfer(msg.value - totalAmount);
        }
    }

    function downTrait(uint16 _traitId, uint16 _amount) external {
        require(
            traitsSaleInfoBySeller[msg.sender][_traitId].amount >= _amount,
            "Not enough amount."
        );
        IHoodyTraits(hoodyTraits).downTraitsFromMarketplace(
            _traitId,
            _amount
        );
        traitsSaleInfoBySeller[msg.sender][_traitId].amount -= _amount;

        emit DownTrait(msg.sender, _traitId, _amount);
    }

    function updateTraitPrice(uint16 _traitId, uint256 _price) external {
        require(
            traitsSaleInfoBySeller[msg.sender][_traitId].amount >= 0,
            "You didn't list that trait yet."
        );
        traitsSaleInfoBySeller[msg.sender][_traitId].price = _price;
        emit UpdateTraitPrice(msg.sender, _traitId, _price);
    }

    function withdrawFee(address payable _receiver) external onlyOwner {
        _receiver.transfer(address(this).balance);
    }

    function setTradingFee(uint8 _fee) external onlyOwner {
        tradingFee = _fee;
    }

    function setHoodyTraits(address _hoodyTraits) external onlyOwner {
        hoodyTraits = _hoodyTraits;
    }
}
