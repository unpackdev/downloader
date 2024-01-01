// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

/*
010001010100000101010100001000000100110101011001
001000000100000101010011010100110100001001010101
0101001001000111010001010101001000100000

Telegram: https://t.me/assburgers_entry


Website: https://www.assburgers.club/

X: x.com/assburgers_club 

*/

contract Assburgers is ERC20, Ownable {
    /* Variables */
    bool public TradeEnabled = false;
    bool public limitsInEffect = true;

    uint256 public maxBuy;
    uint256 public maxSell;
    uint256 public maxBurgers;

    address public router = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;

    /* Mappings */
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _excludedFromMaxWallet;
    mapping(address => bool) public bots;

    constructor(address initialOwner) ERC20("Assburgers", "ASSBURGERS") {
        _mint(msg.sender, 1000000000 * 10**18); // 1bl
        Ownable(initialOwner);
        maxBuy = 20000000 * 10**18; // 20ml
        maxSell = 20000000 * 10**18; // 20ml
        maxBurgers = 20000000 * 10**18; // 20ml
        _excludedFromMaxWallet[initialOwner] = true;
        _excludedFromMaxWallet[router] = true;
    }

    /* Only Owner Admin functions */

    // CAN ONLY BE CALLED ONCE
    function InitTrading() public onlyOwner {
        TradeEnabled = true;
    }

    // REMOVES POTENTIAL BAD ACTORS
    function tagBot(address wallet, bool state) public onlyOwner {
        bots[wallet] = state;
    }

    // MUST EXECUTE ON PAIR AFTER ADDING LIQUIDITY
    function exclude(address wallet, bool state) public onlyOwner {
        _excludedFromMaxWallet[wallet] = state;
    }

    // MUST EXECUTE ON PAIR AFTER ADDING LIQUIDITY
    function addMMP(address mm, bool state) public onlyOwner {
        automatedMarketMakerPairs[mm] = state;
    }

    // REMOVES MAXBUY MAXSELL MAXBURGERS
    function removeLimits(bool state) public onlyOwner {
        limitsInEffect = state;
    }

    // EDITS MAXBUY MAXSELL MAXBURGERS
    function editLimits(
        uint256 mb,
        uint256 ms,
        uint256 bag
    ) public onlyOwner {
        maxBuy = mb * 10**18;
        maxSell = ms * 10**18;
        maxBurgers = bag * 10**18;
    }

    /* Burn */
    function burn(uint256 amount) public {
        require(amount > 0);
        super._burn(msg.sender, amount);
    }

    /* Transfer */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!bots[from] && !bots[to], "no more burgers for you");
        if (from != owner()) {
            require(TradeEnabled, "trading has not been enabled");
        }
        if (limitsInEffect) {
            if (automatedMarketMakerPairs[to]) {
                require(amount <= maxSell, "Cannot sell over max sell limit");
            } else if (automatedMarketMakerPairs[from]) {
                require(amount <= maxBuy, "Cannot buy over max buy limit");

                if (!_excludedFromMaxWallet[to]) {
                    require(
                        amount + balanceOf(to) <= maxBurgers,
                        "about to exceed max Wallet"
                    );
                }
            }
        }
        super._transfer(from, to, amount);
    }
}
