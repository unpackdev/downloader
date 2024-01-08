//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

/*
    ▓█████▄ ▓█████   █████▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓ ▒█████   ██▀███
    ▒██▀ ██▌▓█   ▀ ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒
    ░██   █▌▒███   ▒████ ░▒██░    ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒
    ░▓█▄   ▌▒▓█  ▄ ░▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄
    ░▒████▓ ░▒████▒░▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░      ░ ▒ ▒░   ░▒ ░ ▒░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░          ░      ░ ░ ░ ▒    ░░   ░
       ░       ░  ░           ░  ░   ░  ░░ ░                   ░ ░     ░
     ░                                   ░
*/

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IDeflector.sol";
import "./IERC20MintSnapshot.sol";

/**
 * @title Deflector
 * @author DEFLECT PROTOCOL
 * @dev This contract handles spendable and global token effects on contracts like farming pools.
 *
 * Default numeric values used for percentage calculations should be divided by 1000.
 * If the default value for amount in Spendable is 20, it's meant to represeent 2% (i * amount / 1000)
 *
 * Range structs range values should be set as ether-values of the wanted values. (r1 = 5, r2 = 10)
 */

contract Deflector is Ownable, IDeflector {
    using SafeMath for uint256;

    uint256 private constant PERCENTAGE_DENOMINATOR = 1000;
    IERC20MintSnapshot public immutable prism;

    struct GlobalBoostLevel {
        uint256 lowerBound;
        uint256 percentage;
    }

    struct LocalBoostLevel {
        uint256 cumulativeCost;
        uint256 percentage;
    }

    struct User {
        address[] tokensLeveled;
        mapping(address => uint256) levelPerToken;
    }

    struct Pool {
        address[] boostTokens;
        bool exists;
        mapping(address => User) users;
        mapping(address => LocalBoostLevel[]) localBoosts;
    }

    mapping(address => Pool) public pools;

    GlobalBoostLevel[] public globalBoosts;

    modifier onlyPool() {
        require(
            pools[msg.sender].exists,
            "Deflector::onlyPool: Insufficient Privileges"
        );
        _;
    }

    constructor(IERC20MintSnapshot _prism) public Ownable() {
        prism = _prism;
        // Tier 1: 15 PRISM -> 5%
        globalBoosts.push(GlobalBoostLevel(15 ether, 50));
        // Tier 2: 30 PRISM -> 10%
        globalBoosts.push(GlobalBoostLevel(30 ether, 100));
        // Tier 3: 75 PRISM -> 25%
        globalBoosts.push(GlobalBoostLevel(75 ether, 250));
        // Tier 4: 150 PRISM -> 50%
        globalBoosts.push(GlobalBoostLevel(150 ether, 500));
    }

    function addPool(address pool) external onlyOwner() {
        pools[pool].exists = true;
    }

    function getPoolInfor(address pool, address _token)
        external
        view
        returns (address[] memory, LocalBoostLevel[] memory)
    {
        uint256 lengthBoostToken = pools[pool].boostTokens.length;
        uint256 lengthlocalBoostLevel = pools[pool].localBoosts[_token].length;
        address[] memory boostTokens = new address[](lengthBoostToken);
        LocalBoostLevel[] memory localBoostLevel =
            new LocalBoostLevel[](lengthlocalBoostLevel);
        // boostTokens[0] = address(0);
        for (uint256 i = 0; i < lengthBoostToken; i++) {
            boostTokens[i] = pools[pool].boostTokens[i];
        }

        for (uint256 i = 0; i < lengthlocalBoostLevel; i++) {
            localBoostLevel[i] = pools[pool].localBoosts[_token][i];
        }
        //  = pools[pool].boostTokens;
        //  = pools[pool].localBoosts;
        return (boostTokens, localBoostLevel);
    }

    function addLocalBoost(
        address _pool,
        address _token,
        uint256[] calldata costs,
        uint256[] calldata percentages
    ) external onlyOwner() {
        require(
            costs.length == percentages.length,
            "Deflector::addLocalBoost: Incorrect cost & percentage length"
        );
        Pool storage pool = pools[_pool];

        if (pool.localBoosts[_token].length == 0) pool.boostTokens.push(_token);

        for (uint256 i = 0; i < costs.length; i++) {
            pool.localBoosts[_token].push(
                LocalBoostLevel(costs[i], percentages[i])
            );
        }
    }

    function updateLocalBoost(
        address _pool,
        address _token,
        uint256[] calldata costs,
        uint256[] calldata percentages
    ) external onlyOwner() {
        require(
            costs.length == percentages.length,
            "Deflector::addLocalBoost: Incorrect cost & percentage length"
        );
        Pool storage pool = pools[_pool];
        for (uint256 i = 0; i < costs.length; i++) {
            pool.localBoosts[_token][i] = LocalBoostLevel(
                costs[i],
                percentages[i]
            );
        }
    }

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external override onlyPool() returns (uint256) {
        Pool storage pool = pools[msg.sender];
        User storage user = pool.users[_user];

        if (user.levelPerToken[_token] == 0) {
            user.tokensLeveled.push(_token);
        }

        user.levelPerToken[_token] = _nextLevel;

        return calculateBoostedBalance(_user, _balance);
    }

    function calculateBoostedBalance(address _user, uint256 _balance)
        public
        view
        override
        returns (uint256)
    {
        uint256 mintedPrism = prism.getPriorMints(_user, block.number - 1);

        // Calculate Global Boost
        uint256 loopLimit = globalBoosts.length;
        uint256 i;
        for (i = 0; i < loopLimit; i++) {
            if (mintedPrism < globalBoosts[i].lowerBound) break;
        }

        uint256 totalBoost;
        if (i > 0) totalBoost = globalBoosts[i - 1].percentage;

        // Calculate Local Boost
        Pool storage pool = pools[msg.sender];

        // Safe arithmetics here
        loopLimit = pool.boostTokens.length;
        for (i = 0; i < loopLimit; i++) {
            address token = pool.boostTokens[i];
            uint256 userLevel = pool.users[_user].levelPerToken[token];
            if (userLevel == 0) continue;
            totalBoost += pool.localBoosts[token][userLevel - 1].percentage;
        }
        return _balance.mul(totalBoost) / PERCENTAGE_DENOMINATOR;
    }

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view override returns (uint256) {
        Pool storage pool = pools[msg.sender];
        User storage user = pool.users[_user];
        require(
            _nextLevel != 0 && _nextLevel <= pool.localBoosts[_token].length,
            "Deflector::calculateCost: Incorrect Level Specified"
        );
        uint256 currentLevel = user.levelPerToken[_token];
        uint256 currentCost =
            currentLevel == 0
                ? 0
                : pool.localBoosts[_token][currentLevel - 1].cumulativeCost;
        return
            pool.localBoosts[_token][_nextLevel - 1].cumulativeCost.sub(
                currentCost
            );
    }
}
