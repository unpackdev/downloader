// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.3;

import "./Ownable.sol";

interface IToken {
    function mint(address _receiver, uint256 _amount) external;
    function burn(address _receiver, uint256 _amount) external;
}

contract GRODistributer is Ownable {
    
    enum pool { NONE, DAO, INVESTOR, TEAM, COMMUNITY }
    // Limits for token minting
    uint256 public constant DEFAULT_FACTOR = 1E18;
    // Amount dedicated to the dao
    uint256 public constant DAO_QUOTA = 8_000_000 * DEFAULT_FACTOR;
    // Amount dedicated to the investor group
    uint256 public constant INVESTOR_QUOTA = 19_490_577 * DEFAULT_FACTOR;
    // Amount dedicated to the team
    uint256 public constant TEAM_QUOTA = 22_509_423 * DEFAULT_FACTOR;
    // Amount dedicated to the community
    uint256 public constant COMMUNITY_QUOTA = 45_000_000 * DEFAULT_FACTOR;

    IToken public immutable govToken; 
    address public daoMinter;
    // contracts that are allowed to mint, and which pool they can mint from
    mapping(address => uint256) public vesters;
    // contracts that are allowed to burn
    mapping(address => bool) public burners;
    // pool with minting limits for vesters
    mapping(pool => uint256) public mintingPools;

    constructor(
        address token,
        address _dao
    ) {
        govToken = IToken(token);
        mintingPools[pool.DAO] = DAO_QUOTA;
        mintingPools[pool.INVESTOR] = INVESTOR_QUOTA;
        mintingPools[pool.TEAM] = TEAM_QUOTA;
        mintingPools[pool.COMMUNITY] = COMMUNITY_QUOTA;
        transferOwnership(_dao);
    }

    // @dev Set vester contracts that can mint tokens
    // @param vesters target contract
    // @param status add/remove from vester role
    function setVester(address vester, uint256 role) external onlyOwner {
        require(!burners[vester], 'setVester: burner cannot be vester');
        // Can only have one daoVester
        if (role == 1) {
            vesters[daoMinter] = 0;
            daoMinter = vester;
        }
        vesters[vester] = role;
    }

    // @dev Set burner contracts, that can burn tokens
    // @param burner target contract
    // @param status add/remove from burner pool
    function setBurner(address burner, bool status) external onlyOwner {
        require(vesters[burner] == 0, 'setBurner: vester cannot be burner');
        burners[burner] = status;
    }

    // @dev mint tokens - Reduces total allowance for minting pool
    // @param account account to mint for
    // @param amount amount to mint
    function mint(address account, uint256 amount) external {
        require(vesters[msg.sender] > 1, "mint: msg.sender != vester");
        uint256 poolId = vesters[msg.sender];
        if (poolId > 4) {
            poolId = 4;
        }
        mintingPools[pool(poolId)] = mintingPools[pool(poolId)] - amount;
        govToken.mint(account, amount);
    }

    // @dev mintDao seperate minting function for dao vester - can mint from both
    //      community and dao quota
    // @param account account to mint for
    // @param amount amount to mint
    // @param pool pool whos' allowance to reduce
    function mintDao(address account, uint256 amount, bool community) external {
        require(vesters[msg.sender] == 1, "mint: msg.sender != dao");
        uint256 poolId = 1;
        if (community) {
            poolId = 4;
        }
        mintingPools[pool(poolId)] = mintingPools[pool(poolId)] - amount;
        govToken.mint(account, amount);
    }

    // @dev burn tokens - adds allowance to community pool
    // @param account account whos' tokens to burn
    // @param amount amount to burn
    function burn(address account, uint256 amount) external {
        require(burners[msg.sender], "burn: msg.sender != burner");
        govToken.burn(account, amount);
        mintingPools[pool(4)] = mintingPools[pool(4)] + amount;
    }
}
