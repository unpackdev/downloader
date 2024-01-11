//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./SanctionsList.sol";
import "./Multicall.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";

// solhint-disable not-rely-on-time
contract Airdrop is Initializable, AccessControlUpgradeable, EIP712Upgradeable, UUPSUpgradeable, PausableUpgradeable, Multicall {
    bytes32 public constant AIRDROP_MANAGER_ROLE = keccak256("AIRDROP_MANAGER_ROLE");
    bytes32 public constant EXTERNAL_VERIFIER_ROLE = keccak256("EXTERNAL_VERIFIER_ROLE");
    bytes32 public constant ADDITIONAL_CLAIM_MANAGER_ROLE = keccak256("ADDITIONAL_CLAIM_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct ExternalClaim {
        address from;
        address to;
        uint8 tier;
        bytes32 nonce;
        uint256 deadline;
    }

    struct ExternalTier {
        uint256 amount;
        uint256 slots;
    }

    bytes32 private constant _EXTERNALCLAIM_TYPEHASH =
        keccak256("ExternalClaim(address from,address to,uint8 tier,bytes32 nonce,uint256 deadline)");
    uint256 private constant MIN_DURATION = 90 days;

    bytes32 public merkleRoot;
    uint256 public startTime;
    uint256 public endTime;
    IERC20Upgradeable public token;
    address public treasury;
    SanctionsList public sanctionsList;

    // Merkle tree claims are represented by packed array of booleans in a uint256 to save gas.
    mapping(uint256 => uint256) private claimedBitMap;
    ExternalTier[] public tierAllocations;
    mapping(bytes32 => address) public claimedNonces;
    mapping(address => uint256) public additionalClaims;
    mapping(address => bool) public denyList;

    event ExternalAllocationsReduced(uint8 indexed tier, uint256 slots);
    event NonceConsumed(bytes32 indexed nonce, address indexed recipient);
    event TokensReleased(address indexed recipient, uint256 amount);
    event TokensReclaimed(address indexed treasury, uint256 amount);
    event AdditionalClaimModified(address indexed claimer, uint256 newClaim);
    event AddressBlockChanged(address indexed claimer, bool blocked);
    event TreasurySet(address indexed treasury);
    event SanctionsListSet(address indexed sanctionsList);

    modifier whenAirdropActive() {
        require(block.timestamp <= endTime && block.timestamp > startTime, "Airdrop is over or not started");
        _;
    }

    modifier whenAirdropOver() {
        require(block.timestamp > endTime, "Airdrop not over yet");
        _;
    }

    modifier ifAddressNotSanctioned(address _claimer) {
        require(!sanctionsList.isSanctioned(_claimer), "Claimer in sanctions list");
        _;
    }

    modifier ifAddressNotBlocked(address _claimer) {
        require(!denyList[_claimer], "Claimer blocked");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        IERC20Upgradeable _token,
        bytes32 _merkleRoot,
        address _treasury,
        uint256 _startTime,
        uint256 _endTime,
        ExternalTier[] calldata _externalAllocations,
        address _sanctionsList
    ) external initializer  {
        require(address(_token) != address(0), "Token must be non zero address");
        require(_admin != address(0), "Admin must be non zero address");
        require(_merkleRoot != "", "Empty MerkleRoot");
        require(_treasury != address(0), "Treasury must be non zero address");
        require(_startTime > 0, "Start date not set");
        require(_endTime > _startTime, "End date before start date");
        if (block.chainid == 1) {
            require(_endTime - _startTime>= MIN_DURATION, "Airdrop too short");
        }
        __AccessControl_init();
        __EIP712_init("Airdrop", "1");
        __UUPSUpgradeable_init();
        __Pausable_init();

        token = _token;
        merkleRoot = _merkleRoot;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(AIRDROP_MANAGER_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        // EXTERNAL_VERIFIER_ROLE should not be _admin
        // ADDITIONAL_CLAIM_MANAGER_ROLE starts unset

        treasury = _treasury;
        startTime = _startTime;
        endTime = _endTime;
        for (uint256 i = 0; i < _externalAllocations.length; i++) {
            tierAllocations.push(_externalAllocations[i]);
        }

        _setSanctionsList(_sanctionsList);
    }

    /**
     * @notice Distributes tokens to addresses that are included in the MerkleTree corresponding to the merkleRoot set when initializing.
     * @param _index in the merkle tree
     * @param _proof merkle proof of the merkle leaf
     */
    function claim(uint256 _index, uint256 _amount, bytes32[] calldata _proof)
        external
        whenAirdropActive
        whenNotPaused
        ifAddressNotBlocked(msg.sender)
        ifAddressNotSanctioned(msg.sender) {
        
        require(!isClaimed(_index), "Already claimed");
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _amount));
        require(
            MerkleProofUpgradeable.verify(_proof, merkleRoot, node),
            "Account not on the list"
        );
        _claim(_index, msg.sender, _amount);
    }

    /**
     * @notice Distributes tokens to the address indicated in a ExternalClaim, signed by EXTERNAL_VERIFIER_ROLE, in accordance to tierAllocations amount and availability.
     * @param _claim ExternalClaim(address from,address to,uint8 tier,bytes32 nonce,uint256 deadline)
     * @param _signature EIP712 typed signature
     */
    function externalClaim(ExternalClaim calldata _claim, bytes calldata _signature)
        external
        whenAirdropActive
        whenNotPaused
        ifAddressNotBlocked(_claim.to)
        ifAddressNotSanctioned(_claim.to) {
            
        require(!isExternallyClaimed(_claim.nonce), "Nonce already claimed");
        require(hasRole(EXTERNAL_VERIFIER_ROLE, _claim.from), "Claim not issued by verifier");
        require(block.timestamp <= _claim.deadline, "Claim expired");
        require(msg.sender == _claim.to, "Claim.to must be sender");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                _claim.from,
                _hashTypedDataV4(keccak256(abi.encode(_EXTERNALCLAIM_TYPEHASH, _claim.from, _claim.to, _claim.tier, _claim.nonce, _claim.deadline))),
                _signature
            ),
            "Signature does not match"
        );
        _claimExternal(_claim);
    }

    /**
     * @notice Sender can claim tokens allocated exceptionally after deployment
     */
    function claimAdditionalTokens() external whenAirdropActive whenNotPaused ifAddressNotBlocked(msg.sender) ifAddressNotSanctioned(msg.sender) {
        require(additionalClaims[msg.sender] > 0, "No claim for sender");
        uint256 amount = additionalClaims[msg.sender];
        additionalClaims[msg.sender] = 0;
        SafeERC20Upgradeable.safeTransfer(token, msg.sender, amount);
        emit TokensReleased(msg.sender, amount);
    }

    /**
     * @notice Increases the token claim for the claimer address, if sender is ADDITIONAL_CLAIM_MANAGER_ROLE and claimer is not blocked.
     * It will transfer _amount tokens from the sender to the contract
     * @param _claimer the claimer address
     * @param _amount of tokens to be added to the claim
     */
    function increaseAdditionalClaim(address _claimer, uint256 _amount) external onlyRole(ADDITIONAL_CLAIM_MANAGER_ROLE) ifAddressNotBlocked(_claimer) ifAddressNotSanctioned(_claimer) {
        require(_claimer != address(0), "Claimer cannot be address(0)");
        SafeERC20Upgradeable.safeTransferFrom(token, msg.sender, address(this), _amount);
        additionalClaims[_claimer] = additionalClaims[_claimer] + _amount;
        emit AdditionalClaimModified(_claimer, additionalClaims[_claimer]);
    }

    /**
     * @notice Decreases the token claim amount for the claimer address, if sender is ADDITIONAL_CLAIM_MANAGER_ROLE and claimer is not blocked.
     * Will send the excess tokens to the sender.
     * @param _claimer the claimer address,
     * @param _amount of tokens to be decreased from the claim. If _amount > stored claim, new claim will be 0.
     */
    function decreaseAdditionalClaim(address _claimer, uint256 _amount) external onlyRole(ADDITIONAL_CLAIM_MANAGER_ROLE) {
        require(_claimer != address(0), "Claimer cannot be address(0)");
        uint256 subtractedAmount = MathUpgradeable.min(_amount, additionalClaims[_claimer]);
        additionalClaims[_claimer] = additionalClaims[_claimer] - subtractedAmount;
        SafeERC20Upgradeable.safeTransfer(token, msg.sender, subtractedAmount);
        emit AdditionalClaimModified(_claimer, additionalClaims[_claimer]);
    }

    /**
     * @notice Pauses the token distribution.
     * Emergency method, it won't affect distribution duration.
     * Only callable by PAUSER_ROLE
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the token distribution.
     * Emergency method, it won't affect distribution duration.
     * Only callable by PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Sets a new treasury address, where unclaimed tokens go after airdrop end.
     * Only callable by AIRDROP_MANAGER_ROLE
     * @param _treasury address;
     */
    function setTreasury(address _treasury) external onlyRole(AIRDROP_MANAGER_ROLE) {
        require(_treasury != address(0), "Treasury must be non zero address");
        treasury = _treasury;
        emit TreasurySet(treasury);
    }

    /**
     * @notice Adds or removes address on denyList. Addresses on denyList can't claim or get tokens distributed to them.
     * @param _claimer address blocked or unblocked
     * @param _blocked true if adding to denyList, false if removing from it
     */
    function setAddressStatus(address _claimer, bool _blocked) external onlyRole(AIRDROP_MANAGER_ROLE) {
        require(_claimer != address(0), "Blocked must be non zero address");
        denyList[_claimer] = _blocked;
        emit AddressBlockChanged(_claimer, _blocked);
    }

    /**
     * @notice Sends unclaimed tokens to treasury when airdrop is over.
     * Only callable by AIRDROP_MANAGER_ROLE
     */
    function recoverTokens() external whenAirdropOver onlyRole(AIRDROP_MANAGER_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        SafeERC20Upgradeable.safeTransfer(token, treasury, balance);
        emit TokensReclaimed(treasury, balance);
    }

    /**
     * @notice Sets the address of the sanction list contract.
     * Only callable by AIRDROP_MANAGER_ROLE
     * @param _list address of the Chainalysis contract.
     */
    function setSanctionsList(address _list) external onlyRole(AIRDROP_MANAGER_ROLE) {
        _setSanctionsList(_list);
    }

    /**
     * @notice Checks if tokens already sent to leaf of the Merkle tree
     * @param _index the merkleTree index of the leaf
     */
    function isClaimed(uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice Checks if tokens already sent to a claimer added by the VERIFIER_ROLE
     * @param _nonce the external ID with a token allocation
     */
    function isExternallyClaimed(bytes32 _nonce) public view returns (bool) {
        return claimedNonces[_nonce] != address(0);
    }

    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
        // solhint-disable-next-line no-empty-blocks
    { }

    function _setClaimed(uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _claim(uint256 _index, address _account, uint256 _amount) private {
        _setClaimed(_index);
        SafeERC20Upgradeable.safeTransfer(token, _account, _amount);
        emit TokensReleased(_account, _amount);
    }  

    function _claimExternal(ExternalClaim calldata _claim) private {
        claimedNonces[_claim.nonce] = _claim.to;
        emit NonceConsumed(_claim.nonce, _claim.to);
        require(tierAllocations[_claim.tier].slots >= 1, "Tier fully allocated");
        tierAllocations[_claim.tier].slots -= 1;
        emit ExternalAllocationsReduced(_claim.tier, tierAllocations[_claim.tier].slots);
        SafeERC20Upgradeable.safeTransfer(token, _claim.to, tierAllocations[_claim.tier].amount);
        emit TokensReleased(_claim.to, tierAllocations[_claim.tier].amount);
    }

    function _setSanctionsList(address _list) private {
        require(_list != address(0), "_list cannot be zero address");
        sanctionsList = SanctionsList(_list);
        emit SanctionsListSet(_list);
    }

}