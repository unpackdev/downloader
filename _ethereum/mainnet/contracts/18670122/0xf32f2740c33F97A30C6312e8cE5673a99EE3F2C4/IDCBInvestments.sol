// SPDX-License-Identifier: UNLICENSED

//** DCB Investments Interface */
//** Author Aaron & Aceson : DCB 2023.2 */

pragma solidity 0.8.19;

interface IDCBInvestments {
    event DistributionClaimed(address _user, address _event);
    event ImplementationsChanged(address _newVesting, address _newTokenClaim, address _newCrowdfunding);
    event Initialized(uint8 version);
    event ManagerRoleSet(address _user, bool _status);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event UserInvestmentSet(address _address, address _event, uint256 _amount);

    function changeImplementations(address _newVesting, address _newTokenClaim, address _newCrowdfunding) external;

    function changeVestingStartTime(address _event, uint256 _newTime) external;

    function claimDistribution(address _event) external returns (bool);

    function crowdfundingImpl() external view returns (address);

    function events(address)
        external
        view
        returns (
            string memory name,
            address paymentToken,
            address tokenAddress,
            address vestingAddress,
            uint8 eventType
        );

    function eventsList(uint256) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getUserInvestments(address _address) external view returns (address[] memory);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialize() external;

    function numUserInvestments(address) external view returns (uint256);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setManagerRole(address _user, bool _status) external;

    function setUserInvestment(address _address, address _event, uint256 _amount) external returns (bool);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokenClaimImpl() external view returns (address);

    function userAmount(address, address) external view returns (uint256);

    function vestingImpl() external view returns (address);
}
