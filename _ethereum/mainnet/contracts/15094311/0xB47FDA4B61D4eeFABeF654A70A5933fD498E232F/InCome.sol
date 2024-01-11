// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./RootDB.sol";

contract Income {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    /// @notice An event emitted when operator distribute torn
    /// @param torn: the amount of the TORN distributed
    event distribute_torn(uint256 torn);


    constructor(
        address _torn_contract,
        address _root_db
    ) {
        TORN_CONTRACT = _torn_contract;
        ROOT_DB = _root_db;
    }
    /**
      * @notice distributeTorn used to distribute TORN to deposit contract which belong to stakes
      * @param _torn_qty the amount of TORN
   **/
    function distributeTorn(uint256 _torn_qty) external {
        address deposit_address = RootDB(ROOT_DB).depositContract();
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT), deposit_address, _torn_qty);
        emit distribute_torn(_torn_qty);
    }

    receive() external payable {

    }

}
