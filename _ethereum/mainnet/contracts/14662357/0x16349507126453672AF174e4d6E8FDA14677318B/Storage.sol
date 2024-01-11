// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ReentrancyGuard.sol";
import "./EoaGuard.sol";

import "./Ownable.sol";

/**
 * @title Storage
 * @author JieLi
 *
 * @notice Local Variables
 */
contract Storage is Ownable, ReentrancyGuard {

    // ============ Variables for Control ============

    bool public _DROP_ALLOWED_;
    bool public _PRESALE_ALLOWED_;
    bool public _REVEAL_ALLOWED_;
    bool public _RAFFLE_ALLOWED_;
    uint256 public _PRICE_;
    uint256 public _PRESALE_PRICE_;
    uint256 public _OWNER_PRICE_;
    uint256 public _COUNT_PER_LEVEL_;
    uint256 public _PRESALE_COUNT_;
    uint256 public _WHITE_LIST_COUNT_;
    uint256 public _MAX_TOKEN_LEVEL_;
    uint256 public _MAX_MINT_COUNT_;
    uint256 internal _RANDOM_VALUE_;
    string  public _REVEAL_URI_;
    string  public  _PENDING_URI_;
    string  public  _URI_EXTENSION_;

    // ============ Advanced Controls ============

    mapping(address => bool) public owners;
    mapping(address => bool) public controllers;
    mapping(uint256 => bool) public frozen;
    mapping(uint256 => bool) public charred;
    mapping(uint256 => uint256) public levels;
    mapping(uint256 => uint256) public startTimestamps;

    // ============ Core Address ============


    // ============ Variables for Traits Probability ============

    uint256[] internal _ENVIRONMENT_PROBABILITY_;
    uint256[] internal _SHINE_PROBABILITY_;
    uint256[] internal _EFFICIENCY_PROBABILITY_;

    // ============ Modifiers ============

    modifier onlyRandom() {
        require(_RANDOM_VALUE_ > 0, "NO RANDOM VALUE");
        _;
        _RANDOM_VALUE_ = 0;
    }

    modifier onlyRaffle() {
        require(_RAFFLE_ALLOWED_, "RAFFLE DISABLED");
        _;
        _RAFFLE_ALLOWED_ = false;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "NOT CONTROLLER");
        _;
    }

    modifier onlyOwners() {
        owners[owner()] = true;
        require(owners[msg.sender], "NOT LISTED ON OWNERS");
        _;
    }

    // ============ Helper Functions ============

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }
}
