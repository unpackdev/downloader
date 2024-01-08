//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

abstract contract AbstractLocker is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH=keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));
    bytes32 private constant WITHDRAW_TYPEHASH=keccak256(abi.encodePacked(
        "Withdraw(uint256 claimID,uint256 targetChainID,address targetAddress,uint256 amount,uint256 deadline)"
    ));
    bytes32 private constant REFUND_TYPEHASH=keccak256(abi.encodePacked(
        "Refund(uint256 claimID,uint256 sourceChainID,address sourceAddress,uint256 amount)"
    ));
    bytes32 private DOMAIN_SEPARATOR;
    uint256 private chainID;
    address public token;
    address public feeAddress;
    uint16 public feeBP;
    bool public maintenanceMode;
    mapping(address => bool) public oracles;
    mapping(uint256 => bool) public claims;

    event Deposit(address indexed sender, uint256 indexed targetChainID, address indexed targetAddress, uint256 amount);
    event Withdraw(address indexed sender, address indexed targetAddress,  uint256 amount);
    event Refund(address indexed sender, address indexed sourceAddress, uint256 amount);

    function initialize(
        address _token,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) public initializer {
        __AbstractLocker_init(_token, _oracleAddress, _feeAddress, _feeBP);
    }

    function __AbstractLocker_init(
        address _token,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AbstractLocker_init_unchained(_token, _oracleAddress, _feeAddress, _feeBP);
    }

    function __AbstractLocker_init_unchained(
        address _token,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        require(_feeBP <= 10000, "initialize: invalid fee");

        uint256 _chainID;
        assembly {
            _chainID := chainid()
        }
        chainID = _chainID;
        token = _token;
        feeAddress = _feeAddress;
        feeBP = _feeBP;
        maintenanceMode = false;
        oracles[_oracleAddress] = true;

        bytes32 _DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("BAG Locker Oracle"),
            keccak256("1"),
            _chainID,
            address(this)
        ));
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    modifier live {
        require(!maintenanceMode, "locker: maintenance mode");
        _;
    }

    // Update fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: not authorized");
        feeAddress = _feeAddress;
    }

    // Update fee bps
    function setFeeBP(uint16 _feeBP) public onlyOwner {
        require(_feeBP <= 10000, "setFeeBP: invalid fee");
        feeBP = _feeBP;
    }

    // Update oracle address
    function addOracleAddress(address _oracleAddress) public onlyOwner {
        oracles[_oracleAddress] = true;
    }

    function removeOracleAddress(address _oracleAddress) public onlyOwner {
        oracles[_oracleAddress] = false;
    }

    // Update maintenance mode
    function setMaintenanceMode(bool _maintenanceMode) public onlyOwner {
        maintenanceMode = _maintenanceMode;
    }

    // Check if the claim has been processed and return current block time and number
    function isClaimed(uint256 _claimID) external view returns (bool, uint256, uint256) {
        return (claims[_claimID], block.timestamp, block.number);
    }

    // Deposit funds to locker from transfer to another chain
    function deposit(
        uint256 _targetChainID,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline
    ) public live {
        // Checks
        require(_targetChainID != chainID, 'deposit: invalid target chain');
        require(_amount > 0, 'deposit: zero amount');
        require(_deadline >= block.timestamp, 'deposit: invalid deadline');

        // Effects

        // Interaction
        _receiveTokens(msg.sender, _amount);

        emit Deposit(msg.sender, _targetChainID, _targetAddress, _amount);
    }

    // Withdraw tokens on a new chain with a valid claim from the oracle
    function withdraw(
        uint256 _claimID,
        uint256 _targetChainID,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        // Checks
        require(chainID == _targetChainID, 'withdraw: wrong chain');
        require(_deadline >= block.timestamp, 'withdraw: claim expired');
        require(claims[_claimID] == false, 'withdraw: claim used');

        uint256 feeAmount = _amount.mul(feeBP).div(10000);
        uint256 netAmount = _amount.sub(feeAmount);

        // digest must cover all non-signature arguments to the public function call
        bytes32 digest = keccak256(abi.encodePacked(
            EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                WITHDRAW_TYPEHASH,
                _claimID, _targetChainID, _targetAddress, _amount, _deadline
            ))
        ));
        _verify(digest, _v, _r, _s);

        // Effects
        claims[_claimID] = true;

        // Interactions
        if (feeAmount > 0) {
            _sendTokens(feeAddress, feeAmount);
        }
        _sendTokens(_targetAddress, netAmount);

        emit Withdraw(msg.sender, _targetAddress, _amount);
    }

    // Refund tokens on the original chain with a valid claim from the oracle
    function refund(
        uint256 _claimID,
        uint256 _sourceChainID,
        address _sourceAddress,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        // Checks
        require(chainID == _sourceChainID, 'refund: wrong chain');
        require(claims[_claimID] == false, 'refund: claim used');

        // digest must cover all non-signature arguments to the public function call
        bytes32 digest = keccak256(abi.encodePacked(
            EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                REFUND_TYPEHASH,
                _claimID, _sourceChainID, _sourceAddress, _amount
            ))
        ));
        _verify(digest, _v, _r, _s);

        // Effects
        claims[_claimID] = true;

        // Interactions
        _sendTokens(_sourceAddress, _amount);

        emit Refund(msg.sender, _sourceAddress, _amount);
    }

    // Verifies that the claim signature is from a trusted source
    function _verify(
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        address recoveredAddress = ECDSAUpgradeable.recover(_digest, _v, _r, _s);
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

}