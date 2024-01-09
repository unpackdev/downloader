// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";

import "./ERC20BurnableUpgradeable.sol";

import "./IMintableBurnableTokenUpgradeable.sol";
import "./ITokenInitializableV1.sol";

contract PoolTokenUpgradeable is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20BurnableUpgradeable,
    IMintableBurnableTokenUpgradeable,
    ITokenInitializableV1
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    uint8 public _decimalsValue;

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimalsValue_,
        address minterAdmin_,
        address minter_
    ) external override initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        __ERC20_init_unchained(name_, symbol_);
        __ERC20Burnable_init_unchained();

        _decimalsValue = decimalsValue_;

        if (minter_ != address(0)) {
            _setupRole(MINTER_ROLE, minter_);
        }
        if (minterAdmin_ != address(0)) {
            _setupRole(MINTER_ADMIN_ROLE, minterAdmin_);
            _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        }
    }

    function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimalsValue;
    }
}
