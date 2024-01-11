// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

struct OptionState {
    // Option that the vault is shorting / longing in the next cycle
    address nextOption;
    // Option that the vault is currently shorting / longing
    address currentOption;
    // The timestamp when the `nextOption` can be used by the vault
    uint32 nextOptionReadyAt;
}

struct VaultParams {
    // Option type the vault is selling
    bool isPut;
    // Token decimals for vault shares
    uint8 decimals;
    // Asset used in Theta / Delta Vault
    address asset;
    // Underlying asset of the options sold by vault
    address underlying;
    // Minimum supply of the vault shares issued, for ETH it's 10**10
    uint56 minimumSupply;
    // Vault cap
    uint104 cap;
}

interface IVault {
    function currentOtokenPremium() external view returns(uint256);
    function optionState() external view returns(OptionState memory);
    function vaultParams() external view returns(VaultParams memory);
    function nextProductId() external view returns(uint256);
}

contract AntimatterSwap is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public vault;
    mapping(address => bool) public managers;

    event Swapped(address indexed sender, uint256 indexed optionAmount, uint256 indexed premiumAmount);

    function initialize(address _vault, address _manager) external initializer {
        __Ownable_init();
        vault = _vault;
        managers[_manager] = true;
    }

    function swap() external onlyManager {
        IVault vaultContract = IVault(vault);
        address option = vaultContract.optionState().currentOption;
        address asset = vaultContract.vaultParams().asset;
        require(option != address(0), "!option");
        require(asset != address(0), "!asset");

        (uint256 optionAmount, uint256 premiumAmount, ) = getAmounts();
        IERC20Upgradeable(option).safeTransferFrom(vault, msg.sender, optionAmount);
        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, vault, premiumAmount);

        emit Swapped(msg.sender, optionAmount, premiumAmount);
    }

    function getAmounts() public view returns(uint256 optionAmount, uint256 premiumAmount, uint256 productId) {
        IVault vaultContract = IVault(vault);
        productId = vaultContract.nextProductId();
        uint256 premiumPrice = vaultContract.currentOtokenPremium();
        if (premiumPrice == 0) {
            return (0, 0, productId);
        }

        IERC20MetadataUpgradeable optionToken = IERC20MetadataUpgradeable(vaultContract.optionState().currentOption);
        uint256 optionDecimals = optionToken.decimals();
        uint256 assetDecimals = IERC20MetadataUpgradeable(vaultContract.vaultParams().asset).decimals();

        optionAmount = optionToken.allowance(vault, address(this));
        optionAmount = optionToken.balanceOf(vault) < optionAmount ? optionToken.balanceOf(vault) : optionAmount;
        // The decimal of Premium Price is 4
        premiumAmount = optionAmount
            .mul(10**assetDecimals)
            .mul(premiumPrice)
            .div(1e4)
            .div(10**optionDecimals);

        return (optionAmount, premiumAmount, productId);
    }

    function getCurrentOptionAndPremiumPrice() public view returns(address option, uint256 premiumPrice) {
        IVault vaultContract = IVault(vault);
        option = vaultContract.optionState().currentOption;
        premiumPrice = vaultContract.currentOtokenPremium();

        return (option, premiumPrice);
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function addManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        delete managers[_manager];
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Invalid vault");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender] || owner() == msg.sender, "Invalid manager");
        _;
    }
}
