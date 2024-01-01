// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IAdminStructure.sol";
import "./FeeManagerErrors.sol";
import "./IFeeManager.sol";
import "./AddressUtils.sol";

/**
 * @title Dollet FeeManager contract
 * @author Dollet Team
 * @notice FeeManager contract that is responsible for managing fees of different types.
 */
contract FeeManager is Initializable, IFeeManager {
    using AddressUtils for address;

    uint16 public constant MAX_FEE = 4000; // 40.00%

    mapping(address strategy => mapping(FeeType feeType => Fee fee)) public fees;
    IAdminStructure public adminStructure;

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    modifier onlyAdmin() {
        adminStructure.isValidAdmin(msg.sender);
        _;
    }

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    modifier onlySuperAdmin() {
        adminStructure.isValidSuperAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this contract in time of deployment.
     * @param _adminStructure Admin structure contract address.
     */
    function initialize(address _adminStructure) external initializer {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IFeeManager
    function setAdminStructure(address _adminStructure) external onlySuperAdmin {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IFeeManager
    function setFee(address _strategy, FeeType _feeType, address _recipient, uint16 _fee) external onlyAdmin {
        AddressUtils.onlyContract(_strategy);

        if (_recipient == address(0)) revert FeeManagerErrors.WrongFeeRecipient(_recipient);
        if (_fee > MAX_FEE) revert FeeManagerErrors.WrongFee(_fee);

        Fee memory _newFee = Fee({ recipient: _recipient, fee: _fee });

        fees[_strategy][_feeType] = _newFee;

        emit FeeSet(_strategy, _feeType, _newFee);
    }
}
