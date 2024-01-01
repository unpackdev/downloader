//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./Ownable.sol";

contract ManaVendingMachine is Ownable {
    /**
     * @notice Vault address.
     * @notice This address will receive all the funds after withdrawal.
     */
    address payable public vaultAddress;

    /**
     * @notice Contract balance.
     * @notice This contract will hold funds after mana purchase until withdrawal.
     */
    uint256 public contractBalance;

    /**
     * @notice Mana balances.
     * @notice This mapping stores the mana balance of each address.
     */
    mapping(address => uint256) public manaBalances;

    /**
     * @notice Package struct.
     * @notice This struct defines the mana quantity and price of a package.
     */
    struct Package {
        uint256 manaQty;
        uint256 price;
    }

    /**
     * @notice Define maximum integer value.
     */
    uint256 MAX_INT = type(uint256).max;

    /**
     * @notice Number of packages.
     * @notice This number should be the same as the length of the packages array.
     */
    uint8 public pkgQty = 3;
    Package[] public packages;

    /**
     * @dev Event for purchase packages.
     * @param buyer address The address of the buyer.
     * @param quantities uint256[] The quantity of each package purchased.
     * @param totalEth uint256 The total eth spent.
     * @param totalMana uint256 The total mana purchased.
     */
    event PurchasePackages(
        address buyer,
        uint256[] quantities,
        uint256 totalEth,
        uint256 totalMana
    );

    /**
     * @dev Constructor function.
     */
    constructor() {
        // Set the owner and vaultAddress as the contract creator
        vaultAddress = payable(msg.sender);

        for (uint8 i = 0; i < pkgQty; i++) {
            packages.push(Package(0, MAX_INT));
        }
    }

    /**
     * @dev Set the vault address.
     * @param _vaultAdress address The address of the vault.
     */
    function setVaultAddress(address _vaultAdress) external onlyOwner {
        vaultAddress = payable(_vaultAdress);
    }

    /**
     * @dev Get the number of packages defined in contract.
     * @return uint8 The number of packages.
     */
    function getPkgQty() public view returns (uint8) {
        return pkgQty;
    }

    /**
     * @dev Get the mana balance of an address.
     * @param _address address The address to check.
     * @return uint The mana balance.
     */
    function getManaBalance(address _address) public view returns (uint) {
        return manaBalances[_address];
    }

    /**
     * @dev Get the packages list.
     * @return Package[] The list of packages.
     */
    function getPackages() public view returns (Package[] memory) {
        return packages;
    }

    /**
     * @dev Get a package from its id.
     * @param pkgId uint8 The id of the package.
     * @return Package The package.
     */
    function getPackageFromId(
        uint8 pkgId
    ) public view returns (Package memory) {
        // Id should be in the size of the packages array
        require(
            pkgId < packages.length,
            "The pkgId must be in the size of the packages array"
        );

        return packages[pkgId];
    }

    /**
     * @dev Set the packages.
     * @param _manaQty uint256[] The quantity of mana of each package.
     * @param _prices uint256[] The price of each package.
     */
    function setPackages(
        uint256[] calldata _manaQty,
        uint256[] calldata _prices
    ) external onlyOwner {
        // Arrays should be the same length
        require(
            _manaQty.length == _prices.length,
            "Mana quantity and prices arrays must have the same length"
        );

        // Arrays should be the same size as pkgQty (packages quantity)
        require(
            _manaQty.length == pkgQty,
            "Mana quantity and prices arrays must be same length as pkgQty"
        );

        // Loop through the arrays and create the packages
        for (uint8 i = 0; i < _manaQty.length; i++) {
            packages[i] = Package(_manaQty[i], _prices[i]);
        }
    }

    /**
     * @dev Purchase packages.
     * @param _qty uint256[] The quantity of each package to purchase.
     */
    function purchasePackages(uint256[] memory _qty) public payable {
        // Array should be the same length as the number of packages
        require(
            _qty.length == packages.length,
            "The length of the array is not the same as the number of packages"
        );

        // Loop through the array to calculate the total price
        uint256 totalEth = 0;
        uint256 totalMana = 0;
        for (uint8 i = 0; i < _qty.length; i++) {
            totalEth += packages[i].price * _qty[i];
            totalMana += packages[i].manaQty * _qty[i];
        }

        // Check if the value sent is enough
        require(msg.value == totalEth, "Value sent is not exact");

        // Add the mana to the user's balance
        manaBalances[msg.sender] += totalMana;

        // Save the value to the contract balance
        contractBalance += totalEth;

        // Emit the event
        emit PurchasePackages(msg.sender, _qty, totalEth, totalMana);
    }

    /**
     * @dev Withdraw funds to the vault using call.
     * @param _amount uint256 The amount to withdraw.
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= contractBalance, "Insufficient contract balance");
        contractBalance -= _amount;

        (bool success, ) = vaultAddress.call{value: _amount}("");
        require(success, "Withdraw was not successful");
    }

    /**
     * @dev Withdraw all the funds to the vaultAdress using call.
     */
    function withdrawAll() external onlyOwner {
        uint256 _amount = contractBalance;
        contractBalance = 0;

        (bool success, ) = vaultAddress.call{value: _amount}("");
        require(success, "Withdraw all was not successful");
    }
}
