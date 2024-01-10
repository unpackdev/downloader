// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./I888888Game.sol";
import "./IFortunaToken.sol";

contract Fortuna is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IFortunaToken public fortunaToken;
    I888888Game public game;
    IERC20 public weth;

    address public team;

    uint256 public queueRolls;

    constructor() {
        team = msg.sender;
        game = I888888Game(0x11cFC32eEa4e092F9df0282BB8f99C2eEC5ce9e5);
        weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        weth.safeApprove(address(game), type(uint256).max);
    }

    // roll a dice
    /// @param _amount how many times to roll
    function roll(uint256 _amount) public {
        require(_amount > 0, "Must roll at least once.");

        weth.safeTransferFrom(
            msg.sender,
            address(this),
            uint256(_amount).mul(game.ticketSize())
        );

        queueRolls = queueRolls.add(_amount);

        while (queueRolls >= 5) {
            queueRolls = queueRolls.sub(5);
            game.rollMultipleDice(uint32(5));
        }

        fortunaToken.mint(msg.sender, _amount.mul(10**18));
    }

    // manually roll remaining dice in queue (if any)
    function rollRemaining() public {
        require(queueRolls > 0, "Must have at least one roll in the queue.");

        queueRolls = 0;
        game.rollMultipleDice(uint32(queueRolls));
    }

    // collect revenue split from the game (if any)
    function claimRevenueSplit() public onlyOwner {
        game.collectRevenueSplit();
    }

    function withdrawAll() public onlyOwner {
        require(game.isGameOver(), "Cannot withdraw until game is over.");

        // send 8.88% to team
        weth.safeTransfer(
            team,
            weth.balanceOf(address(this)).mul(111).div(1250)
        );

        // send 91.12% to governance multisig
        weth.safeTransfer(owner(), weth.balanceOf(address(this)));
    }

    function setFortunaToken(address _fortunaToken) public onlyOwner {
        require(
            address(fortunaToken) == address(0),
            "Fortuna token already set."
        );

        fortunaToken = IFortunaToken(_fortunaToken);
    }
}
