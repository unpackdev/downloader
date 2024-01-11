// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Vault.sol";

contract VaultRegistry {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private managerSet;
    EnumerableSet.AddressSet private vaultSet;

    address public treasury = address(0x0);
    address public priceToken = address(0x0);
    uint256 public price = 0;

    modifier onlyManagers() {
        require(
            managerSet.contains(msg.sender),
            "VaultRegistry: only allowed for managers."
        );
        _;
    }

    modifier withVault(address vault) {
        require(Vault(payable(vault)).isVault(), "VaultRegistry: not a Vault");
        _;
    }

    modifier onlyManagersOrVaultManager(address vault) {
        require(
            managerSet.contains(msg.sender) ||
                Vault(payable(vault)).manager() == msg.sender,
            "VaultRegistry: only allowed for managers."
        );
        _;
    }

    event VaultAdded(address indexed vault, address indexed addedBy);
    event VaultRemoved(address indexed vault, address indexed removedBy);

    event ManagerAdded(address indexed manager, address indexed addedBy);
    event ManagerRemoved(address indexed manager, address indexed removedBy);

    event PriceChanged(
        address indexed token,
        address indexed changedBy,
        uint256 price
    );

    event TreasuryChanged(address indexed treasury, address indexed changedBy);

    constructor() {
        managerSet.add(msg.sender);
        emit ManagerAdded(msg.sender, msg.sender);
    }

    function managers() public view returns (address[] memory) {
        return managerSet.values();
    }

    function addManager(address newManager) public onlyManagers {
        managerSet.add(newManager);
    }

    function removeManager(address manager) public onlyManagers {
        require(
            manager != msg.sender,
            "VaultRegistry: cannot remove self from manager set."
        );
        managerSet.remove(manager);
    }

    function vaults() public view returns (address[] memory) {
        return vaultSet.values();
    }

    function _add(address vault) internal virtual {
        if (vaultSet.add(vault)) emit VaultAdded(vault, msg.sender);
    }

    function _remove(address vault) internal virtual {
        if (vaultSet.remove(vault)) emit VaultRemoved(vault, msg.sender);
    }

    function add(address vault)
        public
        withVault(vault)
        onlyManagersOrVaultManager(vault)
    {
        _add(vault);
    }

    function remove(address vault)
        public
        withVault(vault)
        onlyManagersOrVaultManager(vault)
    {
        _remove(vault);
    }

    function create(
        string memory name,
        string memory symbol,
        address underlying,
        address owner
    ) public {
        if (price != 0 && treasury != address(0x0))
            IERC20(priceToken).safeTransferFrom(msg.sender, treasury, price);
        Vault vault = new Vault(name, symbol, underlying, owner);
        vault.setManager(msg.sender);
        _add(address(vault));
    }

    function setPrice(address _priceToken, uint256 _price) public onlyManagers {
        priceToken = _priceToken;
        price = _price;
        emit PriceChanged(priceToken, msg.sender, price);
    }

    function setTreasury(address _treasury) public onlyManagers {
        treasury = _treasury;
        emit TreasuryChanged(treasury, msg.sender);
    }
}
