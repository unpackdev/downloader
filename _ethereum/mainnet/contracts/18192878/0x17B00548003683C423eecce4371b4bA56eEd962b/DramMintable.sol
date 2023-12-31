// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IDramMintable.sol";

/**
 * @notice An abstract ERC20 extension with custom logic for minting tokens.
 */
abstract contract DramMintable is
    Initializable,
    IDramMintable,
    ERC20Upgradeable
{
    mapping(address => uint256) private _mintCaps;

    // solhint-disable-next-line func-name-mixedcase
    function __DramMintable_init() internal onlyInitializing {
        __DramMintable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __DramMintable_init_unchained() internal onlyInitializing {}

    /**
     * @inheritdoc IDramMintable
     */
    function mintCap(address operator) public view returns (uint256) {
        return _mintCaps[operator];
    }

    /**
     * @dev mints token for an account and calculates the new minting cap of the caller.
     * @param account Account to send tokens to
     * @param amount Amount of the tokens to be minted
     */
    function _mint(address account, uint256 amount) internal virtual override {
        _spendMintCap(_msgSender(), amount);
        super._mint(account, amount);
    }

    /**
     * @dev Handles the arithmetic operations of calculating the minting cap.
     * NOTE: If an account has the maximum available minting cap, then this function
     * has no effect on it.
     * @param operator Address that used its minting cap by calling minting tokens
     * @param amount Amount of the minted tokens
     */
    function _spendMintCap(address operator, uint256 amount) internal virtual {
        uint256 currentMintCap = mintCap(operator);
        if (currentMintCap != type(uint256).max) {
            if (currentMintCap < amount) revert InsufficientMintCapError();
            unchecked {
                _setMintCap(operator, currentMintCap - amount);
            }
        }
    }

    /**
     * @dev Increases the minting cap of an address.
     * @param operator Address that gets its minting cap gets increased
     * @param addedValue Value to add to the current minting cap
     */
    function _increaseMintCap(
        address operator,
        uint256 addedValue
    ) internal virtual returns (bool) {
        _setMintCap(operator, mintCap(operator) + addedValue);
        return true;
    }

    /**
     * @dev Decreases the minting cap of an address.
     * @param operator Address that gets its minting cap gets decreased
     * @param subtractedValue Value to subtract from the current minting cap
     */
    function _decreaseMintCap(
        address operator,
        uint256 subtractedValue
    ) internal virtual returns (bool) {
        uint256 currentMintCap = mintCap(operator);
        if (currentMintCap < subtractedValue) revert InsufficientMintCapError();
        unchecked {
            _setMintCap(operator, currentMintCap - subtractedValue);
        }
        return true;
    }

    /**
     * @dev Sets the minting cap of an address and emits the associated event.
     * @param account Address that its minting cap will be changed
     * @param amount New minting cap
     */
    function _setMintCap(
        address account,
        uint256 amount
    ) internal virtual returns (bool) {
        _mintCaps[account] = amount;
        emit MintCapChanged(account, _msgSender(), amount);
        return true;
    }

    uint256[49] private __gap;
}
