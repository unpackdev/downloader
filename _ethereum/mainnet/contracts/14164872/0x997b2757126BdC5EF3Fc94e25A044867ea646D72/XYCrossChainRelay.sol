// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "AccessControlUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "PausableUpgradeable.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import "ECDSA.sol";
import { Address } from "Address.sol";
import { Supervisor } from "Supervisor.sol";
import { IXYToken } from "IXYToken.sol";

/// @title XYCrossChainRelay relays XY token across different chains.
contract XYCrossChainRelay is AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IXYToken;
    using SafeERC20 for IERC20;

    /* ========== STRUCTURE ========== */

    // request to move XY cross chain
    struct CrossChainRequest {
        // chain Id of the destination chainin the cross chain relay
        uint32 destChainId;
        // user who initiate the cross chain request on the source chain
        address sender;
        // user who will receive the XY token on the destination chain
        address receiver;
        uint256 amount;
    }

    /* ========== CONSTANTS ========== */

    uint32 internal constant ETH_CHAIN_ID = 1;

    // Roles in this contract
    // Owner: able to upgrade contract
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    // Manager: able to pause/unpause contract
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    // Staff: able to relay cross chain requests
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");

    /* ========== STATE VARIABLES ========== */

    uint32 thisChainId;
    // Treasury where cross chain fees are sent to
    address public treasury;
    address public pendingTreasury;
    // A contract that supervises each XY token cross chain relay by providing signatures
    Supervisor public supervisor;
    // XY token address
    IXYToken public xyToken;

    // Max amount of XY token allowed in each cross chain request
    uint256 public maxCrossChainAmount;

    // Number of the cross chain requests
    uint256 public numCrossChainRequests;
    // Mapping of completed cross chain requests: source chain id => request id => request
    mapping (uint32 => mapping (uint256 => bool)) public completedCrossChainRequest;

    /* ========== CONSTRUCTOR ========== */

    /// @param chainId The ID of this chain, passed in as param for easier configuration for testing
    /// @param _treasury The Treasury address
    /// @param _supervisor The Supervisor address
    /// @param owner The owner address
    /// @param manager The manager address
    /// @param staff The staff address
    /// @param _xyToken The XY token address
    /// @param _maxCrossChainAmount Max cross chain amount
    function initialize(uint32 chainId, address _treasury, address _supervisor, address owner, address manager, address staff, address _xyToken, uint256 _maxCrossChainAmount) initializer public {
        require(Address.isContract(_supervisor), "ERR_SUPERVISOR_NOT_CONTRACT");
        supervisor = Supervisor(_supervisor);
        require(Address.isContract(_xyToken), "ERR_XY_WRPAPPED_TOKEN_NOT_CONTRACT");
        xyToken = IXYToken(_xyToken);

        thisChainId = chainId;
        treasury = _treasury;
        maxCrossChainAmount = _maxCrossChainAmount;

        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_OWNER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
        _setupRole(ROLE_STAFF, staff);
    }

    /* ========== MODIFIERS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Transfer XY token from user, additionally burn the token if this chain is not ETH chain
    function _lockXYToken(address sender, uint256 amount) internal {
        xyToken.safeTransferFrom(sender, address(this), amount);
        if (thisChainId != ETH_CHAIN_ID) {
            xyToken.burn(amount);
        }
    }

    /// @notice Transfer XY token to user if this chain is ETH chain otherwise mint the token to user
    function _releaseXYToken(address receiver, uint256 amount, uint256 fee) internal {
        if (thisChainId == ETH_CHAIN_ID) {
            xyToken.safeTransfer(receiver, amount);
            xyToken.safeTransfer(treasury, fee);
        } else {
            xyToken.mint(receiver, amount);
            xyToken.mint(treasury, fee);
        }
    }

    /* ========== RESTRICTED FUNCTIONS (TREASURY) ========== */

    function proposeNewTreasury(address newTreasury) external {
        require(msg.sender == treasury, "ERR_NOT_TREASURY");
        pendingTreasury = newTreasury;
        emit NewTreasuryProposed(newTreasury);
    }

    function acceptNewTreasury() external {
        require(msg.sender == pendingTreasury, "ERR_NOT_PENDING_TREASURY");
        pendingTreasury = address(0);
        treasury = msg.sender;
        emit NewTreasuryAccepted(msg.sender);
    }

    /* ========== RESTRICTED FUNCTIONS (OWNER) ========== */

    function _authorizeUpgrade(address) internal override onlyRole(ROLE_OWNER) {}

    /// @notice Rescue fund accidentally sent to this contract. Can not rescue XY token
    /// @param tokens List of token address to rescue
    function rescue(IERC20[] memory tokens) external onlyRole(ROLE_OWNER) {
        for (uint256 i; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            require(address(token) != address(xyToken), "ERR_CAN_NOT_RESCUE_XY_TOKEN");
            uint256 _tokenBalance = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, _tokenBalance);
        }
    }

    /* ========== RESTRICTED FUNCTIONS (MANAGER) ========== */

    /// @notice Pause the contract (could be executed only by manager)
    function pause() external onlyRole(ROLE_MANAGER) {
        _pause();
    }

    /// @notice Unpause the contract (could be executed only by manager)
    function unpause() external onlyRole(ROLE_MANAGER) {
        _unpause();
    }

    /// @notice Set max cross chain amount (could be executed only by manager)
    /// @param newMaxCrossChainAmount New max cross chain amount
    function setMaxCrossChainAmount(uint256 newMaxCrossChainAmount) external onlyRole(ROLE_MANAGER) {
        maxCrossChainAmount = newMaxCrossChainAmount;
    }

    /* ========== RESTRICTED FUNCTIONS (STAFF) ========== */

    /// @notice Complete a cross chain request
    /// @param requestId ID of the cross chain request on the source chain
    /// @param sourceChainId Chain Id of the source chain
    /// @param receiver Receiver of the XY token
    /// @param amount Amount of XY token
    /// @param fee Fee amount (denominated in XY token)
    /// @param signatures Signatures of validators
    function completeCrossChainRequest(uint256 requestId, uint32 sourceChainId, address receiver, uint256 amount, uint256 fee, bytes[] memory signatures) external whenNotPaused onlyRole(ROLE_STAFF) {
        require(!completedCrossChainRequest[sourceChainId][requestId], "ERR_CROSS_CHAIN_REQUEST_ALREADY_COMPLETE");
        require(amount > fee, "ERR_FEE_GREATER_THAN_AMOUNT");
        require(amount <= maxCrossChainAmount, "ERR_INVALID_CROSS_CHAIN_AMOUNT");

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.VALIDATE_XY_CROSS_CHAIN_IDENTIFIER(), address(this), sourceChainId, thisChainId, requestId, receiver, amount, fee));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);
        uint256 amountSubFee = amount - fee;

        completedCrossChainRequest[sourceChainId][requestId] = true;
        emit CrossChainCompleted(requestId, sourceChainId, thisChainId, receiver, amount, fee);
        _releaseXYToken(receiver, amountSubFee, fee);
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice Request to send XY token cross chain
    /// @param destChainId Chain Id of the destination chain
    /// @param receiver Receiver of the XY token on destination chain
    /// @param amount Amount of XY token to send cross chain
    function requestCrossChain(uint32 destChainId, address receiver, uint256 amount) external whenNotPaused {
        require(amount > 0 && amount <= maxCrossChainAmount, "ERR_INVALID_CROSS_CHAIN_AMOUNT");

        uint256 id = numCrossChainRequests++;
        _lockXYToken(msg.sender, amount);

        emit CrossChainRequested(id, thisChainId, destChainId, msg.sender, receiver, amount);
    }

    /* ========== EVENTS ========== */

    event NewTreasuryProposed(address newTreasury);
    event NewTreasuryAccepted(address newTreasury);
    event CrossChainRequested(uint256 indexed requestId, uint32 sourceChainId, uint32 indexed destChainId, address indexed sender, address receiver, uint256 amount);
    event CrossChainCompleted(uint256 indexed requestId, uint32 indexed sourceChainId, uint32 destChainId, address indexed receiver, uint256 amount, uint256 fee);
}
