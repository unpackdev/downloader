// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.10;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./VersionedInitializable.sol";


/**
* @title DigipharToTerraMigrator
* @notice This contract implements the migration from Ethereum to Terra blockchain
* @author inventronforce.com 
*/
contract DigipharmToTerraMigrator is VersionedInitializable {
    using SafeMath for uint256;

    IERC20 public immutable DPH;
    uint256 public constant REVISION = 1;
    
    uint256 public _totalDPHMigrated;

    /**
    * @dev emitted on migration
    * @param sender the caller of the migration
    * @param amount the amount being migrated
    */
    event DPHMigrated(address indexed sender, bytes32 indexed to, uint256 indexed amount);

    /**
    * @param dph the address of the DPH token
     */
    constructor(IERC20 dph) public {
        DPH = dph;
    }

    /**
    * @dev initializes the implementation
    */
    function initialize() public initializer {
    }

    /**
    * @dev returns true if the migration started
    */
    function migrationStarted() external view returns(bool) {
        return lastInitializedRevision != 0;
    }


    /**
    * @dev executes the migration from DPH on Ethereum to DPH on Terra. Users need to give allowance to this contract to transfer DPH before executing
    * this transaction. Once the tokens are locked in the Migrator contract, DPHMigrated event is emitted.
    * @param amount the amount of DPH to be migrated
    */
    function migrateFromETH(uint256 amount, bytes32 to) external {
        require(lastInitializedRevision != 0, "MIGRATION_NOT_STARTED");

        _totalDPHMigrated = _totalDPHMigrated.add(amount);
        DPH.transferFrom(msg.sender, address(this), amount);
        emit DPHMigrated(msg.sender, to, amount);
    }

    /**
    * @dev returns the implementation revision
    * @return the implementation revision
    */
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

}