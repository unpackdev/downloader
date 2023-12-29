// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseModule.sol";
import "./IVault.sol";

/**
 * @title SecurityManager
 * @notice Abstract module implementing the key security features of the vault: guardians, lock and recovery.
 */
abstract contract SecurityManager is BaseModule {

    event Bequeathed(address indexed vault, address indexed newOwner, address newKbg);
    event TransferedOwnership(address indexed vault, address newOwner, address newKbg);
    event Locked(address indexed vault);
    event Unlocked(address indexed vault);
    event HumanGuardianChanged(address indexed vault, address indexed guardian);
    event TrusteeChanged(address indexed vault, address indexed trustee);
    event TimeDelayChanged(address indexed vault, uint256 newTimeDelay);
    event Enabled(address indexed vault, address kbg);
    event Disabled(address indexed vault);

    /**
     * @notice Lets a guardian lock a vault.
     * @param _vault The target vault.
     */
    function lock(address _vault) external onlySelf() {
        _storage.lock(_vault);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        emit Locked(_vault);
    }

    /**
     * @notice Updates the TimeDelay
     * @param _vault The target vault.
     * @param _newTimeDelay The new DelayTime to update.
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlySelf()
    {
        _storage.setTimeDelay(_vault, _newTimeDelay);
        emit TimeDelayChanged(_vault, _newTimeDelay);
    }

    /**
     * @notice Lets a guardian unlock a locked vault.
     * @param _vault The target vault.
     */
    function unlock(
        address _vault
    ) 
        external
        onlySelf()
    {
        _storage.unlock(_vault);
        emit Unlocked(_vault);
    }


    /**
     * @notice Lets the owner add a guardian to its vault.
     * @param _vault The target vault.
     * @param _guardian The guardian to add.
     */
    function setHumanGuardian(
        address _vault,
        address _guardian
    )
        external
        onlySelf()
    {
        require(_guardian != IVault(_vault).owner(), "SM: Invalid guardian");
        _storage.setHumanGuardian(_vault, _guardian);
        emit HumanGuardianChanged(_vault, _guardian);
    }

    /**
     * @notice Function to be used to remove human guardians.
     * @param _vault The target vault.
     */
    function removeHumanGuardian(
        address _vault
    )
        external
        onlySelf()
    {
        _storage.setHumanGuardian(_vault, ZERO_ADDRESS);
        emit HumanGuardianChanged(_vault, ZERO_ADDRESS);
    }

    /**
     * @notice Function to add a human guardian to vault.
     * @param _vault The target vault.
     * @param _guardian Address of the new guardian.
     */
    function addHumanGuardian(
        address _vault,
        address _guardian
    )
        external
        onlySelf()
    {
        require(
            _storage.getHumanGuardian(_vault) == ZERO_ADDRESS,
            "SM: Cannot add guardian"
        );
        _storage.setHumanGuardian(_vault, _guardian);
        emit HumanGuardianChanged(_vault, _guardian);
    }

    /**
     * @notice Changes trustee address for a vault.
     * @param _vault The target vault.
     * @param _newTrustee Address of the new trustee.
     */
    function addTrustee(
        address _vault,
        address _newTrustee
    ) 
        external
        onlySelf()
    {
        require(
            _storage.getTrustee(_vault) == ZERO_ADDRESS && _newTrustee != ZERO_ADDRESS,
            "SM: Cannot add trustee"
        );
        _storage.setTrustee(_vault, _newTrustee);
        emit TrusteeChanged(_vault, _newTrustee);
    }

    /**
     * @notice Resets the trustee address.
     * @param _vault The target vault.
     */
    function removeTrustee(
        address _vault
    )
        external
        onlySelf()
    {
        _storage.setTrustee(_vault, ZERO_ADDRESS);
        emit TrusteeChanged(_vault, ZERO_ADDRESS);
    }

    /**
     * @notice Sets the current trustee address as the new owner for the vault. 
     * After change in owner sets the current trustee address to 0x0.
     * @param _vault The target vault.
     * @param _newKbg The new KBG address.
     */
    function executeBequeathal(
        address _vault,
        address _newKbg
    )
        external
        onlySelf()
    {
        address trustee = _storage.getTrustee(_vault);
        resetVault(_vault, trustee, _newKbg);
        emit Bequeathed(_vault, trustee, _newKbg);
    }

    /**
     * @notice Enables target vault.
     * @param _vault The target vault.
     * @param _newKbg New KBG address.
     */
    function enable(
        address _vault,
        address _newKbg
    )
        external
        onlySelf()
    {
        _storage.enable(_vault, _newKbg);
        emit Enabled(_vault, _newKbg);
    }

    /**
     * @notice Disables target vault.
     * @param _vault The target vault.
     */
    function disable(
        address _vault
    )
        external
        onlySelf()
    {
        _storage.disable(_vault);
        emit Disabled(_vault);
    }

    /**
     * @notice Transfers ownership to different address and changes the kbg address.
     * @param _vault The target vault.
     * @param _newKbg The new kbg address.
     * @param _newOwner The new owner address.
     */
    function transferOwnership(
        address _vault,
        address _newOwner,
        address _newKbg
    )
        external
        onlySelf()
    {
        resetVault(_vault, _newOwner, _newKbg);
        emit TransferedOwnership(_vault, _newOwner, _newKbg);
    }

    /**
     * @notice Changes owner, and resets vault to default state.
     * @param _vault The target vault.
     * @param _newOwner The new owner address.
     * @param _newKbg The new kbg address.
     */
    function resetVault(
        address _vault,
        address _newOwner,
        address _newKbg
    )
        internal
    {
        changeOwner(_vault, _newOwner);
        _storage.reset(_vault);
        _storage.setKbg(_vault, _newKbg);
    }

    /**
     * @notice Changes the owner address for a vault.
     * @param _vault The target vault.
     * @param _newOwner Address of the new owner.
     */
    function changeOwner(address _vault, address _newOwner) internal {
        validateNewOwner(_vault, _newOwner);
        IVault(_vault).setOwner(_newOwner);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
    }

    /**
     * @notice Checks if the vault address is valid to be a new owner.
     * @param _vault The target vault.
     * @param _newOwner The target vault.
     */
    function validateNewOwner(
        address _vault,
        address _newOwner
    ) internal view {
        require(
            !_storage.isHumanGuardian(
                _vault,
                _newOwner
            ),
            "SM: new owner cannot be guardian"
        );
    }
}