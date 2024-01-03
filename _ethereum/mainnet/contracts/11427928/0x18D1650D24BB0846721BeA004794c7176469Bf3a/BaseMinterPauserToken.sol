//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "./ERC20Burnable.sol";
import "./Context.sol";
import "./Base.sol";

contract BaseMinterPauserToken is Base, Context, ERC20Burnable {
    constructor(
        address settingsAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal Base(settingsAddress) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external onlyMinter(_msgSender()) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        _settings().requireIsNotPaused();
    }
}
