// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IAdminStructure.sol";

/**
 * @title Dollet IFeeManager
 * @author Dollet Team
 * @notice Interface for FeeManager contract.
 */
interface IFeeManager {
    /**
     * @notice Fee type enumeration.
     * @param MANAGEMENT Fee type: management
     * @param PERFORMANCE Fee type: performance
     */
    enum FeeType {
        MANAGEMENT, // 0
        PERFORMANCE // 1
    }

    /**
     * @notice Fee structure.
     * @param recipient recipient of the fee.
     * @param fee The fee (as percentage with 2 decimals).
     */
    struct Fee {
        address recipient;
        uint16 fee;
    }

    /**
     * @notice Logs the information when a new fee is set.
     * @param _strategy Strategy contract address for which the fee is set.
     * @param _feeType Type of the fee.
     * @param _fee The fee structure itself.
     */
    event FeeSet(address indexed _strategy, FeeType indexed _feeType, Fee _fee);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new fee to provided strategy.
     * @param _strategy The strategy contract address to set a new fee for.
     * @param _feeType The fee type to set.
     * @param _recipient The recipient of the fee.
     * @param _fee The fee (as percentage with 2 decimals).
     */
    function setFee(address _strategy, FeeType _feeType, address _recipient, uint16 _fee) external;

    /**
     * @notice Retrieves a fee and its recipient for the provided strategy and fee type.
     * @param _strategy The strategy contract address to get the fee for.
     * @param _feeType The fee type to get the fee for.
     * @return _recipient The recipient of the fee.
     * @return _fee The fee (as percentage with 2 decimals).
     */
    function fees(address _strategy, FeeType _feeType) external view returns (address _recipient, uint16 _fee);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return The address of the AdminStructure contract.
     */
    function adminStructure() external returns (IAdminStructure);

    /**
     * @notice Returns MAX_FEE constant value (with two decimals).
     * @return MAX_FEE constant value (with two decimals).
     */
    function MAX_FEE() external pure returns (uint16);
}
