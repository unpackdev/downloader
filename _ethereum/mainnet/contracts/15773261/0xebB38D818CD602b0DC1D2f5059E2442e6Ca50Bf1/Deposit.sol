// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";

// Uncomment this line to use console.log
// import "./console.sol";

contract Deposit is Initializable, AccessControlUpgradeable {
    IERC20Upgradeable public usdt;
    
    bytes32 public constant ROLE_WITHDRAWER = "WITHDRAWER";

    event Withdrawed(address receiver, uint256 amount);


    modifier onlyAdmin {
        require(IsAdmin(msg.sender), "Only admin");
        _;
    }
    modifier onlyWithdrawerRole() {
        require(hasRole(ROLE_WITHDRAWER, msg.sender), "Not withdawer role");
        _;
    }
    // -------------------------------------------------------
    function initialize(address admin, address _usdtAddress) public initializer {
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        usdt = IERC20Upgradeable(_usdtAddress);
    }

    function IsAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function SetAdmin(address _address) public {
        require(IsAdmin(msg.sender), "Only admin");
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function ChangeAdmin(address _address) public onlyAdmin {
         grantRole(DEFAULT_ADMIN_ROLE, _address);
         revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // -------------------------------------------------------
    // this func need admin role. grantRole and revokeRole need admin role
    function SetRoles(
        bytes32 roleType,
        address[] calldata addresses,
        bool[] calldata setTo
    ) external onlyAdmin{
        _setRoles(roleType, addresses, setTo);
    }

    function _setRoles(
        bytes32 roleType,
        address[] calldata addresses,
        bool[] calldata setTo
    ) private onlyAdmin{
        require(addresses.length == setTo.length, "parameter address length not eq");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (setTo[i]) {
                grantRole(roleType, addresses[i]);
            } else {
                revokeRole(roleType, addresses[i]);
            }
        }
    }

    function SetWithdrawerRole(address[] calldata withdrawers, bool[] calldata setTo) public onlyAdmin{
       for (uint256 i = 0; i < withdrawers.length; i++) {
           require(!IsAdmin(withdrawers[i]), "Can not set withdrawer role to admin");
       }
        _setRoles(ROLE_WITHDRAWER, withdrawers, setTo);
    }

    function withdraw() public onlyWithdrawerRole {
        uint256 balance = usdt.balanceOf(address(this));
        if (balance > 0) {
            usdt.transfer(msg.sender, balance);
        }

        emit Withdrawed(msg.sender, balance);
    }
}