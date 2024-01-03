// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./UniswapAware.sol";


contract RoleAware is AccessControl, UniswapAware {
    bytes32 public constant STAKING_POOL_ROLE = keccak256("STAKING_POOL_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant WHITELIST_TO_ROLE = keccak256("WHITELIST_TO_ROLE");
    bytes32 public constant WHITELIST_FROM_ROLE =
        keccak256("WHITELIST_FROM_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    address payable public _developer;

    constructor(address payable developer, address[] memory stakingPools)
        public
    {
        _developer = developer;

        _setupRole(DEVELOPER_ROLE, _developer);
        _setupRole(DEFAULT_ADMIN_ROLE, _developer);

        grantRole(WHITELIST_ROLE, address(this));
        // O(n) iteration allowed as stakingPools will contain very few items
        for (uint256 i = 0; i < stakingPools.length; i++) {
            grantRole(STAKING_POOL_ROLE, stakingPools[i]);
            grantRole(WHITELIST_ROLE, stakingPools[i]);
        }
    }

    modifier onlyDeveloper() {
        require(hasRole(DEVELOPER_ROLE, msg.sender), "Caller is not developer");
        _;
    }

    // distinct from external staking pools, Ape staking pools can mint rewards for users
    modifier onlyStakingPool() {
        require(
            hasRole(STAKING_POOL_ROLE, msg.sender),
            "Caller is not a staking pool"
        );
        _;
    }

    // needed to add new external liquidity pools - pools should not be burned by default
    function addWhitelist(address grantee) public onlyDeveloper {
        grantRole(WHITELIST_ROLE, grantee);
    }

    function addWhitelistTo(address grantee) public onlyDeveloper {
        grantRole(WHITELIST_TO_ROLE, grantee);
    }

    function addWhitelistFrom(address grantee) public onlyDeveloper {
        grantRole(WHITELIST_FROM_ROLE, grantee);
    }

    function anyWhitelisted(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return (hasRole(WHITELIST_ROLE, sender) ||
            hasRole(WHITELIST_ROLE, recipient) ||
            hasRole(WHITELIST_ROLE, msg.sender) ||
            hasRole(WHITELIST_TO_ROLE, recipient) ||
            hasRole(WHITELIST_FROM_ROLE, sender));
    }
}
