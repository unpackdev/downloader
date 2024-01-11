//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IVendingMachine.sol";

contract ZetaVendingMachine is IVendingMachine {
    // tokenId => price
    mapping(uint256 => uint256) private prices;

    bool public mintEnabled;

    constructor(address _zetaERC1155) IVendingMachine(_zetaERC1155) {
        mintEnabled = false;
    }

    function price(uint256 id) external view returns (uint256) {
        return prices[id];
    }

    function setPrice(uint256 id, uint256 _price) external onlyRole(DEPLOYER) {
        prices[id] = _price;
    }

    function setMintEnabled(bool _mintEnabled) external onlyRole(DEPLOYER) {
        mintEnabled = _mintEnabled;
    }

    function mint(uint256 id, uint256 amount)
        external
        payable
        virtual
        override
    {
        if (!mintEnabled) {
            revert NotOnSale();
        }

        if (prices[id] == 0) {
            revert NotOnSale();
        }

        if (amount * prices[id] > msg.value) {
            revert NotEnoughFunds();
        }

        _safeDecreaseAvailableStock(id, amount);
        zetaERC1155.mint(msg.sender, id, amount, "Zeta Vending Machine");
    }
}
