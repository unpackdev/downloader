pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "./IERC20.sol";
import "./Ownable.sol";
import "./IMasterChef.sol";
import "./IETacoChef.sol";
import "./MigratorDummy.sol";
import "./DummyToken.sol";


/**
 *@title MigratorPOOLZ contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorPOOLZ is Ownable {
    IMasterChef public oldChef;
    IETacoChef public newChef;
    MigratorDummy public dummyMigrator;

    /**
     *  @param _oldChef The address of TacoChef contract.
     *  @param _newChef The address of eTacoChef.
     *  @param _dummyMigrator The address of MigratorDummy.
     **/
    constructor(
        address _oldChef,
        address _newChef,
        address _dummyMigrator
    ) {
        require(_oldChef != address(0x0), "Migrator::set zero address");
        require(_dummyMigrator != address(0x0), "Migrator::set zero address");
        require(_newChef != address(0x0), "Migrator::set zero address");
        oldChef = IMasterChef(_oldChef);
        newChef = IETacoChef(_newChef);
        dummyMigrator = MigratorDummy(_dummyMigrator);
    }

    /**
     *  @dev Migrates LP tokens from TacoChef to eTacoChef.
     *   Deploy DummyToken. Mint DummyToken with the same amount of LP tokens.
     *   DummyToken is neaded to pass require in TacoChef contracts migrate function.
     **/
    function migrate(ITacoswapV2Pair orig) public returns (IERC20) {
        require(
            msg.sender == address(oldChef),
            "Migrator: not from old master chef"
        );

        require(address(orig) == address(0x70A3944215De6FA1463A098bA182634dF90bB9F4), "Only ETH-POOLZ");

        uint256 lp = orig.balanceOf(msg.sender);

        IERC20 dummyToken = IERC20(dummyMigrator.lpTokenToDummyToken(address(orig)));

        orig.transferFrom(msg.sender, address(newChef), lp);
        dummyToken.transferFrom(address(newChef), address(oldChef), lp);

        return dummyToken;
    }
}
