// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

import "./IBridge.sol";

contract Bridge is
    IBridge,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    uint256 public constant ONE_DAY_TIME = 1 days;

    /// @dev Ongoing bridge phase
    BridgePhase private BRIDGE_PHASE;

    /// @dev Bridge validator address to bridge AGOV/MPWR thru cross-chain
    address private BRIDGE_VALIDATOR;

    /// @dev Bridge signer address
    address private BRIDGE_SIGNER;

    /// @dev Bridgeable token contract address
    address private BRIDGE_TOKEN;

    /// @dev Daily total deposit limit
    uint256 private BRIDGE_TOTAL_DAILY_LIMIT;

    /// @dev Daily operator bridge limit
    uint256 private BRIDGE_OPERATOR_DAILY_LIMIT;

    /// @dev Whitelisted users merkle root hash
    bytes32 private WHITELIST_ROOT;

    /// @dev Bridge blacklist
    mapping(address => bool) private _blacklist;

    /// @dev Bridge positions
    mapping(address => BridgePosition) private _positions;

    /// @dev Initialize contract states
    /// @param validator Bridge validator address
    /// @param token Bridge Token contract address - AGOV/MPWR address
    /// @param signer Bridge signer address
    /// @param totalLimit Total daily limit
    /// @param operatorLimit Operator daily limit
    function initialize(
        address validator,
        address signer,
        address token,
        uint256 totalLimit,
        uint256 operatorLimit
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        setBridgeValidator(validator);
        setBridgeSigner(signer);
        setBridgeToken(token);
        setTotalDailyLimit(totalLimit);
        setOperatorDailyLimit(operatorLimit);
        _pause();
    }

    /// @dev Set Bridge validator address
    /// @param validator Bridge validator address
    function setBridgeValidator(address validator) public onlyOwner {
        BRIDGE_VALIDATOR = validator;
        emit BridgeValidator(validator);
    }

    /// @dev Set Bridgeable token contract address
    /// @param token Bridgeable token contract address - AGOV | MPWR
    function setBridgeToken(address token) public onlyOwner {
        BRIDGE_TOKEN = token;
        emit BridgeToken(token);
    }

    /// @dev Set Bridge signer address
    /// @param signer Brige transaction signer address
    function setBridgeSigner(address signer) public onlyOwner {
        BRIDGE_SIGNER = signer;
        emit BridgeSigner(signer);
    }

    /// @dev Set daily bridge limit amount
    /// @param limit Total daily bridge limit
    function setTotalDailyLimit(uint256 limit) public onlyOwner {
        BRIDGE_TOTAL_DAILY_LIMIT = limit;
        emit BridgeTotalDailyLimit(limit);
    }

    /// @dev Set operator's daily bridge limit amount
    /// @param limit Operator's daily bridge limit
    function setOperatorDailyLimit(uint256 limit) public onlyOwner {
        BRIDGE_OPERATOR_DAILY_LIMIT = limit;
        emit BridgeOperatorDailyLimit(limit);
    }

    /// @dev Set whitelist merkle root
    /// @param root Whitelist merkletree root
    function setWhitelist(bytes32 root) public onlyOwner {
        WHITELIST_ROOT = root;
        emit BridgeWhitelist(root);
    }

    /// @dev Blacklist wallets
    function setBlacklists(
        address[] calldata operators,
        bool[] memory activates
    ) external onlyOwner {
        uint256 length = operators.length;
        require(length == activates.length, "Bridge: Invalid inputs");

        bool activate;
        address operator;
        for (uint256 i = 0; i < length; i++) {
            operator = operators[i];
            activate = activates[i];
            _blacklist[operator] = activate;
            emit BridgeBlacklist(operator, activate);
        }
    }

    /// @dev Set Bridge phase
    function setBridgePhase(BridgePhase phase) external onlyOwner {
        BRIDGE_PHASE = phase;
        emit BridgeOngoingPhase(phase);
    }

    /// @dev Withdraw Bridge token
    function withdrawBridgeToken(address receiver, uint256 amount)
        external
        onlyOwner
    {
        getBridgeToken().safeTransfer(receiver, amount);
    }

    /// @dev Pause Bridge
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause Bridge
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Deposit bridge token
    function deposit(
        uint256 amount,
        bytes32[] calldata proofs
    ) external whenNotPaused nonReentrant {
        uint256 positionAmount = amount;
        require(positionAmount > 0, "Bridge: Invalid bridge amount");

        address operator = _msgSender();
        require(
            _validateOperator(operator, proofs),
            "Bridge: Invalid operator"
        );
        require(
            getOperatorLimit(operator) >= positionAmount,
            "Bridge: Insufficient bridge amount"
        );

        // Transfer Bridge Token to contract
        getBridgeToken().safeTransferFrom(
            operator,
            address(this),
            positionAmount
        );

        // update operator day position
        _updateOperatorPosition(operator, positionAmount);
        // update contract day position
        _updateOperatorPosition(address(this), positionAmount);

        emit BridgeDeposit(operator, block.chainid, positionAmount);
    }

    /// @dev Withdraw bridge token
    function withdraw(bytes memory data, bytes memory signature)
        external
        onlyValidator
    {
        (uint256 amount, address operator) = abi.decode(
            data,
            (uint256, address)
        );
        require(
            _validateSigner(amount, operator, signature),
            "Bridge: Invalid signer"
        );

        // Transfer Bridge Token to operator
        getBridgeToken().safeTransfer(operator, amount);

        emit BridgeWithdraw(operator, block.chainid, amount);
    }

    /// @dev Get Bridge validator address
    function getBridgeValidator() public view returns (address) {
        return BRIDGE_VALIDATOR;
    }

    /// @dev Get Bridge signer address
    function getBridgeSigner() public view returns (address) {
        return BRIDGE_SIGNER;
    }

    /// @dev Get whitelist merkle root
    function getWhitelist() public view returns (bytes32) {
        return WHITELIST_ROOT;
    }

    /// @dev Get Bridge token contract address
    function getBridgeToken() public view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(BRIDGE_TOKEN);
    }

    /// @dev Get position info
    function getPosition(address operator)
        public
        view
        returns (BridgePosition memory)
    {
        return _positions[operator];
    }

    /// @dev Get total daily limit
    function getTotalDailyLimit() public view returns (uint256) {
        return BRIDGE_TOTAL_DAILY_LIMIT;
    }

    /// @dev Get operator daily limit
    function getOperatorDailyLimit() public view returns (uint256) {
        return BRIDGE_OPERATOR_DAILY_LIMIT;
    }

    /// @dev Get Bridge phase
    function getBridgePhase() public view returns (BridgePhase) {
        return BRIDGE_PHASE;
    }

    /// @dev Get today bridge limit
    function getBridgeLimit() public view returns (uint256) {
        return _getLimit(address(this), getTotalDailyLimit());
    }

    /// @dev Get today operator limit
    function getOperatorLimit(address operator) public view returns (uint256) {
        uint256 operatorLimit = _getLimit(operator, getOperatorDailyLimit());
        uint256 bridgeLimit = getBridgeLimit();
        return operatorLimit > bridgeLimit ? bridgeLimit : operatorLimit;
    }

    /// @dev Get today position number
    function getTodayPositionId() public view returns (uint256) {
        return block.timestamp / ONE_DAY_TIME;
    }

    /// @dev Get operator limit
    function _getLimit(address operator, uint256 operatorDailyLimit)
        private
        view
        returns (uint256)
    {
        BridgePosition memory position = getPosition(operator);
        uint256 todayPositionId = getTodayPositionId();
        if (position.positionId < todayPositionId) {
            return operatorDailyLimit;
        }
        if (
            position.positionId == todayPositionId &&
            position.positionAmount < operatorDailyLimit
        ) {
            return operatorDailyLimit - position.positionAmount;
        }
        return 0;
    }

    /// @dev Validate signer address
    function _validateSigner(
        uint256 amount,
        address operator,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked(amount, operator));
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        return signer == getBridgeSigner();
    }

    /// @dev Validate operator
    function _validateOperator(address operator, bytes32[] calldata proofs)
        private
        view
        returns (bool)
    {
        require(!_blacklist[operator], "Bridge: Blacklisted operator");
        if (BRIDGE_PHASE == BridgePhase.WHITELIST_PHASE) {
            return
                MerkleProofUpgradeable.verify(
                    proofs,
                    getWhitelist(),
                    keccak256(abi.encodePacked(operator))
                );
        }
        return true;
    }

    /// @dev Update operator position
    function _updateOperatorPosition(address operator, uint256 amount) private {
        uint256 todayPositionId = getTodayPositionId();
        BridgePosition storage position = _positions[operator];
        if (position.positionId < todayPositionId) {
            position.positionId = todayPositionId;
            position.positionAmount = 0;
        }
        position.positionAmount += amount;
    }

    /// @dev Only bridge validation can call
    modifier onlyValidator() {
        require(
            _msgSender() == getBridgeValidator(),
            "Bridge: Only validator can call"
        );
        _;
    }
}
