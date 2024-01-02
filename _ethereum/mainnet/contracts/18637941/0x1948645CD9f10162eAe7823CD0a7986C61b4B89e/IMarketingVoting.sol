// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IMarketingVoting {
    struct Option {
        string name;
        bool active;
    }
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event GivenVote(address indexed account, uint256 indexed optionIndex);
    event Initialized(uint8 version);
    event Paused(address account);
    event RevokedVote(address indexed account, uint256 indexed optionIndex);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event SnapshottedResult(uint256 indexed index, uint256[] votes);
    event Unpaused(address account);
    event Upgraded(address indexed implementation);

    function CONFIGURATOR_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function PAUSER_ROLE() external view returns (bytes32);

    function PROXY_VOTER_ROLE() external view returns (bytes32);

    function SNAPSHOTER_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function addOption(string memory _option) external;

    function createVoteSnapshot() external;

    function deactivateOption(uint256 index) external;

    function getCurrentVoteResult() external view returns (uint256[] memory);

    function getOptions()
    external
    view
    returns (Option[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVote(address account) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
    external
    view
    returns (bool);

    function initialize(address _veToken) external;

    function optionMapVoters(uint256, address) external view returns (uint256);

    function optionVoters(uint256, uint256) external view returns (address);

    function options(uint256)
    external
    view
    returns (string memory name, bool active);

    function optionsCount() external view returns (uint256);

    function pause() external;

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function question() external view returns (string memory);

    function renounceRole(bytes32 role, address account) external;

    function resetVotes() external;

    function revokeRole(bytes32 role, address account) external;

    function revokeVote() external;

    function setQuestion(string memory _question) external;

    function snapshotsCount() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unpause() external;

    function updateVeToken(address _veToken) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
    external
    payable;

    function veToken() external view returns (address);

    function voteForOption(uint256 index) external;

    function voteForOption(
        uint256 index,
        bytes memory signature,
        address account
    ) external;

    function votersOption(address) external view returns (uint256);
}