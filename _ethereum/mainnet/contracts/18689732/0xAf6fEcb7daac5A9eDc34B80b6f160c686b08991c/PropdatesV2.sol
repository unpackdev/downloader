// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./NounsDAOLogicV2.sol";
import "./NounsDAOInterfaces.sol";
import "./UUPSUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";

import "./GasRefund.sol";

contract PropdatesV2 is Initializable, Ownable2StepUpgradeable, UUPSUpgradeable{
    struct PropdateInfo {
        // address which can post updates for this prop
        address propUpdateAdmin;
        // when was the last update was posted
        uint88 lastUpdated;
        // is the primary work of the proposal considered done
        bool isCompleted;
    }

    event PropUpdateAdminTransferred(uint256 indexed propId, address indexed oldAdmin, address indexed newAdmin);
    event PropUpdateAdminRecovered(uint256 indexed propId, address indexed oldAdmin, address indexed newAdmin);
    event PropUpdateAdminMigrated(uint256 indexed propId, address indexed oldAdmin, address indexed newAdmin);
    event PostUpdate(uint256 indexed propId, bool indexed isCompleted, string update);
    event SuperAdminTransferred(address indexed oldSuperAdmin, address indexed newSuperAdmin);

    error OnlyPropUpdateAdmin();
    error OnlySuperAdmin();
    error OnlyPropUpdateAdminOrSuperAdmin();
    error NoZeroAddress();
    error MismatchedLengths();

    address payable public constant NOUNS_DAO = payable(0x6f3E6272A167e8AcCb32072d08E0957F9c79223d);
    address public superAdmin;

    mapping(uint256 => PropdateInfo) internal _propdateInfo;

    //BEGIN STORAGE GAPS         

    uint256[50] __reservedUint256;         
    address[50] __reservedAddress;         
    bool[50] __reservedBool;         

    mapping(address => uint256) __reservedAddressUint256MappingZero;         
    mapping(address => uint256) __reservedAddressUint256MappingOne;         
    mapping(address => uint256) __reservedAddressUint256MappingTwo; 
    mapping(uint256 => address) __reservedUint256AddressMappingZero;         
    mapping(uint256 => address) __reservedUint256AddressMappingOne;        
    mapping(uint256 => address) __reservedUint256AddressMappingTwo;
    mapping(uint256 => uint256) __reservedUint256Uint256MappingZero;         
    mapping(uint256 => uint256) __reservedUint256Uint256MappingOne;         
    mapping(uint256 => uint256) __reservedUint256Uint256MappingTwo;  
    mapping(uint256 => bool) __reservedUint256BoolMappingZero;         
    mapping(uint256 => bool) __reservedUint256BoolMappingOne;         
    mapping(uint256 => bool) __reservedUint256BoolMappingTwo;               

    // END STORAGE GAPS

    /// @notice sets initial owner of contract
    function initialize() external initializer { 
         __Ownable_init(msg.sender);
    }

    /// @notice function to allow upgrades to new implementation
    function _authorizeUpgrade(address) internal override onlyOwner {}
    
    // allow receiving ETH for gas refunds
    receive() external payable {}

    /// @notice Transfers prop update admin power to a new address
    /// @dev reverts if the new admin is the zero address
    /// @dev if current admin is zero address, reverts unless msg.sender is prop proposer
    /// @dev if current admin is not zero address, reverts unless msg.sender is current admin
    /// @dev requires newAdmin to accept the admin power in a separate transaction
    /// @param propId The id of the prop
    /// @param newAdmin The address to transfer admin power to
    function transferPropUpdateAdmin(uint256 propId, address newAdmin) external {
        if (newAdmin == address(0)) {
            // block transferring to zero address because it creates a weird state
            // where the prop proposer has control again
            revert NoZeroAddress();
        }

        address currentAdmin = _propdateInfo[propId].propUpdateAdmin;

        // sender must either current admin, or be prop proposer with current admin as 0 address
        if (
            msg.sender != currentAdmin
            && !(currentAdmin == address(0) && NounsDAOLogicV2(NOUNS_DAO).proposals(propId).proposer == msg.sender)
        ) {
            revert OnlyPropUpdateAdmin();
        }

        _propdateInfo[propId].propUpdateAdmin = newAdmin;

        emit PropUpdateAdminTransferred(propId, currentAdmin, newAdmin);
    }

    /// @notice allow superAdmin to manually transfer propId to a new address
    function recoverPropUpdateAdmin(uint256 propId, address newAdmin) external {
        if (newAdmin == address(0)) {
            // block transferring to zero address because it creates a weird state
            // where the prop proposer has control again
            revert NoZeroAddress();
        }

        address currentAdmin = _propdateInfo[propId].propUpdateAdmin;

        // sender must be superAdmin
        if (
            msg.sender != superAdmin
        ) {
            revert OnlySuperAdmin();
        }

        _propdateInfo[propId].propUpdateAdmin = newAdmin;

        emit PropUpdateAdminRecovered(propId, currentAdmin, newAdmin);
    }

    /// @notice Transfers multiple prop update admins at once
    /// @notice Only used by superAdmin to migrate initial state
    /// @dev reverts if any new admin is the zero address
    /// @dev reverts if propIds length, newAdmins length, and statuses length are not all equal
    /// @dev reverts if sender is not superAdmin
    /// @param propIds array of propIds
    /// @param newAdmins array of new admin addresses for each propId
    /// @param statuses array of isCompleted statuses for each propId
    function batchTransferPropUpdateAdmins(uint256[] memory propIds, address[] memory newAdmins, bool[] memory statuses) external {
        
        // lengths of all three arrays must match
        if(
            !(propIds.length == newAdmins.length && newAdmins.length == statuses.length)
        ) {
            revert MismatchedLengths();
        }
        
        // sender must be superAdmin
        if (
            msg.sender != superAdmin
        ) {
            revert OnlySuperAdmin();
        }

        for(uint i = 0; i < propIds.length; i++){
            if (newAdmins[i] == address(0)) {
            // block transferring to zero address because it creates a weird state
            // where the prop proposer has control again
            revert NoZeroAddress();
            }

            address currentAdmin = _propdateInfo[propIds[i]].propUpdateAdmin;
            _propdateInfo[propIds[i]].propUpdateAdmin = newAdmins[i];
            _propdateInfo[propIds[i]].isCompleted = statuses[i];

            emit PropUpdateAdminMigrated(propIds[i], currentAdmin, newAdmins[i]);
        }
    }

    /// @notice Posts an update for a prop
    /// @param propId The id of the prop
    /// @param isCompleted Whether the primary work of the prop is considered done
    /// @param update A string describing the update
    function postUpdate(uint256 propId, bool isCompleted, string calldata update) external {
        uint256 startGas = gasleft();
        
        address currentAdmin = _propdateInfo[propId].propUpdateAdmin;

        if (msg.sender != currentAdmin) {
           if (currentAdmin == address(0) && msg.sender == NounsDAOLogicV2(NOUNS_DAO).proposals(propId).proposer) {
                _propdateInfo[propId].propUpdateAdmin = msg.sender;
                emit PropUpdateAdminTransferred(propId, address(0), msg.sender);
            } else {
                revert OnlyPropUpdateAdmin();
           }
        }

        _propdateInfo[propId].lastUpdated = uint88(block.timestamp);
        // only set this value if true, so that it can't be unset
        if (isCompleted) {
            _propdateInfo[propId].isCompleted = true;
        }

        emit PostUpdate(propId, isCompleted, update);

        if (NounsDAOLogicV2(NOUNS_DAO).proposals(propId).executed) {
            GasRefund.refundGas(startGas);
        }
    }

    /// @notice Returns the propdate info for a prop
    /// @param propId The id of the prop
    /// @return info propdate info
    function propdateInfo(uint256 propId) external view returns (PropdateInfo memory) {
        return _propdateInfo[propId];
    }

    /// @notice sets a new superAdmin for Propdates
    /// @param _newSuperAdmin the address to be the new superAdmin
    function setSuperAdmin(address _newSuperAdmin) external onlyOwner {
        address oldSuperAdmin = superAdmin;
        superAdmin = _newSuperAdmin;

        emit SuperAdminTransferred(oldSuperAdmin, superAdmin);
    }

    /// @notice withdraws balance of contract to an address
    /// @param _to the address to withdraw balance to
    function withdraw(address payable _to) external onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}