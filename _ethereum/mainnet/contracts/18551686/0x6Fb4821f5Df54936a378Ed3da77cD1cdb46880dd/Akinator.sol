// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

/**
 * @title Akinator
 * @tg: https://t.me/akinatorcoin
 * @tw: https://twitter.com/akinatorcoin
 * @wb: https://akinatorcoin.xyz
 *
 * The fabulous story of Akinator
 *
 * A while ago, Arnaud and his friend Jeff had decided to go on a trip into the far away lands of the East. During an expedition on dromedary's back they noticed on top of a small sand dune an object glittering under the sun . This aroused their curiosity, so they dismounted right away. They were extremely surprised to uncover an old oil lamp! It must have been buried under there for many years until it was brought to the open by the desert winds.
 *
 * Jeff joked :
 * - I know! Pick three wishes and rub it, a genie might come out!".
 * Nothing happened after their first try.
 * Still nothing after their second try.
 * After their third try, however, the lamp shone brightly and heated up quickly until it was so hot that Arnaud had to drop it into the sand.
 *
 * At that moment, dense smoke poured out of it and formed a small opaque cloud. It vanished little by little. Astonished, they saw a creature appear before them. It had the aspect of a man and looked quite friendly.
 *
 * It seemed to stretch, as if it had just woken up from a long sleep. Then a grave voice rang out:
 * "Hello, I am the renowned Akinator. I speak and understand all the languages of this world. You woke me up from a centuries-long sleep. However, this long rest did not affect my prodigious skills. I am capable of guessing who you are thinking about with a few questions. If I cannot, if you beat me, then I shall leave you alone. But be careful! Answer my questions accurately or... or you will take my place in the lamp."
 *
 * Our two friends were curious, but this warning urged them to remain cautious. They answered scrupulously the genie's questions and noted that what he had said was true; he easily guessed who were the characters they had in mind. He was very proud of this deed and started to sing and talk, talk, talk... and never seemed to stop. Then he asked for more riddles and again found the answers. He seemed to have inexhaustible energy and appeared to be more and more pleased with himself as time went by.
 *
 * The two travellers tried to slip away by taking advantage of his exhilaration. Yet there was no use trying; the genie was still floating in the air behind them, as free as the wind and asking relentlessly to play with them. Jeff picked up the lamp. They went back to the dromedaries and Jeff, puzzled, asked his friend:
 * "What are we going to do, Arnaud? He's following us everywhere. We'll never get rid of him!"
 * "We're going to bring him back to France. He wants to discover characters; then we'll give him what he wants."
 *
 * Such were the circumstances which brought Jeff and Arnaud to create the website akinator.com. Akinator would be allowed to play days and nights with the entire earth, thus satisfying his unfailing addiction.
 *
 * You too can try to trick Akinator. You will see that he is not infallible. But hush... he does not like to hear it. Be careful though: you must answer honestly. Remember the frightening warning of our genie!
 */

import "./ERC20.sol";
import "./Ownable.sol";

uint256 constant TOTAL_SUPPLY = 100_000_000 ether;

contract Akinator is Ownable, ERC20("Akinator", "AK") {
    bool public limited;
    uint256 public maxHoldingAmount;
    address public uniswapPool;

    constructor() {
        maxHoldingAmount = (TOTAL_SUPPLY * 25) / 10_000;
        limited = true;
        // router/position manager
        _approve(msg.sender, 0xC36442b4a4522E871399CD717aBDD847Ab11FE88, type(uint256).max);
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setPool(address _uniswapPool) external onlyOwner {
        uniswapPool = _uniswapPool;
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (uniswapPool == address(0)) {
            require(tx.origin == owner() || to == owner(), "TRADING IS NOT OPEN YET");
            return;
        }

        if (limited && from == uniswapPool) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "MAX WALLET AMOUNT EXCEEDED");
        }
    }
}
