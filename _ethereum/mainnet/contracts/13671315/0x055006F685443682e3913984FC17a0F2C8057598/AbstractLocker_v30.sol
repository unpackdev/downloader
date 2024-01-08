//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Upgradeable.sol";

interface IERC20Decimals {
    function decimals() external returns (uint8);
}

abstract contract AbstractLocker_v30 is Initializable, OwnableUpgradeable {
    string constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 constant EIP712_DOMAIN_TYPEHASH=keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));
    bytes32 private constant BRIDGE_WITHDRAW_TYPEHASH=keccak256(abi.encodePacked(
        "BridgeWithdraw(uint256 claimId,uint256 targetChainGuid,address targetLockerAddress,address targetAddress,uint256 amount,uint256 deadline)"
    ));
    bytes32 private constant BRIDGE_REFUND_TYPEHASH=keccak256(abi.encodePacked(
        "BridgeRefund(uint256 claimId,uint256 sourceChainGuid,address sourceLockerAddress,address sourceAddress,uint256 amount)"
    ));
    bytes32 private constant LIQUIDITY_WITHDRAW_TYPEHASH=keccak256(abi.encodePacked(
        "LiquidityWithdraw(uint256 claimId,uint256 targetChainGuid,address targetLockerAddress,address targetAddress,uint256 amount,uint256 deadline,bool bypassFee)"
    ));
    bytes32 private ORACLE_DOMAIN_SEPARATOR;
    uint256 public chainGuid;
    uint256 public evmChainId;
    address public lockerToken;
    address public feeAddress;
    uint16 public feeBP;
    bool public maintenanceMode;
    mapping(address => bool) public oracles;
    mapping(uint256 => bool) public claims;
    uint8 public tokenDecimals;

    event BridgeDeposit(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event BridgeWithdraw(address indexed sender, address indexed targetAddress,  uint256 amount);
    event BridgeRefund(address indexed sender, address indexed sourceAddress, uint256 amount);

    event LiquidityAdd(address indexed sender, address indexed to, uint256 amount);
    event LiquidityRemove(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event LiquidityWithdraw(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event LiquidityRefund(address indexed sender, address indexed sourceAddress, uint256 amount);

    function __AbstractLocker_init(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AbstractLocker_init_unchained(_chainGuid, _lockerToken, _oracleAddress, _feeAddress, _feeBP);
    }

    function __AbstractLocker_init_unchained(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        require(_feeBP <= 10000, "initialize: invalid fee");

        uint256 _evmChainId;
        assembly {
            _evmChainId := chainid()
        }
        chainGuid = _chainGuid;
        evmChainId = _evmChainId;
        lockerToken = _lockerToken;
        feeAddress = _feeAddress;
        feeBP = _feeBP;
        maintenanceMode = false;
        oracles[_oracleAddress] = true;

        bytes32 _ORACLE_DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("BAG Locker Oracle"),
            keccak256("2"),
            _evmChainId,
            address(this)
        ));
        ORACLE_DOMAIN_SEPARATOR = _ORACLE_DOMAIN_SEPARATOR;

        setupTokenDecimals();
    }

    modifier live {
        require(!maintenanceMode, "locker: maintenance mode");
        _;
    }

    function setupTokenDecimals() public virtual onlyOwner {
        tokenDecimals = IERC20Decimals(lockerToken).decimals();
    }

    // Update fee address
    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: not authorized");
        feeAddress = _feeAddress;
    }

    // Update fee bps
    function setFeeBP(uint16 _feeBP) external onlyOwner {
        require(_feeBP <= 10000, "setFeeBP: invalid fee");
        feeBP = _feeBP;
    }

    // Update oracle address
    function addOracleAddress(address _oracleAddress) external onlyOwner {
        oracles[_oracleAddress] = true;
    }

    function removeOracleAddress(address _oracleAddress) external onlyOwner {
        oracles[_oracleAddress] = false;
    }

    // Update maintenance mode
    function setMaintenanceMode(bool _maintenanceMode) external onlyOwner {
        maintenanceMode = _maintenanceMode;
    }

    // Check if the claim has been processed and return current block time and number
    function isClaimed(uint256 _claimId) external view returns (bool, uint256, uint256) {
        return (claims[_claimId], block.timestamp, block.number);
    }

    // Deposit funds to locker from transfer to another chain
    function bridgeDeposit(
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline
    ) external live {
        // Checks
        require(_targetChainGuid != chainGuid || _targetLockerAddress != address(this), 'bridgeDeposit: same locker');
        require(_amount > 0, 'bridgeDeposit: zero amount');
        require(_deadline >= block.timestamp, 'bridgeDeposit: invalid deadline');

        // Effects

        // Interaction
        _receiveTokens(msg.sender, _amount);

        emit BridgeDeposit(msg.sender, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount);
    }

    // Withdraw tokens on a new chain with a valid claim from the oracle
    function bridgeWithdraw(
        uint256 _claimId,
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require(chainGuid == _targetChainGuid, 'bridgeWithdraw: wrong chain');
        require(address(this) == _targetLockerAddress, 'bridgeWithdraw: wrong locker');
        require(_deadline >= block.timestamp, 'bridgeWithdraw: claim expired');
        require(claims[_claimId] == false, 'bridgeWithdraw: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'bridgeWithdraw: bad decimals');

        uint256 feeAmount = _amount * feeBP / 10000;
        uint256 netAmount = _amount - feeAmount;

        // values must cover all non-signature arguments to the external function call
        bytes32 values = keccak256(abi.encode(
            BRIDGE_WITHDRAW_TYPEHASH,
            _claimId, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount, _deadline
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        if (feeAmount > 0) {
            _sendFees(feeAmount);
        }
        _sendTokens(_targetAddress, netAmount);

        emit BridgeWithdraw(msg.sender, _targetAddress, _amount);
    }

    // Refund tokens on the original chain with a valid claim from the oracle
    function bridgeRefund(
        uint256 _claimId,
        uint256 _sourceChainGuid,
        address _sourceLockerAddress,
        address _sourceAddress,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require((chainGuid == _sourceChainGuid) && (address(this) == _sourceLockerAddress), 'bridgeRefund: wrong chain');
        require(claims[_claimId] == false, 'bridgeRefund: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'bridgeRefund: bad decimals');

        // values must cover all non-signature arguments to the external function call
        bytes32 values = keccak256(abi.encode(
            BRIDGE_REFUND_TYPEHASH,
            _claimId, _sourceChainGuid, _sourceLockerAddress, _sourceAddress, _amount
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        _sendTokens(_sourceAddress, _amount);

        emit BridgeRefund(msg.sender, _sourceAddress, _amount);
    }


    // Withdraw tokens on a new chain with a valid claim from the oracle
    function liquidityWithdraw(
        uint256 _claimId,
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline,
        bool _bypassFee,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require(chainGuid == _targetChainGuid, 'liquidityWithdraw: wrong chain');
        require(address(this) == _targetLockerAddress, 'liquidityWithdraw: wrong locker');
        require(_deadline >= block.timestamp, 'liquidityWithdraw: claim expired');
        require(claims[_claimId] == false, 'liquidityWithdraw: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'liquidityWithdraw: bad decimals');

        // values must cover all non-signature arguments to the publexternalic function call
        bytes32 values = keccak256(abi.encode(
            LIQUIDITY_WITHDRAW_TYPEHASH,
            _claimId, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount, _deadline, _bypassFee
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        uint256 feeAmount = _bypassFee ? 0 : _amount * feeBP / 10000;
        uint256 netAmount = _amount - feeAmount;
        if (feeAmount > 0) {
            _sendFees(feeAmount);
        }
        _sendTokens(_targetAddress, netAmount);

        emit LiquidityWithdraw(msg.sender, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount);
    }

    // Verifies that the claim signature is from a trusted source
    function _verify(
        bytes32 _values,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked(
            EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
            ORACLE_DOMAIN_SEPARATOR,
            _values
        ));
        address recoveredAddress = ECDSAUpgradeable.recover(digest, _v, _r, _s);
        require(oracles[recoveredAddress], 'verify: tampered sig');
    }

    function _receiveTokens(
        address _fromAddress,
        uint256 _amount
    ) virtual internal;

    function _sendTokens(
        address _toAddress,
        uint256 _amount
    ) virtual internal;

    function _sendFees(
        uint256 _feeAmount
    ) virtual internal;

    uint256[50] private __gap;
}