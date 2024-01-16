// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./DaxCoin.sol";
import "./DaxMap.sol";
import "./DaxToken.sol";

contract DaxMining is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    event Damage(uint256 indexed miner, uint256 amount);
    event Extract(uint256 indexed miner, address indexed to, uint256 x, uint256 y, uint256 z);
    event Improvement(uint256 indexed miner, uint256 amount);
    event Mine(uint256 indexed miner, uint256 x, uint256 y, uint256 z, uint256 amount);

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant MINER_EXTRACT_ROLE = keccak256("MINER_EXTRACT_ROLE");
    bytes32 public constant MINER_IMPROVE_ROLE = keccak256("MINER_IMPROVE_ROLE");
    bytes32 public constant MINER_MINE_ROLE = keccak256("MINER_MINE_ROLE");
    bytes32 public constant MINING_ADMIN_ROLE = keccak256("MINING_ADMIN_ROLE");
    bytes32 public constant MINING_DAMAGE_ROLE = keccak256("MINING_DAMAGE_ROLE");
    bytes32 public constant MINING_FACTOR_ROLE = keccak256("MINING_FACTOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _miners;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _minerMovements;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _miningFactors;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _miningStarts;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _miningClaims;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _miningWearFactor;
    mapping(uint256 => uint256) private _minerImprovements;
    mapping(uint256 => uint256) private _minerImprovementsPending;
    mapping(uint256 => uint256) private _miningTotals;

    uint256 private _efficiencyBase;
    uint256 private _minerDamageBasisPoints;
    uint256 private _unimprovedMinerPenalty;
    DaxCoin private _coinContract;
    DaxMap private _mapContract;
    DaxToken private _tokenContract;

    constructor() {
        _disableInitializers();
    }

    function initialize(DaxToken tokenContract, DaxMap mapContract, DaxCoin coinContract)
    public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        address sender = _msgSender();
        address coinContractAddress = address(coinContract);

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(CONTRACT_ADMIN_ROLE, sender);
        _grantRole(MINER_EXTRACT_ROLE, coinContractAddress);
        _grantRole(MINER_IMPROVE_ROLE, coinContractAddress);
        _grantRole(MINER_MINE_ROLE, coinContractAddress);
        _grantRole(MINING_ADMIN_ROLE, sender);
        _grantRole(MINING_DAMAGE_ROLE, sender);
        _grantRole(MINING_FACTOR_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

        _tokenContract = tokenContract;
        _mapContract = mapContract;
        _coinContract = coinContract;
        _efficiencyBase = 100000000000000000000; // 100 DAXC
        _miningFactors[0][0][0] = 10000000000000; // 0.00001 DAXC
        _unimprovedMinerPenalty = 10;
        _minerDamageBasisPoints = 275;

        _miningClaims[0][0][0] = 1;
    }

    function blockReward(uint256 miner)
    public view returns (uint256) {
        (uint256 x, uint256 y, uint256 z) = _mapContract.current(miner);

        uint256 mapFactor = _miningFactors[0][0][0];
        uint256 efficiencyFactor = _minerImprovements[miner].div(_efficiencyBase) + 1;
        uint256 pointFactor = _miningFactors[x][y][z];
        uint256 xFactor = _miningFactors[x][0][0];
        uint256 yFactor = _miningFactors[0][y][0];
        uint256 zFactor = _miningFactors[0][0][z];

        if (mapFactor == 0) { mapFactor = 1; }
        if (efficiencyFactor == 1) { mapFactor = mapFactor.div(_unimprovedMinerPenalty); }
        if (pointFactor == 0) { pointFactor = 1; }
        if (xFactor == 0) { xFactor = 1; }
        if (yFactor == 0) { yFactor = 1; }
        if (zFactor == 0) { zFactor = 1; }

        return mapFactor * pointFactor * xFactor * yFactor * zFactor * efficiencyFactor;
    }

    function improvements(uint256 miner)
    public view
    returns (uint256) {
        return _minerImprovements[miner];
    }

    function mined(address account)
    public view
    returns (uint256) {
        uint256 index;
        uint256 total;
        while (index < _tokenContract.balanceOf(account)) {
            total += mined(_tokenContract.tokenOfOwnerByIndex(account, index));
            index++;
        }
        return total;
    }

    function mined(uint256 miner)
    public view
    returns (uint256) {
        if (!mining(miner)) {
            return 0;
        }

        (uint256 x, uint256 y, uint256 z) = _mapContract.current(miner);
        return blockReward(miner) * (block.number - _miningStarts[x][y][z]);
    }

    function mining(uint256 miner)
    public view
    returns (bool) {
        if (!_mapContract.exists(miner)) return false;

        (uint256 x, uint256 y, uint256 z) = _mapContract.current(miner);
        if (_miners[x][y][z] != miner) return false;
        if (_mapContract.inMotion(miner)) return false;

        uint256 time = _mapContract.moveTime(miner);
        if (_miningStarts[x][y][z] < time) return false;
        if (_minerMovements[x][y][z] != time) return false;

        return true;
    }

    function miningClaim(uint256 x, uint256 y, uint256 z)
    public view
    returns (uint256) {
        return _miningClaims[x][y][z];
    }

    function miningFactor(uint256 x, uint256 y, uint256 z)
    public view
    returns (uint256) {
        return _miningFactors[x][y][z];
    }

    function totalMined(uint256 miner)
    public view
    returns (uint256) {
        return _miningTotals[miner];
    }

    function improve(address account, uint256 amount)
    public onlyRole(MINER_IMPROVE_ROLE) {
        uint256 remaining = amount;
        uint256 count = _tokenContract.balanceOf(account);
        uint256 share = remaining.div(count);
        uint256 index;
        while (index < count) {
            uint256 token = _tokenContract.tokenOfOwnerByIndex(account, index);
            if (remaining == 0) {
                break;
            } else if (remaining < share) {
                _improve(token, remaining);
                remaining = 0;
            } else {
                _improve(token, share);
                remaining -= share;
            }
            index++;
        }
    }

    function improve(uint256 miner, uint amount)
    public onlyRole(MINER_IMPROVE_ROLE) {
        _improve(miner, amount);
    }

    function mine(address account)
    public onlyRole(MINER_MINE_ROLE)
    returns (uint256) {
        uint256 index;
        uint256 total;
        while (index < _tokenContract.balanceOf(account)) {
            total += _mine(_tokenContract.tokenOfOwnerByIndex(account, index));
            index++;
        }
        return total;
    }

    function mine(uint256 miner)
    public onlyRole(MINER_MINE_ROLE)
    returns (uint256) {
        return _mine(miner);
    }

    function __config()
    public view
    returns (
        DaxMap mapContract,
        DaxToken tokenContract,
        DaxCoin coinContract,
        uint256 baseMiningFactor,
        uint256 efficiencyBase,
        uint256 minerDamageBasisPoints,
        uint256 unimprovedMinerPenalty)
    {
        mapContract = _mapContract;
        tokenContract = _tokenContract;
        coinContract = _coinContract;
        baseMiningFactor = _miningFactors[0][0][0];
        efficiencyBase = _efficiencyBase;
        minerDamageBasisPoints = _minerDamageBasisPoints;
        unimprovedMinerPenalty = _unimprovedMinerPenalty;
    }

    function __baseMiningFactor()
    public view returns (uint256) {
        return _miningFactors[0][0][0];
    }

    function __coinContract()
    public view returns (DaxCoin) {
        return _coinContract;
    }

    function __efficiencyBase()
    public view returns (uint256) {
        return _efficiencyBase;
    }

    function __mapContract()
    public view returns (DaxMap) {
        return _mapContract;
    }

    function __minerDamageBasisPoints()
    public view returns (uint256) {
        return _minerDamageBasisPoints;
    }

    function __tokenContract()
    public view returns (DaxToken) {
        return _tokenContract;
    }

    function __unimprovedMinerPenalty()
    public view returns (uint256) {
        return _unimprovedMinerPenalty;
    }

    function __setCoinContract(DaxCoin coinContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        address currentContract = address(_coinContract);
        _revokeRole(MINER_EXTRACT_ROLE, currentContract);
        _revokeRole(MINER_IMPROVE_ROLE, currentContract);
        _revokeRole(MINER_MINE_ROLE, currentContract);

        address newContract = address(coinContract);
        _grantRole(MINER_EXTRACT_ROLE, newContract);
        _grantRole(MINER_IMPROVE_ROLE, newContract);
        _grantRole(MINER_MINE_ROLE, newContract);

        _coinContract = coinContract;
    }

    function __setEfficiencyBase(uint256 base)
    public onlyRole(MINING_ADMIN_ROLE) {
        _efficiencyBase = base;
    }

    function __setMapContract(DaxMap mapContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _mapContract = mapContract;
    }

    function __setMinerDamageBasisPoints(uint256 points)
    public onlyRole(MINING_DAMAGE_ROLE) {
        _minerDamageBasisPoints = points;
    }

    function __setMiningFactor(uint256 factor_, uint256 x, uint256 y, uint256 z)
    public onlyRole(MINING_FACTOR_ROLE) {
        _miningFactors[x][y][z] = factor_;
    }

    function __setTokenContract(DaxToken tokenContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _tokenContract = tokenContract;
    }

    function __setUnimprovedMinerPenalty(uint256 penalty)
    public onlyRole(MINING_ADMIN_ROLE) {
        _unimprovedMinerPenalty = penalty;
    }

    function _authorizeUpgrade(address newImplementation)
    internal override onlyRole(UPGRADER_ROLE) {}

    function _improve(uint256 miner, uint256 amount)
    private {
        if (mining(miner)) {
            _minerImprovementsPending[miner] += amount;
        } else {
            _minerImprovements[miner] += amount;
        }

        emit Improvement(miner, amount);
    }

    function _mine(uint256 miner)
    private
    returns (uint256) {
        (uint256 x, uint256 y, uint256 z) = _mapContract.current(miner);
        bool available = _miningClaims[x][y][z] == 0 || _miningClaims[x][y][z] == miner;

        if (!available || _mapContract.inMotion(miner)) {
            return 0;
        }

        _mapContract.initialize(miner);
        if (!mining(miner)) {
            _miners[x][y][z] = miner;
            _minerMovements[x][y][z] = _mapContract.moveTime(miner);
            _miningStarts[x][y][z] = block.number;
            _miningClaims[x][y][z] = miner;
            
            emit Mine(miner, x, y, z, 0);
            return 0;
        } else {
            uint256 amount = mined(miner);
            uint256 damage = _minerImprovements[miner].mul(_minerDamageBasisPoints).div(10000); 

            _miningStarts[x][y][z] = block.number;
            _minerImprovements[miner] += _minerImprovementsPending[miner];
            _minerImprovements[miner] -= damage;
            _minerImprovementsPending[miner] = 0;
            _miningTotals[miner] += amount;

            emit Mine(miner, x, y, z, amount);
            return amount;
        }
    }

    function _requireMineable(uint256 miner)
    private view {
        require(_mapContract.isApprovedOrOwner(_msgSender(), miner), "DaxMining: caller not approved");
        require(!_mapContract.inMotion(miner), "DaxMining: miner in motion");

        (uint256 x, uint256 y, uint256 z) = _mapContract.current(miner);

        bool available = _miningClaims[x][y][z] == 0 || _miningClaims[x][y][z] == miner;
        require(available, "DaxMining: mining location unavailable");

        bool abandonned = _minerMovements[x][y][z] == _mapContract.moveTime(miner);
        require(abandonned, "DaxMining: miner abandonned claim");
    }
}
