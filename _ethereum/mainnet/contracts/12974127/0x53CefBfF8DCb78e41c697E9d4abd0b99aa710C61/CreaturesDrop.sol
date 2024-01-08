// contracts/CreaturesDrop.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Creatures.sol";

contract CreaturesDrop is Ownable, Pausable, ReentrancyGuard {
    Creatures private token;

    address private wallet;
    uint256 private price;
    uint256 constant MAX_MINT_PER_ORDER = 20;

    constructor(
        Creatures _token,
        uint256 _price,
        address _wallet
    ) Ownable() {
        token = _token;
        price = _price;
        wallet = _wallet;

        _pause();
    }

    function mint(uint256 quantity) external payable whenNotPaused() nonReentrant() {
        require(msg.value >= price * quantity, "CreaturesDrop: Insufficient value");
        require(quantity <= MAX_MINT_PER_ORDER, "CreaturesDrop: Exceeds order limit");
        require(token.canMint(quantity), "CreaturesDrop: Exceeds total");

        for (uint256 i = 0; i < quantity; i++) {
            token.mint(_msgSender());
        }
    }

    function ownerMint(uint256 quantity) external onlyOwner() {
        require(token.canMint(quantity), "CreaturesDrop: Exceeds total");

        for (uint256 i = 0; i < quantity; i++) {
            token.mint(_msgSender());
        }
    }

    function mintGiveaways(address[] calldata addresses) external onlyOwner() {
        require(token.canMint(addresses.length), "CreaturesDrop: Exceeds total");

        for (uint256 i = 0; i < addresses.length; i++) {
            token.mint(addresses[i]);
        }
    }

    function withdraw(uint256 _amount) external onlyOwner() {
        payable(wallet).transfer(_amount);
    }

    function pause() external whenNotPaused() onlyOwner() {
        _pause();
    }

    function unpause() external whenPaused() onlyOwner() {
        _unpause();
    }
}
