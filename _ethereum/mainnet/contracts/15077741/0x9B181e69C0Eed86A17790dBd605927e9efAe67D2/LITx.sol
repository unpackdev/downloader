// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BannedUpgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract LITxToken is
    OwnableUpgradeable,
    BannedUpgradeable,
    ERC20PermitUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string private constant NAME = "LITx Token";
    string private constant SYMBOL = "LITx";
    uint256 private constant PPM = 100;
    uint256 private constant TOTAL_SUPPLY = 5_417_770_823e18;
    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /**
     * @dev Emitted when Fee Distributor address set.
     */
    event FeeDistributorSet(address indexed who, address to);
    /**
     * @dev Emitted when Chain enabled/disabled.
     */
    event ChainSet(address indexed who, uint256 chain, bool enable);
    /*
     * @dev Burn the token on target chain
     */
    event BridgeGotOn(
        address indexed sender,
        uint256 amount,
        uint256 indexed targetChain,
        uint256 indexed tx
    );
    /*
     * @dev Mint the token on target chain
     */
    event BridgeGotOff(
        address indexed beneficiary,
        uint256 amount,
        uint256 indexed originChain,
        uint256 indexed tx
    );
    /**
     * @dev Emitted when `amount` tokens are moved from the contract to (`to`).
     */
    event Migrated(address indexed to, uint256 amount);
    /**
     * @dev Emitted when migration finalised andv`amount` tokens are moved from the contract to (`to`) - ecosystem.
     */
    event Finalized(address to, uint256 amount);

    address public bridge;
    address public ecosystem;
    IERC20Upgradeable public migrateToken;
    address public feeDistributor;
    uint256 public migrateBy;

    mapping(uint256 => bool) public chains;
    mapping(bytes32 => bool) public txs;

    CountersUpgradeable.Counter private _txCounter;

    /**
     * @dev Throws if called by any account other than the bridge.
     */
    modifier onlyBridge() {
        require(bridge == _msgSender(), "LITX: caller is not the bridge");
        _;
    }

    /**
     * @dev Throws if called by any account other than the bridge.
     */
    modifier canBridge(uint256 chain) {
        require(chains[chain], "LITX: bad chain");
        _;
    }

    /**
     * @dev Throws if called by any account other than the bridge.
     */
    modifier canMigrate() {
        require(block.timestamp < migrateBy, "LITX: migration finished");
        _;
    }

    /**
     * @dev See {__LITxToken_init}.
     */
    function initialize(
        address bridge_,
        address ecosystem_,
        address migrateToken_,
        uint256 migrateBy_,
        uint256[] calldata chains_
    ) external initializer {
        __LITxToken_init(
            NAME,
            SYMBOL,
            bridge_,
            ecosystem_,
            migrateToken_,
            migrateBy_,
            chains_
        );
    }

    /**
     * @dev See {__LITx_init_unchained}.
     */
    function __LITxToken_init(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address ecosystem_,
        address migrateToken_,
        uint256 migrateBy_,
        uint256[] calldata chains_
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        __ERC20Permit_init_unchained(name_);
        __LITxToken_init_unchained(
            bridge_,
            ecosystem_,
            migrateToken_,
            migrateBy_,
            chains_
        );
    }

    /**
     * @dev Set the bridge and swap token addresses.
     */
    function __LITxToken_init_unchained(
        address bridge_,
        address ecosystem_,
        address migrateToken_,
        uint256 migrateBy_,
        uint256[] calldata chains_
    ) internal onlyInitializing {
        require(
            bridge_ != address(0) &&
                ecosystem_ != address(0) &&
                migrateToken_ != address(0),
            "LITX: !zero address"
        );
        bridge = bridge_;
        ecosystem = ecosystem_;
        migrateToken = IERC20Upgradeable(migrateToken_);
        migrateBy = migrateBy_;

        if (block.timestamp < migrateBy_) {
            super._mint(address(this), TOTAL_SUPPLY);
        }

        for (uint256 i = 0; i < chains_.length; ) {
            chains[chains_[i]] = true;
            unchecked {i++;}
        }
    }

    /**
     * @dev Set Fee Distributor.
     */
    function setFeeDistributor(address feeDistributor_) external onlyOwner {
        require(feeDistributor_ != address(0), "LITX: !zero address");
        feeDistributor = feeDistributor_;
        emit FeeDistributorSet(_msgSender(), feeDistributor_);
    }

    /**
     * @dev Set./Unset chains
     */
    function setChain(uint256 chain_, bool enable_) external onlyOwner {
        require(chains[chain_] != enable_, "LITX: !same value");
        chains[chain_] = enable_;
        emit ChainSet(_msgSender(), chain_, enable_);
    }

    /**
     * @dev Go to the bridge.
     */
    function bridgeGetOn(uint256 amount, uint256 targetChain)
        external
        canBridge(targetChain)
        nonBanned(_msgSender())
    {
        uint256 tx_ = _txCounter.current();
        _txCounter.increment();
        super._burn(msg.sender, amount);
        emit BridgeGotOn(msg.sender, amount, targetChain, tx_);
    }

    /**
     * @dev Get off the bridge.
     */
    function bridgeGetOff(
        address beneficiary,
        uint256 amount,
        uint256 originChain,
        uint256 tx_
    ) external onlyBridge {
        require(beneficiary != address(0), "LITX: !zero address");
        bytes32 hash = keccak256(abi.encode(originChain, tx_));
        require(!txs[hash], "LITX: tx replay");
        txs[hash] = true;
        super._mint(beneficiary, amount);
        emit BridgeGotOff(beneficiary, amount, originChain, tx_);
    }

    /**
     * @dev Migrate LITH to LITx as 1:1.
     */
    function migrate(address _beneficiary, uint256 _amount)
        external
        canMigrate
        nonBanned(_beneficiary)
        nonBanned(_msgSender())
    {
        require(_beneficiary != address(0), "LITX: !zero address");
        require(_amount > 0, "LITX: bad input");
        require(migrateToken.transferFrom(_msgSender(), BURN_ADDRESS, _amount), "!transferFrom");
        super._transfer(address(this), _beneficiary, _amount);
        emit Migrated(_beneficiary, _amount);
    }

    /**
     * @dev Finalize a migration.
     */
    function finalize() external {
        require(block.timestamp >= migrateBy, "LITX: too early");
        uint256 toSend = balanceOf(address(this));
        super._transfer(address(this), ecosystem, toSend);
        emit Finalized(ecosystem, toSend);
    }

    /**
     * @dev Ban token transfer from caller.
     */
    function ban(address user) external onlyOwner {
        super._ban(user);
    }

    /**
     * @dev Unban token transfer from banned caller.
     */
    function unban(address user) external onlyOwner {
        super._unban(user);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override nonBanned(sender) nonBanned(recipient) {
        uint256 fee = 0;
        if (sender != feeDistributor && recipient != feeDistributor) {
            fee = amount / PPM;
            super._transfer(sender, feeDistributor, fee);
        }
        super._transfer(sender, recipient, amount - fee);
    }
}
