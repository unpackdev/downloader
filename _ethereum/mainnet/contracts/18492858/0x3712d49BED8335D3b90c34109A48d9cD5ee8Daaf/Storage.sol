// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IVault.sol";
import "./IStorage.sol";

/**
 * @title Storage
 * @notice Base contract for the storage of a vault.
 */
contract Storage is IStorage{

    address constant ZERO_ADDRESS = address(0);
    uint256 constant DEFAULT_TD = 8 hours;

    struct StorageConfig {
        uint256 timeDelay; // time delay in seconds which has to be expired to executed queued requests.
        address trustee; // address of the trustee to bequeath.
        address kbg; // address of the default guardian (vault owner and kresus bootstrap guardian).
        address humanGuardian; // group address for all the human guardians.
        bool locked; // true if vault is locked else false.
        bool disabled; // true if vault is disabled, else false.
    }
    
    // Vault specific storage
    mapping (address => StorageConfig) private vaultStorage;

    /**
     * @notice Throws if the caller is not an authorised module.
     */
    modifier onlyModule(address _vault) {
        require(
            IVault(_vault).authorised(msg.sender),
            "S: must be an authorized module to call this method"
        );
        _;
    }

    /**
     * @inheritdoc IStorage
     */
    function lock(
        address _vault
    ) external onlyModule(_vault) {
        vaultStorage[_vault].locked = true;
    }

    /**
     * @inheritdoc IStorage
     */
    function unlock(
        address _vault
    ) external onlyModule(_vault) {
        _reset(_vault);
        vaultStorage[_vault].locked = false;
    }

    /**
     * @inheritdoc IStorage
     */
    function setHumanGuardian(
        address _vault,
        address _guardian
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].humanGuardian = _guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].timeDelay = _newTimeDelay;
    }
    
    /**
     * @inheritdoc IStorage
     */
    function setTrustee(
        address _vault,
        address _trustee
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].trustee = _trustee;
    }

    /**
     * @inheritdoc IStorage
     */
    function setKbg(
        address _vault,
        address _kbg
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].kbg = _kbg;
    }

    /**
     * @inheritdoc IStorage
     */
    function enable(address _vault, address _kbg) external onlyModule(_vault) {
        StorageConfig storage s = vaultStorage[_vault];
        s.disabled = false;
        s.kbg = _kbg;
        s.timeDelay = DEFAULT_TD;
    }

    /**
     * @inheritdoc IStorage
     */
    function disable(address _vault) external onlyModule(_vault) {
        StorageConfig storage s = vaultStorage[_vault];
        s.locked = false;
        s.disabled = true;
        s.humanGuardian = ZERO_ADDRESS;
        s.timeDelay = 0;
        s.kbg = IVault(_vault).owner();
    }

    /**
     * @inheritdoc IStorage
     */
    function reset(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        _reset(_vault);
    }

    /**
     * @notice Function which sets the time dealy, human guardian and trustee to default vaules.
     * @param _vault - Target vault.
     */
    function _reset(
        address _vault
    )
        internal
    {
        StorageConfig storage s = vaultStorage[_vault];
        s.trustee = ZERO_ADDRESS;
        s.humanGuardian = ZERO_ADDRESS;
        s.timeDelay = DEFAULT_TD;
    }

    /**
     * @inheritdoc IStorage
     */
    function isLocked(
        address _vault
    ) 
        external
        view
        returns (bool)
    {
        return vaultStorage[_vault].locked;
    }

    /**
     * @inheritdoc IStorage
     */
    function getKbg(
        address _vault
    )
        external
        view
        returns (address)
    {
        return vaultStorage[_vault].kbg;
    }

    /**
     * @inheritdoc IStorage
     */
    function getHumanGuardian(
        address _vault
    )
        external
        view
        returns (address)
    {
        return vaultStorage[_vault].humanGuardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function getTrustee(
        address _vault
    )
        external
        view
        returns(address)
    {
        return vaultStorage[_vault].trustee;
    }

    /**
     * @inheritdoc IStorage
     */
    function isKbg(
        address _vault,
        address _guardian
    )
        external
        view
        returns (bool)
    {
        return (vaultStorage[_vault].kbg == _guardian);
    }

    /**
     * @inheritdoc IStorage
     */
    function isHumanGuardian(
        address _vault,
        address _guardian
    )
        external
        view
        returns(bool)
    {
        return vaultStorage[_vault].humanGuardian == _guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function isTrustee(
        address _vault,
        address _trustee
    )
        external
        view
        returns(bool)
    {
        return vaultStorage[_vault].trustee == _trustee;
    }

    /**
     * @inheritdoc IStorage
     */
    function isDisabled(
        address _vault
    )
        external
        view
        returns(bool)
    {
        return vaultStorage[_vault].disabled;
    }

    /**
     * @inheritdoc IStorage
     */
    function getTimeDelay(
        address _vault
    )
        external
        view
        returns(uint256)
    {
        return vaultStorage[_vault].timeDelay;
    }

    /**
     * @inheritdoc IStorage
     */
    function hasHumanGuardian(address _vault) external view returns(bool) {
        return vaultStorage[_vault].humanGuardian != ZERO_ADDRESS;
    }
}