// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./UUPSProxy.sol";
import "./IBSVault.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title VaultFactory
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

contract VaultFactory {
    /// @dev vault logic address
    address public vaultLogic;
    /// @dev owner that can update vault logic address
    address public immutable owner;

    event NewVault(address vault, uint256 created);
    event VaultUpdated(address vault, uint256 created);

    /// @notice modifier to allow only the owner to call a function
    modifier onlyOwner {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(address _owner, address _vaultLogic) {
        require(_vaultLogic != address(0), "INVALID_VAULT");
        require(_owner != address(0), "INVALID_OWNER");

        owner = _owner;
        vaultLogic = _vaultLogic;
    }

    /// @notice update the vault logic address
    /// @param _newVault the address of the new vault logic
    function updateVaultLogic(address _newVault) external onlyOwner {
        require(_newVault != address(0), "INVALID_VAULT");

        vaultLogic = _newVault;
        emit VaultUpdated(_newVault, block.timestamp);
    }

    /// @notice create an upgradable vault
    /// @param _flashLoanRate flash loan rate to charge
    /// @param _vaultOwner address allowed to perform vault `admin` functions
    function createUpgradableVault(uint256 _flashLoanRate, address _vaultOwner)
        external
        onlyOwner
        returns (address proxy)
    {
        UUPSProxy uupsProxy = new UUPSProxy();
        uupsProxy.initializeProxy(vaultLogic);

        proxy = address(uupsProxy);
        
        // initiailize vault & validates the input properties
        IBSVault(proxy).initialize(_flashLoanRate, _vaultOwner);

        emit NewVault(proxy, block.timestamp);
    }
}
