pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "./IERC20.sol";
import "./Ownable.sol";
import "./ITacoswapV2Pair.sol";
import "./IMasterChef.sol";
import "./IETacoChef.sol";
import "./DummyToken.sol";


/**
 *@title Migrator contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorDummy is Ownable {
    IMasterChef public oldChef;
    IETacoChef public newChef;
    uint256 public desiredLiquidity = type(uint256).max;

    mapping(address => address) public lpTokenToDummyToken;

    mapping(address => bool) public isMigrated;

    /**
     *  @param _oldChef The address of TacoChef contract.
     *  @param _newChef The address of eTacoChef.
     **/
    constructor(
        address _oldChef,
        address _newChef
    ) {
        require(_oldChef != address(0x0), "Migrator::set zero address");
        require(_newChef != address(0x0), "Migrator::set zero address");
        oldChef = IMasterChef(_oldChef);
        newChef = IETacoChef(_newChef);
    }

    /**
     * @dev Migrates pools which pids are given in array(pools).
     *      Can be called one time, when eTacoChef poolInfo is empty.
     * @param pools Array which contains pids that must be migrated.
     **/
    function migratePools(uint256[] memory pools) external onlyOwner {
        uint256 poolsLength = pools.length;

        for (uint256 i = 0; i < poolsLength; i++) {
            (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accTacoPerShare) =
                oldChef.poolInfo(pools[i]);

            ITacoswapV2Pair lp = ITacoswapV2Pair(lpToken);

            DummyToken dummyToken = new DummyToken();
            uint256 lpAmount = lp.balanceOf(address(newChef));
            dummyToken.mint(address(newChef), lpAmount);
            dummyToken.mint(msg.sender, 1e21);

            lpTokenToDummyToken[lpToken] = address(dummyToken);

            newChef.setPool(
                address(dummyToken),
                allocPoint,
                lastRewardBlock,
                accTacoPerShare
            );
        }
    }

    /**
     *  @dev Migrates UserInfo from TacoChef to eTacoChef
     *   Can be called by user one time and required to call deposit function
     *   with amount = 0, for all pools where the user have some amount before migration.
     **/
    function migrateUserInfo() external onlyOwner {
        require(!isMigrated[msg.sender], "Migrator: Already migrated");
        for (uint256 i = 0; i < 17; i++) {
            (uint256 amount, uint256 rewardDebt) = oldChef.userInfo(i, msg.sender);
            if (amount == 0) continue;
            newChef.setUser(i, msg.sender, amount, rewardDebt);
        }
        isMigrated[msg.sender] = true;
    }

    /**
     *  @dev Migrates LP tokens from TacoChef to eTacoChef.
     *   Deploy DummyToken. Mint DummyToken with the same amount of LP tokens.
     *   DummyToken is neaded to pass require in TacoChef contracts migrate function.
     **/
    function migrate(ITacoswapV2Pair orig) public onlyOwner returns (IERC20) {
        // Transfer all LP tokens from oldMaster to newMaster
        // Deploy dummy token
        // Mint same amount of dummy token for oldMaster
        require(
            msg.sender == address(oldChef),
            "Migrator: not from old master chef"
        );

        DummyToken dummyToken = new DummyToken();
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return dummyToken;

        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(newChef), lp);
        dummyToken.mint(msg.sender, lp);
        desiredLiquidity = type(uint256).max;
        return dummyToken;
    }
}
