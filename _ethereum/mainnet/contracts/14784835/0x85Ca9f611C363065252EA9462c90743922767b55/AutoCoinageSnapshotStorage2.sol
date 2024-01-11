// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Counters.sol";
import "./Arrays.sol";

contract AutoCoinageSnapshotStorage2 is AccessControl {
    using Arrays for uint256[];
    using Counters for Counters.Counter;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Layer2Snapshots {
        address[] layer2s;
        uint256[] snapshotIds;
    }

    struct BalanceSnapshots {
        uint256[] ids;
        uint256[] balances;
    }

    struct FactorSnapshots {
        uint256[] ids;
        uint256[] factors;
        uint256[] refactorCounts;
    }

    uint256 public REFACTOR_BOUNDARY = 10 ** 28;
    uint256 public REFACTOR_DIVIDER = 2;

    address public seigManager ;
    address public layer2Registry ;

    // layer2- account - balance
    mapping(address => mapping(address => BalanceSnapshots)) internal accountBalanceSnapshots;
    // layer2- account - snapahot - RefactoredCounts
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal accountRefactoredCounts;
    // layer2- account - snapahot - Remains
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal accountRemains;

    // layer2- totalSupply
    mapping(address => BalanceSnapshots) internal totalSupplySnapshots;
    // layer2- totalSupply - snapahot - RefactoredCounts
    mapping(address => mapping(uint256 => uint256)) internal totalSupplyRefactoredCounts;
    // layer2- totalSupply - snapahot - Remains
    mapping(address => mapping(uint256 => uint256)) internal totalSupplyRemains;

    //layer2- factor
    mapping(address => FactorSnapshots) internal factorSnapshots;


    // layer2 ->currentLayer2SnapshotId
    mapping(address => uint256)  public currentLayer2SnapshotId;

    //snashotAggregatorId ->
    mapping(uint256 => Layer2Snapshots)  internal snashotAggregator;
    uint256 public snashotAggregatorTotal;

    bool public pauseProxy;
    bool public migratedL2;


    //--- unused
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    //---
    string public name;
    string public symbol;
    uint256 public decimals;


    //--
    address[] public layer2s;
    mapping(address => bool) public existLayer2s;

    // layer2 - accounts
    mapping(address => address[]) public needSyncs;

}
