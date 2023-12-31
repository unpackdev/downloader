//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./ERC20Upgradeable.sol";

import "./SteroidsGame.sol";

/**
 * @title SteroidsToken
 * @author gotbit
 * @notice Steroids token contract, developed specifically for the Steroids game
 */
contract SteroidsToken is ERC20Upgradeable {
    SteroidsGame public game;

    /// @notice Can initialize token params after creation and mint tokens
    /// @param name - token name
    /// @param symbol - token symbol
    /// @param totalSupply - token total supply
    /// @param holder - token supply recepient
    /// @param game_ - steroids game contract instance
    function initialize(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address holder,
        SteroidsGame game_
    ) external initializer {
        require(totalSupply >= 10 ** 3, 'Supply too low');
        require(!_emptyStr(name), 'Empty name');
        require(!_emptyStr(symbol), 'Empty symbol');
        __ERC20_init(name, symbol);
        game = game_;
        _mint(holder, totalSupply);
    }

    /// @notice Returns true if a string is empty
    /// @param a - the checked string
    /// @return true if a string is empty, else - false
    function _emptyStr(
        string memory a
    ) private pure returns (bool) {
        return bytes(a).length == 0;
    }

    /// @notice Overriden ERC20 function _beforeTokenTransfer
    /// @param from - token sender
    /// @param to - token recepient
    /// @param amount - token amount
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        game.trackTransfer(from, to, amount);
    }
}
