// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

/* 
    Author: chosta.eth (@chosta_eth)
 */
/* 
    HOW IT WORKS: 
    + a snapshot of NFT holders is created (at any given time, for any erc721 or erc1155 collection)
    + the snapshot takes the wallets and amounts of NFTs for each holder from the collection at a given time
    + a hash proof is generated for the corresponding vault, which enables the wallet owners to claim their FNDR tokens when the vault opens (the key to open the vault is the wallet.
    + once the vault is "opened," a holder that is a part of the corresponding snapshot will be eligible to claim
    + once claimed, the holder will be able to claim again the next time the vault reopens (but they also need to be a part of the following snapshot)
    + once the vault expires, a restart can be made at any time (preferably asap). The root hash is updated to serve the new snapshot
    + The claimable is calculated based on the following formula. AMOUNT NFTS x DAILY YIELD RATE x DAYS THE VAULT IS OPEN. Claimable only works for wallets that are eligible for the corresponding snapshot.

    WHY DO WE NEED IT:
    + we want to be able to add any project to be able to generate the $FNDR token - including erc1155 collections and collections with a high amount of staked tokens.
    + we want to reduce the price for claiming, as our current claiming solution can be costly for owners of multiple NFTs. In the case of vaults, the gas cost does not scale with the amount of NFTs.
    + we want to enable cross-chain FNDR generation - snapshots can be made in any L1 or L2 in existence
 */

interface IERC20 {
    function mint(address user, uint256 amount) external;
}

contract FFVaultGenerator is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct FFVault {
        address addr;
        bytes32 currentHash; // has to be refreshed for every new claimable period
        string name; // project name
        uint256 start; // timestamp to start claimable period
        uint256 end; // timestamp stop claimable period
        uint256 yieldRate; // 1 to 10000 rate as per the whitepaper (used to control token generation amounts)
        bool active; // for frontend help only - NOT USED FOR INTERNAL LOGIC
        string projectUrl; // opensea / looksrare (or any other) external url
        string placeholderUrl; // any image describing the project
    }

    /* #TODO -> DRY (used in FFGenerator) */
    struct FFRate {
        address addr;
        uint256 yieldRate;
    }

    IERC20 public token;
    address[] public vaultAddresses; // keep track of all addresses (frontend help)
    mapping(address => FFVault) public vaults;
    mapping(address => mapping(address => uint256)) public claims; // mark claimed

    event VaultClaimed(address indexed user_, uint256 amount_);
    event VaultAdded(address indexed user_, FFVault FFVault_);
    event VaultEdited(address indexed user_, FFVault FFVault_);
    event VaultDeactivated(address indexed user_, FFVault FFVault_);
    event HashUpdated(
        address indexed user_,
        bytes32 currentHash_,
        bytes32 newHash_
    );
    event VaultInitiated(
        address indexed user_,
        uint256 start_,
        uint256 endd_,
        bytes32 currentHash_
    );
    event VaultRatesUpdated(address indexed user_, FFRate[] rates_);

    // role used to enable non-admins to change the rates
    bytes32 public constant RATOOOOR = keccak256("RATOOOOR");
    // avoid misclicks and breaking the economy by setting a limit
    uint16 public constant MAX_YIELD = 10000;

    constructor(address token_) {
        token = IERC20(token_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RATOOOOR, msg.sender);
    }

    function claimSingle(
        address vault_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external whenNotPaused nonReentrant {
        uint256 _totalClaim;
        uint256 _start = vaults[vault_].start;
        uint256 _end = vaults[vault_].end;

        require(block.timestamp < _end, "claim finished");
        require(block.timestamp > _start, "claim not started");
        require(!(isClaimed(vault_, msg.sender)), "already claimed");
        require(
            isValidClaim(vault_, amount_, merkleProof_) == true,
            "invalid proof"
        );

        _totalClaim = _totalClaim.add(pendingYield(vault_, amount_));

        require(_totalClaim > 0, "No claimable yield");

        claims[vault_][msg.sender] = block.timestamp;
        token.mint(msg.sender, _totalClaim);

        emit VaultClaimed(msg.sender, _totalClaim);
    }

    function isValidClaim(
        address vault_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        bytes32 _rootHash = vaults[vault_].currentHash;
        bytes32 _keca = keccak256(abi.encodePacked(msg.sender, amount_));
        return MerkleProof.verify(merkleProof_, _rootHash, _keca);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addVault(address vault_, FFVault memory FFVault_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(FFVault_.name).length > 0, "name missing");
        require(address(FFVault_.addr) == vault_, "contract address mismatch");
        require(uint256(FFVault_.yieldRate) > 0, "yieldRate must be > 0");
        require(
            uint256(FFVault_.yieldRate) <= MAX_YIELD,
            "can't exceed max yield"
        );

        FFVault_.start = 0;
        FFVault_.end = 0;

        vaults[vault_] = FFVault_;
        vaultAddresses.push(vault_);

        emit VaultAdded(msg.sender, FFVault_);
    }

    function updateVault(address vault_, FFVault memory FFVault_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            bytes(vaults[FFVault_.addr].name).length > 0,
            "vault doesnt exist"
        );
        require(bytes(FFVault_.name).length > 0, "name missing");
        require(address(FFVault_.addr) == vault_, "contract address mismatch");
        require(uint256(FFVault_.yieldRate) > 0, "yieldRate must be > 0");
        require(
            uint256(FFVault_.yieldRate) <= MAX_YIELD,
            "can't exceed max yield"
        );

        FFVault memory _FFVault;

        _FFVault.name = FFVault_.name;
        _FFVault.addr = FFVault_.addr;
        _FFVault.start = FFVault_.start;
        _FFVault.end = FFVault_.end;
        _FFVault.currentHash = FFVault_.currentHash;
        _FFVault.yieldRate = FFVault_.yieldRate;
        _FFVault.active = FFVault_.active;
        _FFVault.projectUrl = FFVault_.projectUrl;
        _FFVault.placeholderUrl = FFVault_.placeholderUrl;

        vaults[FFVault_.addr] = _FFVault;

        emit VaultEdited(msg.sender, FFVault_);
    }

    function deactivateVault(address vault_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(vaults[vault_].name).length > 0, "vault doesnt exist");

        vaults[vault_].active = false;

        emit VaultDeactivated(msg.sender, vaults[vault_]);
    }

    function updateHash(address vault_, bytes32 newHash_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(vaults[vault_].name).length > 0, "vault doesnt exist");
        require(
            keccak256(abi.encodePacked(vaults[vault_].currentHash)) !=
                keccak256(abi.encodePacked(newHash_)),
            "new hash must be != old"
        );

        vaults[vault_].currentHash = newHash_;

        emit HashUpdated(msg.sender, vaults[vault_].currentHash, newHash_);
    }

    function initiateVault(
        address vault_,
        uint256 start_,
        uint256 end_,
        bytes32 currentHash_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(vaults[vault_].name).length > 0, "vault doesnt exist");

        uint256 _start = vaults[vault_].start;
        uint256 _end = vaults[vault_].end;

        require(_start < start_, "old start must be < new");
        require(_end < end_, "old end must be < old");
        require(
            block.timestamp < start_ && end_ > start_,
            "invalid period dates"
        );

        vaults[vault_].start = start_;
        vaults[vault_].end = end_;
        vaults[vault_].currentHash = currentHash_;

        emit VaultInitiated(msg.sender, start_, end_, currentHash_);
    }

    function updateRates(FFRate[] calldata rates_) external onlyRole(RATOOOOR) {
        for (uint256 i = 0; i < rates_.length; i++) {
            uint256 rate = rates_[i].yieldRate;
            require(rate > 0, "yieldRate must be > 0");
            require(rate <= MAX_YIELD, "can't exceed max yield");

            vaults[rates_[i].addr].yieldRate = rates_[i].yieldRate;
        }
        emit VaultRatesUpdated(msg.sender, rates_);
    }

    function EMERGENCY_updateClaims(
        address vault_,
        address claimer_,
        uint256 timestamp_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claims[vault_][claimer_] = timestamp_;
    }

    function viewVaults(address[] calldata vaults_)
        external
        view
        returns (FFVault[] memory)
    {
        FFVault[] memory _result = new FFVault[](vaults_.length);

        for (uint256 i = 0; i < vaults_.length; i++) {
            FFVault memory _vault = vaults[vaults_[i]];
            _result[i] = _vault;
        }

        return _result;
    }

    function viewAllVaults() external view returns (FFVault[] memory) {
        FFVault[] memory _result = new FFVault[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FFVault memory _vault = vaults[vaultAddresses[i]];
            _result[i] = _vault;
        }

        return _result;
    }

    function pendingYield(address vault_, uint256 amount_)
        internal
        view
        returns (uint256)
    {
        uint256 _start = vaults[vault_].start;
        uint256 _end = vaults[vault_].end;

        return
            (getYieldRate(vault_).mul(_end.sub(_start)).mul(amount_)).div(
                24 hours
            );
    }

    function claimable(
        address vault_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) public view returns (uint256 _claimable) {
        if (isValidClaim(vault_, amount_, merkleProof_) == false) {
            _claimable = 0;
        } else {
            _claimable = pendingYield(vault_, amount_);
        }
    }

    function isClaimed(address vault_, address claimer_)
        public
        view
        returns (bool _claimed)
    {
        uint256 _start = vaults[vault_].start;
        uint256 _end = vaults[vault_].end;

        _claimed =
            claims[vault_][claimer_] > _start &&
            claims[vault_][claimer_] < _end;
    }

    function getYieldRate(address vault_) public view returns (uint256) {
        // the rate is in decimals but should represent a floating number with precision of two
        // therefore we multiply the rate by 10^16 instead of 10^18
        return vaults[vault_].yieldRate.mul(1e16);
    }
}
