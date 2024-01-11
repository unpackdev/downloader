// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.8.9;

import "./DaoTokenStorage.sol";

contract DaoTokenV2 is DaoTokenStorage {
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event NewSupplyCap(uint256 newCap);

    function initialize() external initializer {
        // initialize ancestor storage
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained("Cortex DAO Token", "CXD");

        // initialize impl-specific storage
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROTOCOL_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setSupplyCap(271828182e18);
    }

    /**
     * @notice Mint tokens to specified account.  Cannot exceed the supply cap.
     * @dev Can only be used by an account with minter role.  This should include
     * the smart contract that disburses the liquidity mining rewards.
     */
    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(
            super.totalSupply() + amount <= supplyCap,
            "SUPPLY_CAP_EXCEEDED"
        );
        super._mint(account, amount);
    }

    function _setSupplyCap(uint256 newCap) internal {
        require(newCap > 0, "ZERO_SUPPLY_CAP");
        require(newCap > super.totalSupply(), "INVALID_SUPPLY_CAP");
        supplyCap = newCap;
        emit NewSupplyCap(newCap);
    }
}
