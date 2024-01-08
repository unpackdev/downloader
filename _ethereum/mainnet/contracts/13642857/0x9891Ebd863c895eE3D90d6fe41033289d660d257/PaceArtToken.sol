// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

// WARNING: There is a known vuln contained within this contract related to vote delegation, 
// it's NOT recommmended to use this in production.  

// SushiToken with Governance.
contract PaceArtToken is ERC20, AccessControl {
    using SafeMath for uint;

    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = bytes32("BURNER_ROLE");

    uint256 private _cap = 1e26;

    uint public constant MARKETPLACE_INDEX = 0;
    uint public constant PACE_TEAM_INDEX = 1;
    uint public constant PUBLIC_SALE_INDEX = 2;
    uint public constant MARKETING_INDEX = 3;
    uint public constant SEED_INVESTOR_INDEX = 4;
    uint public constant COMMUNITY_INDEX = 5;

    // 100 M total supply
    uint256[7] private _pools_amount = [
        30000000 * (10**18), // MARKETPLACE REWARD.
        25000000 * (10**18), // PACE TEAM.
        13000000 * (10**18), // PUBLIC SALE.
        10000000 * (10**18), // MARKETING AND CREATORS.
        7000000 * (10**18), // SEED INVESTORS.
        5000000 * (10**18), // COMMUNITY AIRDROP.
        10000000 * (10 ** 18) // LIQUIDITY MINING.
    ];

    mapping(uint => bool) public minted_pools;

    constructor(
        address MARKETPLACE,
        address PACE_TEAM,
        address PUBLIC_SALE,
        address MARKETING_CREATORS,
        address SEED_INVESTORS,
        address COMMUNITY
    ) ERC20("Pace Art", "PACE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(MARKETPLACE, _pools_amount[MARKETPLACE_INDEX]);
        minted_pools[MARKETPLACE_INDEX] = true;

        _mint(PACE_TEAM, _pools_amount[PACE_TEAM_INDEX]);
        minted_pools[PACE_TEAM_INDEX] = true;

        _mint(PUBLIC_SALE, _pools_amount[PUBLIC_SALE_INDEX]);
        minted_pools[PUBLIC_SALE_INDEX] = true;

        _mint(MARKETING_CREATORS, _pools_amount[MARKETING_INDEX]);
        minted_pools[MARKETING_INDEX] = true;

        _mint(SEED_INVESTORS, _pools_amount[SEED_INVESTOR_INDEX]);
        minted_pools[SEED_INVESTOR_INDEX] = true;

        _mint(COMMUNITY, _pools_amount[COMMUNITY_INDEX]);
        minted_pools[COMMUNITY_INDEX] = true;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "PaceArtToken:You not be able to do that");
        _;
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply().add(_amount) <= cap(), "PaceArtToken::Exceeds max cap!");
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyRole(BURNER_ROLE) {
        _burn(_account, _amount);
    }

     /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function grantMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _minter);
    }

    function grantBurner(address _burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BURNER_ROLE, _burner);
    }
}
