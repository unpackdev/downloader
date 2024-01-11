// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IGovernance.sol";
import "./IDistributor.sol";
import "./LibGovernance.sol";
import "./LibTransfer.sol";


contract OscilloToken is IGovernance, OwnableUpgradeable, ERC20Upgradeable {
    using LibGovernance for LibGovernance.MintExecution;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0xd8847acffb1e80c967781c9cefc950c79c285c67014ab8ca7bfb053adcb94e20;

    uint public constant TREASURY_CAPACITY = 18000e21;
    uint public constant SHARE_RATIO = 1765;

    uint public constant DIST_CAPACITY = 102000e21;
    uint public constant DIST_SPEED = 1275e21;
    uint public constant DIST_INTERVAL_MIN = 160 hours;

    bytes32 private _domainSeparator;
    mapping(address => bool) private _whitelist;

    mapping(uint => uint) private _accVolumes;
    mapping(address => LibGovernance.AccountCursor) private _cursors;

    uint public accBooked;
    uint public accMinted;
    address public distributor;

    uint public lastCheckpoint;
    uint public lastCheckpointTime;

    event Minted(address indexed account, uint amount);
    event AccVolumeUpdated(uint indexed checkpoint, uint accVolume);

    modifier onlyWhitelisted {
        require(msg.sender != address(0) && _whitelist[msg.sender], "!whitelist");
        _;
    }

    /** Initialize **/

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init("Oscillo Token", "OSC");

        require(_domainSeparator == 0);
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));
    }

    /** Views **/

    function cursorOf(address account) public view returns (LibGovernance.AccountCursor memory) {
        return _cursors[account];
    }

    function accVolumeOf(uint checkpoint) public view returns (uint) {
        return _accVolumes[checkpoint];
    }

    function calculate(LibGovernance.MintExecution[] calldata chunk, address account) public view returns (uint amount) {
        LibGovernance.AccountCursor memory cursor = _cursors[account];
        for (uint i = 0; i < chunk.length; i++) {
            LibGovernance.MintExecution memory e = chunk[i];
            if (e.recover(_domainSeparator) != owner() || e.p.account != account) continue;

            if (e.p.checkpoint <= cursor.checkpoint) continue;
            if (e.p.volume > _accVolumes[e.p.checkpoint]) continue;
            if (e.p.nonce != cursor.nonce + 1) continue;

            cursor.checkpoint = e.p.checkpoint;
            cursor.nonce = e.p.nonce++;
            amount += e.p.volume * DIST_SPEED / _accVolumes[e.p.checkpoint];
        }
        amount = amount - (amount * SHARE_RATIO / 10000);
    }

    /** Interactions **/

    function mint(LibGovernance.MintExecution[] calldata chunk, bool stake) external {
        uint amount;

        LibGovernance.AccountCursor storage cursor = _cursors[msg.sender];
        for (uint i = 0; i < chunk.length; i++) {
            LibGovernance.MintExecution memory e = chunk[i];
            require(e.recover(_domainSeparator) == owner() && e.p.account == msg.sender, "!sig");

            require(e.p.checkpoint > cursor.checkpoint, "!checkpoint");
            require(e.p.volume <= _accVolumes[e.p.checkpoint], "!volume");
            require(e.p.nonce == cursor.nonce + 1, "!nonce");

            cursor.checkpoint = e.p.checkpoint;
            cursor.nonce = e.p.nonce++;
            amount += e.p.volume * DIST_SPEED / _accVolumes[e.p.checkpoint];
        }
        require(amount > 0 && accMinted + amount <= DIST_CAPACITY, "!capacity");
        accMinted += amount;

        uint shared = amount * SHARE_RATIO / 10000;
        _transferOut(owner(), shared, true);
        _transferOut(msg.sender, amount - shared, stake);
        emit Minted(msg.sender, amount - shared);
    }

    /** Restricted **/

    function setWhitelist(address target, bool on) external onlyOwner {
        require(target != address(0), "!target");
        _whitelist[target] = on;
    }

    function notifyAccVolumeUpdated(uint checkpoint, uint accVolume) external override onlyWhitelisted {
        require(_accVolumes[checkpoint] == 0 && checkpoint <= block.number, "!checkpoint.block");
        require(block.timestamp >= lastCheckpointTime + DIST_INTERVAL_MIN, "!checkpoint.time");
        require(accBooked + DIST_SPEED <= DIST_CAPACITY, "!capacity");

        accBooked += DIST_SPEED;
        _accVolumes[checkpoint] = accVolume;
        lastCheckpoint = checkpoint;
        lastCheckpointTime = block.timestamp;
        emit AccVolumeUpdated(checkpoint, accVolume);
    }

    function setDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(0) && newDistributor != distributor, "!distributor");
        distributor = newDistributor;
    }

    /** Privates **/

    function _transferOut(address account, uint amount, bool stake) private {
        if (distributor != address(0) && stake) {
            _mint(distributor, amount);
            IDistributor(distributor).stakeBehalf(account, amount);
        } else {
            _mint(account, amount);
        }
    }
}
