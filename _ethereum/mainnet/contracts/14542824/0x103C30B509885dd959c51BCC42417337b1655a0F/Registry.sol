pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

import "./IController.sol";
import "./IStrategy.sol";
import "./IVaultCore.sol";
import "./IVaultDelegated.sol";
import "./IVaultWrapped.sol";

/// @title Registry
/// @notice The contract is the middleman actor through which the Keeper
/// bot queries the vaults and strategies addresses to call harvest method.
/// It also keep track of every working available vault and controller versions.
contract Registry is Ownable {
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice The structure to keep vaults addresses
    EnumerableSet.AddressSet private _vaults;

    event VaultAdded(address _newVault);
    event VaultRemoved(address _Vault);

    /// @notice The structure to keep controller addresses
    /// It's important to memorize that controller can be updated or replaced as
    /// well as strategies and vaults, so this is first structure to look when
    /// searching for latest version of the protocol.
    EnumerableSet.AddressSet private _controllers;

    /// @notice Mapping to store data about wrapped or facade vaults
    /// @dev wrapped vault address => actual working vault address
    mapping(address => address) public wrappedVaults;

    /// @notice Mapping to store data whether given vault is delegated
    /// @dev vault address => is delegated (using usual utility token in spite of stablecoin)? (bool)
    mapping(address => bool) public isDelegatedVault;

    /// @notice Adds vault to address set containing ordinary vault
    /// @param _vault Deployed ordinary vault address
    function addVault(address _vault) public onlyOwner {
        _addVault(_vault);
        (address controller, , , , ) = _getVaultData(_vault);
        _addController(controller);
    }

    /// @notice Adds vault first as ordinary then get unwrapped vault and mark it in wrapped vaults set
    /// @param _vault Deployed wrapped vault address
    function addWrappedVault(address _vault) external onlyOwner {
        addVault(_vault);
        address _wrappedVault = IVaultWrapped(_vault).vault();

        require(_wrappedVault.isContract(), "!contractWrapped");
        wrappedVaults[_vault] = _wrappedVault;
    }

    /// @notice Adds vaults as ordinary then mark it as delegated vault
    /// @param _vault Deployed delegated vault address
    function addDelegatedVault(address _vault) external onlyOwner {
        addVault(_vault);
        isDelegatedVault[_vault] = true;
    }

    /// @dev Checks if provided address is contract and if it is not added yet, then adding it.
    /// @param _vault Deployed vault address
    function _addVault(address _vault) internal {
        require(_vault.isContract(), "!contract");
        // Checks if vault is already on the array
        require(!_vaults.contains(_vault), "exists");
        // Adds unique _vault to _vaults array
        _vaults.add(_vault);
        emit VaultAdded(_vault);
    }

    /// @dev Adding controller to set if it is not added yet
    /// @param _controller Deployed controller
    function _addController(address _controller) internal {
        // Adds Controller to controllers array
        if (!_controllers.contains(_controller)) {
            _controllers.add(_controller);
        }
    }

    /// @notice Removes given vault address from the set
    /// @dev IMPORTANT It does not remove the metadata (wrapped or delegated vault marks)!!!
    /// @param _vault Vault address to remove
    function removeVault(address _vault) external onlyOwner {
        require(_vaults.remove(_vault), "!remove");
        emit VaultRemoved(_vault);
    }

    /// @dev An internal function used to aggregate all data for a specific controller
    /// @param _vault Vault address to analyze
    /// @return controller Related to vault controller
    /// @return token Related to vault business logic token
    /// @return strategy Related to vault business logic strategy
    /// @return isWrapped Bool mark if the vault is wrapped
    /// @return isDelegated Bool mark if the vault is delegated
    function _getVaultData(address _vault)
        internal
        view
        returns (
            address controller,
            address token,
            address strategy,
            bool isWrapped,
            bool isDelegated
        )
    {
        address vault = _vault;
        isWrapped = wrappedVaults[_vault] != address(0);
        if (isWrapped) {
            vault = wrappedVaults[_vault];
        }
        isDelegated = isDelegatedVault[vault];

        // Get values from controller
        controller = IVaultCore(vault).controller();
        if (isWrapped && IVaultDelegated(vault).underlying() != address(0)) {
            token = IVaultCore(_vault).token(); // Use non-wrapped vault
        } else {
            token = IVaultCore(vault).token();
        }

        // Check if vault is set on controller for token
        address controllerVault;
        if (isDelegated) {
            strategy = IController(controller).strategies(vault);
            controllerVault = IController(controller).vaults(strategy);
        } else {
            controllerVault = IController(controller).vaults(token);
            strategy = IController(controller).strategies(token);
        }
        require(controllerVault == vault, "!controllerVaultMatch"); // Might happen on Proxy Vaults

        // Check if strategy has the same token as vault
        if (isWrapped) {
            address underlying = IVaultDelegated(vault).underlying();
            require(underlying == token, "!wrappedTokenMatch"); // Might happen?
        } else if (!isDelegated) {
            address strategyToken = IStrategy(strategy).want();
            require(token == strategyToken, "!strategyTokenMatch"); // Might happen?
        }

        return (controller, token, strategy, isWrapped, isDelegated);
    }

    /// @notice Obtain vault by it's index in EnumerableSet
    /// @return Requested vault address
    function getVault(uint256 index) external view returns (address) {
        return _vaults.at(index);
    }

    /// @notice Obtain controller by it's index in EnumerableSet
    /// @return Requested controller address
    function getController(uint256 index) external view returns (address) {
        return _controllers.at(index);
    }

    /// @notice Calculates and returns current size of the vaults address set
    /// @return Vaults set size
    function getVaultsLength() external view returns (uint256) {
        return _vaults.length();
    }

    /// @notice Calculates and returns current size of the controllers address set
    /// @return Controllers set size
    function getControllersLength() external view returns (uint256) {
        return _controllers.length();
    }

    /// @notice Used to return all addresses in order to iterate over them
    /// @return memory All vaults that are registered now
    function getVaults() external view returns (address[] memory) {
        address[] memory vaultsArray = new address[](_vaults.length());
        for (uint256 i = 0; i < _vaults.length(); i++) {
            vaultsArray[i] = _vaults.at(i);
        }
        return vaultsArray;
    }

    /// @notice A facade method for _getVaultData(...) method
    /// @param _vault Vault address to analyze
    /// @return controller Related to vault controller
    /// @return token Related to vault business logic token
    /// @return strategy Related to vault business logic strategy
    /// @return isWrapped Bool mark if the vault is wrapped
    /// @return isDelegated Bool mark if the vault is delegated
    function getVaultInfo(address _vault)
        external
        view
        returns (
            address controller,
            address token,
            address strategy,
            bool isWrapped,
            bool isDelegated
        )
    {
        (controller, token, strategy, isWrapped, isDelegated) = _getVaultData(
            _vault
        );
        return (controller, token, strategy, isWrapped, isDelegated);
    }

    /// @notice Accumulates all the data containing in this registry
    /// @dev The structure returned is table-like, so all entries are bound by index
    /// @return vaultsAddresses All the vaults that are registered
    /// @return controllerArray All the controllers that are used
    /// @return tokenArray All the business tokens that are involved in vaults
    /// @return strategyArray All the strategies that are developed
    /// @return isWrappedArray All the marks of wrapped vaults
    /// @return isDelegatedArray All the marks of delegated vaults
    function getVaultsInfo()
        external
        view
        returns (
            address[] memory vaultsAddresses,
            address[] memory controllerArray,
            address[] memory tokenArray,
            address[] memory strategyArray,
            bool[] memory isWrappedArray,
            bool[] memory isDelegatedArray
        )
    {
        vaultsAddresses = new address[](_vaults.length());
        controllerArray = new address[](_vaults.length());
        tokenArray = new address[](_vaults.length());
        strategyArray = new address[](_vaults.length());
        isWrappedArray = new bool[](_vaults.length());
        isDelegatedArray = new bool[](_vaults.length());

        for (uint256 i = 0; i < _vaults.length(); i++) {
            vaultsAddresses[i] = _vaults.at(i);
            (
                address _controller,
                address _token,
                address _strategy,
                bool _isWrapped,
                bool _isDelegated
            ) = _getVaultData(_vaults.at(i));
            controllerArray[i] = _controller;
            tokenArray[i] = _token;
            strategyArray[i] = _strategy;
            isWrappedArray[i] = _isWrapped;
            isDelegatedArray[i] = _isDelegated;
        }
    }
}
