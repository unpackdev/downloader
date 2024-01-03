// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IRMU.sol";
import "./IHopeNonTradable.sol";
import "./IHope.sol";

contract HopeVendingMachineV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IRMU public rmu;
    IHope public hope;
    IHopeNonTradable public hopeNonTradable;

    mapping(uint256 => uint256) public cardCosts;

    event CardAdded(uint256 card, uint256 cost);
    event Redeemed(address indexed user, uint256 amount, uint256 costPerUnit);

    constructor(IRMU _rmu, IHopeNonTradable _hopeNonTradable, IHope _hope) public {
        rmu = _rmu;
        hopeNonTradable = _hopeNonTradable;
        hope = _hope;
    }

    function getCardCosts(uint256[] memory _cardIds) public view returns(uint256[] memory) {
        uint256[] memory result = new uint256[](_cardIds.length);

        for (uint256 i = 0; i < _cardIds.length; ++i) {
            result[i] = cardCosts[_cardIds[i]];
        }

        return result;
    }

    function addCards(uint256[] memory _cardIds, uint256[] memory _costs) public onlyOwner {
        require(_cardIds.length == _costs.length, "Arrays must have same length");

        for (uint256 i = 0; i < _cardIds.length; ++i) {
            cardCosts[_cardIds[i]] = _costs[i];
            emit CardAdded(_cardIds[i], _costs[i]);
        }
    }

    function redeem(uint256 _card, uint256 _amount, bool _useHopeNonTradable) public nonReentrant {
        require(cardCosts[_card] != 0, "NFT not found");

        uint256 supply = rmu.totalSupply(_card);
        uint256 maxSupply = rmu.maxSupply(_card);

        if (supply.add(_amount) > maxSupply) {
            _amount = maxSupply.sub(supply);
            require(_amount != 0, "No NFTs left");
        }

        uint256 totalPrice = cardCosts[_card].mul(_amount);

        if (_useHopeNonTradable) {
            hopeNonTradable.burn(msg.sender, totalPrice);
        } else {
            hope.burn(msg.sender, totalPrice);
        }

        rmu.mint(msg.sender, _card, _amount, "");

        emit Redeemed(msg.sender, _amount, cardCosts[_card]);
    }
}