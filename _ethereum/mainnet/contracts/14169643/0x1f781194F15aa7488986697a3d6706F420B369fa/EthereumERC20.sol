// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

contract EthereumERC20 is OwnableUpgradeable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    mapping(address => bool) public isBlacklisted;

    event Blacklisted(address indexed account);

    event UnBlacklisted(address indexed account);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        uint256 amount
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        __ERC20Burnable_init_unchained();

        _setupDecimals(decimal_);

        if (amount > 0) {
            _mint(_msgSender(), amount);
        }
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(_msgSender(), amount);
    }

    function blacklist(address account) external onlyOwner {
        require(account != address(0), "ERC20: blacklist the zero address");
        isBlacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unBlacklist(address account) external onlyOwner {
        require(account != address(0), "ERC20: unblacklist the zero address");
        isBlacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        require(isBlacklisted[from] == false, "ERC20: sender is suspended");
        require(isBlacklisted[to] == false, "ERC20: recipient is suspended");
    }
}
