// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./IBeepBoopExoSuit.sol";
import "./IBeepBoop.sol";

contract ProxyBeepBoopExoSuitSale is Ownable {
    /// @notice $BeepBoop
    IBeepBoop public immutable beepBoop;

    /// @notice The exo suit contract
    IBeepBoopExoSuit public immutable exoSuit;

    constructor(address exoSuit_, address beepBoop_) {
        exoSuit = IBeepBoopExoSuit(exoSuit_);
        beepBoop = IBeepBoop(beepBoop_);
    }

    /**
     * @notice Purchase a suit (max 5 using in-game)
     */
    function mintIngame(uint256 quantity) public {
        require(exoSuit.gameMintable(), "Game mint not open");
        uint256 cost = quantity * exoSuit.gameMintPrice();
        IBeepBoop(beepBoop).spendBeepBoop(msg.sender, cost);
        exoSuit.adminMint(msg.sender, quantity);
    }

    /**
     * @notice Transfer back the ownership of the contract
     */
    function transferNftContractOwnership() public onlyOwner {
        exoSuit.transferOwnership(msg.sender);
    }
}
