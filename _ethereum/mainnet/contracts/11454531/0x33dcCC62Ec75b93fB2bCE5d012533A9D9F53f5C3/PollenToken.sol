// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20Snapshot.sol";


/**
 * @title PollenToken
 * @dev ERC-20 token contract for PLN and STEM tokens
 */
contract PollenToken is OwnableUpgradeSafe, ERC20SnapshotUpgradeSafe {

    // Balances never exceed 96 bits
    uint256 internal constant MAX_SUPPLY = 2 ** 96 - 1;

    /**
     * @dev Reserved for possible storage structure changes
     */
    uint256[50] private __gap;

    /**
     * @notice Initializes the contract and sets the token name and symbol (external)
     * @dev Sets the contract `owner` account to the deploying account
     */
    function _initialize(
        string memory name,
        string memory symbol
    ) internal initializer {
        __Ownable_init();
        __ERC20_init_unchained(name, symbol);
        __ERC20Snapshot_init_unchained();
    }

    /**
     * @notice Mints tokens to the owner account (external)
     * @param amount The amount of tokens to mint
     * Requirements: the caller must be the owner
     * See {ERC20-_mint}.
     */
    function mint(uint256 amount) external onlyOwner
    {
        require(
            totalSupply().add(amount) <= MAX_SUPPLY,
            "Pollen: Total supply exceeds 96 bits"
        );
        _mint(_msgSender(), amount);
    }

    /**
     * @notice Destroys `amount` tokens from the caller (external)
     * @param amount The amount of tokens to mint
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external
    {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance
     * Requirements: the caller must have allowance for `accounts`'s tokens of at least `amount`
     */
    function burnFrom(address account, uint256 amount) external {
        uint256 decreasedAllowance = allowance(account, _msgSender())
            .sub(amount, "Pollen: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
     * @notice Creates a new snapshot and returns its snapshot id (external)
     * Requirements: the caller must be the owner
     */
    function snapshot() external onlyOwner returns (uint256)
    {
        return super._snapshot();
    }
}
