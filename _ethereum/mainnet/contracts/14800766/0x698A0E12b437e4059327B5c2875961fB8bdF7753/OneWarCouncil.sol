// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./IOneWar.sol";
import "./IOneWarCouncil.sol";

contract OneWarCouncil is IOneWarCouncil, ERC20 {
    IOneWar public oneWar;
    mapping(uint256 => bool) public redeemed;

    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    constructor(IOneWar _oneWar) ERC20("OneWar Council", "OWC") {
        oneWar = _oneWar;
    }

    function burn(uint256 _value) public override {
        _burn(msg.sender, _value);
    }

    function redeemableCouncilTokens(uint256[] calldata _settlements) public view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _settlements.length; ++i) {
            require(oneWar.isSettled(_settlements[i]), "location is not settled");
            if (!redeemed[_settlements[i]]) {
                amount += 1;
            }
        }

        return amount;
    }

    function redeemCouncilTokens(uint256[] calldata _settlements) public override {
        uint256 amount = 0;
        for (uint256 i = 0; i < _settlements.length; ++i) {
            require(oneWar.isSettled(_settlements[i]), "location is not settled");
            require(oneWar.isRulerOrCoruler(msg.sender, _settlements[i]), "caller is not settlement ruler or co-ruler");
            require(!redeemed[_settlements[i]], "council tokens have already been redeemed");
            redeemed[_settlements[i]] = true;
            amount += 1;
        }

        _mint(msg.sender, amount * GOLD_DENOMINATION);
    }
}
