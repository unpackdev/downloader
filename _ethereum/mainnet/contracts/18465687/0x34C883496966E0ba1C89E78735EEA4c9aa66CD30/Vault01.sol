// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC1967UpgradeUpgradeable.sol";

struct ExecuteCall {
    address to;
    uint256 value;
    bytes data;
}

contract Vault01 is
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1967UpgradeUpgradeable
{
    using AddressUpgradeable for address;

    error TransactionFailed(uint256 txIndex);
    error InvalidContract(uint256 txIndex, address contractAddress);
    error NotEnoughBalance(
        uint256 txIndex,
        uint256 valueNeeded,
        uint256 currentBalance
    );

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC1967Upgrade_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROLLER_ROLE, msg.sender);
    }

    function execute(
        ExecuteCall[] calldata calls
    ) public payable onlyRole(CONTROLLER_ROLE) nonReentrant {
        for (uint256 i = 0; i < calls.length; ) {
            // Fail if we want to call the contract and it doesn't exist.
            // Note that we are checking if we are actually making a call to
            //  a contract by checking data.length. We still want to be able to
            //  simply send ether to EOAs (data is empty)
            if (calls[i].data.length > 0 && !calls[i].to.isContract()) {
                revert InvalidContract(i, calls[i].to);
            }
            if (calls[i].value > address(this).balance) {
                revert NotEnoughBalance(
                    i,
                    calls[i].value,
                    address(this).balance
                );
            }
            (bool success, ) = calls[i].to.call{value: calls[i].value}(
                calls[i].data
            );
            if (!success) {
                revert TransactionFailed(i);
            }
            unchecked {
                i++;
            }
        }
    }

    function getRoleMembers(
        bytes32 role
    ) public view returns (address[] memory) {
        uint256 count = getRoleMemberCount(role);
        address[] memory members = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    // allow contract o receive ether
    receive() external payable {}

    function upgradeTo(
        address newImplementation
    ) external onlyRole(UPGRADER_ROLE) {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external payable onlyRole(UPGRADER_ROLE) {
        _upgradeToAndCall(newImplementation, data, true);
    }

    function version() public pure virtual returns (string memory) {
        return "v1.0.0";
    }
}
