// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract RickRoll is ERC20, Ownable {
    bool public isBlacklistEnabled;
    mapping(address => bool) public pair;

    mapping(address user => bool isBlacklisted) public blacklist;

    error SenderIsBlacklisted();
    error RecipientIsBlacklisted();
    error CannotBuyMoreThan1PercentOfSupply();

    constructor() ERC20("Rickroll", "RICK") Ownable(msg.sender) {
        uint total_supply = 1000000000000000 * 1e18;
        _mint(msg.sender, total_supply);
        isBlacklistEnabled = true;
    }

    function disableBlacklist() external onlyOwner {
        isBlacklistEnabled = false;
    }

    function setPair(address _pair, bool _state) external onlyOwner {
        pair[_pair] = _state;
    }

    function setBlacklist(address user, bool isBlacklisted) external onlyOwner {
        blacklist[user] = isBlacklisted;
    }

    function _update(address from, address to, uint amount) internal override {
        if (isBlacklistEnabled) {
            if (blacklist[from]) {revert SenderIsBlacklisted();}
            if (blacklist[to]  ) {revert RecipientIsBlacklisted();}
        }
        if(pair[from] && to != owner()) {
            // can buy max 1% of supply
            if(balanceOf(to) + amount > totalSupply() / 100) {
                revert CannotBuyMoreThan1PercentOfSupply();
            }
        }
        super._update(from, to, amount);
    }
}