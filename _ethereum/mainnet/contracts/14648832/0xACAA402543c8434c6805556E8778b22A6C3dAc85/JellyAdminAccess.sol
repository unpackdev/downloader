pragma solidity 0.8.6;

import "AccessControl.sol";
import "IJellyContract.sol";


contract JellyAdminAccess is AccessControl, IJellyContract  {

    /// @notice Jelly template id for the pool factory.
    uint256 public override TEMPLATE_TYPE = 7;
    bytes32 public override TEMPLATE_ID = keccak256("ADMIN_ACCESS");


    /// @dev Whether access is initialised.
    bool private initAccess;

    /// @notice Events for adding and removing various roles.
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    /// @notice The deployer needs to initAccessControls()
    constructor() {

    }

    /**
     * @notice Initializes access controls.
     * @param _admin Admins address.
     */
    function initAccessControls(address _admin) public {
        require(!initAccess, "Already initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        initAccess = true;
    }

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role.
     * @param _address EOA or contract being checked.
     * @return bool True if the account has the role or false if it does not.
     */
    function hasAdminRole(address _address) public  view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract receiving the new role.
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the admin role from an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract affected.
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }


    function init(bytes calldata _data) external virtual override payable {}

    function initContract(
        bytes calldata _data
    ) public virtual override {
        (
        address _admin
        ) = abi.decode(_data, (address));

        initAccessControls(_admin);
    }

//    /** 
//      * @dev Generates init data for Farm Factory
//   */
//     function getInitData(
//         address _admin

//     )
//         external
//         pure
//         returns (bytes memory _data)
//     {
//         return abi.encode(_admin);
//     }


}