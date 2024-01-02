//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";

contract OkStorage is Initializable {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Blacklisted(address indexed _account);
    event DepositEth(address indexed user, uint256 ethAmount, uint256 bETHAmount, address indexed referral);
    event EthReceiverUpdated(address indexed previousReceiver, address indexed newReceiver);
    event ExchangeRateUpdated(address indexed oracle, uint256 newExchangeRate);
    event Mint(address indexed minter, address indexed to, uint256 amount, uint256 exchangeRate);
    event Burn(address indexed minter, address indexed from, uint256 amount, uint256 exchangeRate);
    event MinterUpdated(address indexed minter, bool indexed isActive);
    event MovedToStakingAddress(address indexed ethReceiver, uint256 ethAmount);
    event OperatorUpdated(address indexed previousOperator, address indexed newOperator);
    event OracleUpdated(address indexed previousOracle, address indexed newOracle);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event Pause();
    event SuppliedEth(address indexed supplier, uint256 ethAmount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event UnBlacklisted(address indexed _account);
    event Unpause();
    event TransferShares(address indexed from, address indexed to, uint256 sharesValue);
    // ERC20 related

    bytes32 private constant _TOTAL_SHARE_POSITION = keccak256("org.okx.stakedToken.totalShare");
    bytes32 private constant _SHARE_POSITION = keccak256("org.okx.stakedToken.share");
    bytes32 private constant _ALLOWANCE_POSITION = keccak256("org.okx.stakedToken.allowance");

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 private constant _DOMAIN_SEPARATOR_POSITION = keccak256("org.okx.stakedToken.domainSeparator");

    // role
    bytes32 private constant _ADMIN_POSITION = keccak256("org.okx.stakedToken.admin");
    bytes32 private constant _ORACLE_POSITION = keccak256("org.okx.stakedToken.oracle");
    bytes32 private constant _OWNER_POSITION = keccak256("org.okx.stakedToken.owner");
    bytes32 private constant _MINTERS_POSITION = keccak256("org.okx.stakedToken.minters");
    bytes32 private constant _ETH_RECIEVER_POSITION = keccak256("org.okx.stakedToken.ethReciever");
    bytes32 private constant _OPERATOR_POSITION = keccak256("org.okx.stakedToken.operator");

    // status
    bytes32 private constant _PAUSED_POSITION = keccak256("org.okx.stakedToken.paused");
    bytes32 private constant _BLACKLISTED_POSITION = keccak256("org.okx.stakedToken.blacklisted");
    bytes32 private constant _NONCES_POSITION = keccak256("org.okx.stakedToken.nonces");
    bytes32 private constant _EXCHANGE_RATE_POSITION = keccak256("org.okx.stakedToken.exchangeRate");

    function totalShare() internal view returns (uint256 _totalShare) {
        bytes32 position = _TOTAL_SHARE_POSITION;
        assembly {
            _totalShare := sload(position)
        }
    }

    function _setTotalShare(uint256 _newTotalShare) internal {
        bytes32 position = _TOTAL_SHARE_POSITION;
        assembly {
            sstore(position, _newTotalShare)
        }
    }

    function _getShare() internal pure returns (mapping(address => uint256) storage _share) {
        bytes32 position = _SHARE_POSITION;
        assembly {
            _share.slot := position
        }
    }

    function _getAllowance()
        internal
        pure
        returns (mapping(address => mapping(address => uint256)) storage _allowance)
    {
        bytes32 position = _ALLOWANCE_POSITION;
        assembly {
            _allowance.slot := position
        }
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 _domainSeparator) {
        bytes32 position = _DOMAIN_SEPARATOR_POSITION;
        assembly {
            _domainSeparator := sload(position)
        }
    }

    function _setDomainSeparator(bytes32 _newDomainSeparator) internal {
        bytes32 position = _DOMAIN_SEPARATOR_POSITION;
        assembly {
            sstore(position, _newDomainSeparator)
        }
    }

    function owner() public view returns (address _owner) {
        bytes32 position = _OWNER_POSITION;
        assembly {
            _owner := sload(position)
        }
    }

    function _setOwner(address _newOwner) internal {
        bytes32 position = _OWNER_POSITION;
        assembly {
            sstore(position, _newOwner)
        }
    }

    function admin() public view returns (address _admin) {
        bytes32 position = _ADMIN_POSITION;
        assembly {
            _admin := sload(position)
        }
    }

    function _setAdmin(address _newAdmin) internal {
        bytes32 position = _ADMIN_POSITION;
        assembly {
            sstore(position, _newAdmin)
        }
    }

    function oracle() public view returns (address _oracle) {
        bytes32 position = _ORACLE_POSITION;
        assembly {
            _oracle := sload(position)
        }
    }

    function _setOracle(address _newOracle) internal {
        bytes32 position = _ORACLE_POSITION;
        assembly {
            sstore(position, _newOracle)
        }
    }

    function ethReceiver() public view returns (address _ethReceiver) {
        bytes32 position = _ETH_RECIEVER_POSITION;
        assembly {
            _ethReceiver := sload(position)
        }
    }

    function _setEthReceiver(address _newEthReceiver) internal {
        bytes32 position = _ETH_RECIEVER_POSITION;
        assembly {
            sstore(position, _newEthReceiver)
        }
    }

    function operator() public view returns (address _operator) {
        bytes32 position = _OPERATOR_POSITION;
        assembly {
            _operator := sload(position)
        }
    }

    function _setOperator(address _newOperator) internal {
        bytes32 position = _OPERATOR_POSITION;
        assembly {
            sstore(position, _newOperator)
        }
    }

    function paused() public view returns (bool _paused) {
        bytes32 position = _PAUSED_POSITION;
        assembly {
            _paused := sload(position)
        }
    }

    function _setPaused(bool _newPaused) internal {
        bytes32 position = _PAUSED_POSITION;
        assembly {
            sstore(position, _newPaused)
        }
    }

    function _getBlacklist() internal pure returns (mapping(address => bool) storage _blacklist) {
        bytes32 position = _BLACKLISTED_POSITION;
        assembly {
            _blacklist.slot := position
        }
    }

    function blacklisted(address _account) public view returns (bool _blacklisted) {
        return _getBlacklist()[_account];
    }

    function _getMinters() internal pure returns (mapping(address => bool) storage _minters) {
        bytes32 position = _MINTERS_POSITION;
        assembly {
            _minters.slot := position
        }
    }

    function _setMinter(address _minter, bool _isActive) internal {
        mapping(address => bool) storage minters = _getMinters();
        minters[_minter] = _isActive;
    }

    function isMinter(address _account) public view returns (bool _isMinter) {
        mapping(address => bool) storage minters = _getMinters();
        return minters[_account];
    }

    function _getNonce() internal pure returns (mapping(address => uint256) storage _nonce) {
        bytes32 position = _NONCES_POSITION;
        assembly {
            _nonce.slot := position
        }
    }

    function nonces(address _owner) public view returns (uint256 _nonces) {
        return _getNonce()[_owner];
    }

    function exchangeRate() public view returns (uint256 _exchangeRate) {
        bytes32 position = _EXCHANGE_RATE_POSITION;
        assembly {
            _exchangeRate := sload(position)
        }
    }

    function _setExchangeRate(uint256 _newExchangeRate) internal {
        bytes32 position = _EXCHANGE_RATE_POSITION;
        assembly {
            sstore(position, _newExchangeRate)
        }
    }

    // modifier
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier notBlacklisted(address _account) {
        require(!blacklisted(_account), "Blacklistable: account is blacklisted");
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(admin() == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    modifier onlyOracle() {
        require(oracle() == msg.sender, "Ownable: caller is not the oracle");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Ownable: caller is not the minter");
        _;
    }

    modifier onlyOperator() {
        require(operator() == msg.sender, "Ownable: caller is not the operator");
        _;
    }
}
