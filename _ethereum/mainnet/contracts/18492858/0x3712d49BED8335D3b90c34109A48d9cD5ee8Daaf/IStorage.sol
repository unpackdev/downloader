// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStorage
 * @notice Interface for Storage
 */
interface IStorage {

    /**
     * @notice Sets lock for a vault contract.
     * @param _vault - The target vault.
     */
    function lock(address _vault) external;

    /**
     * @notice Unlocks a vault contract.
     * @param _vault - The target vault.
     */
    function unlock(address _vault) external;

    /**
     * @notice Lets an authorised module add a guardian to a vault.
     * @param _vault - The target vault.
     * @param _guardian - The guardian to add.
     */
    function setHumanGuardian(address _vault, address _guardian) external;

    /**
     * @notice Sets a new time delay for a vault contract.
     * @param _vault - The target vault.
     * @param _newTimeDelay - The new time delay.
     */
    function setTimeDelay(address _vault, uint256 _newTimeDelay) external;

    /**
     * @notice Function to be used to add trustee address to bequeath vault ownership.
     * @param _vault - The target vault.
     * @param _newTrustee - New address for trustee.
     */
    function setTrustee(address _vault, address _newTrustee) external;

    /**
     * @notice Function to set the kbg for a vault.
     * @param _vault - The target vault.
     * @param _kbg - Address of kbg.
     */
    function setKbg(address _vault, address _kbg) external;

    /**
     * @notice Function to enable or disable a vault.
     * @param _vault - The target vault.
     */
    function enable(address _vault, address _kbg) external;

    /**
     * @notice Function to disable a vault.
     * @param _vault - The target vault.
     */
    function disable(address _vault) external;

    /**
     * @notice Function to reset the vault.
     * @param _vault - The target vault.
     */
    function reset(address _vault) external;

    /**
     * @notice Returns boolean indicating state of the vault.
     * @param _vault - The target vault.
     * @return true if the vault is locked, else returns false.
     */
    function isLocked(address _vault) external view returns(bool);

    /**
     * @notice Returns kbg address of the vault.
     * @param _vault - The target vault.
     * @return kbg address of the vault.
     */
    function getKbg(address _vault) external view returns(address);

    /**
     * @notice Returns human guardian address of the vault.
     * @param _vault - The target vault.
     */
    function getHumanGuardian(address _vault) external view returns(address);

    /**
     * @notice Returns the trustee address for a vault.
     * @param _vault - The target vault.
     */
    function getTrustee(address _vault) external view returns(address);

    /**
     * @notice Checks if an address is kbg for a vault.
     * @param _vault - The target vault.
     * @param _kbg - The account address to be checked.
     * @return true if `_kbg` is kbg for `_vault`.
     */
    function isKbg(address _vault, address _kbg) external view returns(bool);

    /**
     * @notice Checks if an address is a guardian for a vault.
     * @param _vault - The target vault.
     * @param _guardian - The account address to be checked.
     * @return true if `_guardian` is human guardian for `_vault`.
     */
    function isHumanGuardian(address _vault, address _guardian) external view returns(bool);

    /**
     * @notice Checks if an address is an trustee for a vault.
     * @param _vault - The target vault.
     * @param _trustee - The account address to be checked.
     * return true if `_trustee` is the trustee for `_vault`.
     */
    function isTrustee(address _vault, address _trustee) external view returns(bool);

    /**
     * @notice Returns if a vault is disabled.
     * @param _vault - The target vault.
     * return true if the vault is disabled else return false.
     */
    function isDisabled(address _vault) external view returns(bool);

    /**
     * @notice Returns uint256 time delay in seconds for a vault
     * @param _vault - The target vault.
     * @return uint256 time delay in seconds for a vault.
     */
    function getTimeDelay(address _vault) external view returns(uint256);

    /**
     * @notice Returns if a vault has human guardian.
     * @param _vault - The target vault.
     * @return true if `_vault` has human guardian else false.
     */
    function hasHumanGuardian(address _vault) external view returns(bool);
}