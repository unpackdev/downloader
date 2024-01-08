// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IMirrorERC20ProxyStorage.sol";
import "./IERC20.sol";

/**
 * @title MirrorERC20ProxyStorage
 * @author MirrorXYZ
 */
contract MirrorERC20ProxyStorage is
    IMirrorERC20ProxyStorage,
    IMirrorERC20ProxyStorageEvents,
    IERC20Events
{
    // ============ Constants ============

    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // ============ Structs ============

    struct TokenMetadata {
        string name;
        string symbol;
        uint8 decimals;
    }

    // ============ Mutable Storage ============

    /// @notice Proxies to operator
    mapping(address => address) public proxyOperator;
    /// @notice proxy address to token metadata.
    mapping(address => TokenMetadata) _tokenMetadata;
    mapping(address => uint256) private _totalSupply;
    // Permitting
    mapping(address => bytes32) private domainSeparators;
    mapping(address => mapping(address => uint256)) private _nonces;
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => mapping(address => uint256)))
        private _allowance;

    // ============ Events ============

    event OperatorChanged(
        address indexed proxy,
        address oldOperator,
        address newOperator
    );

    // ============ Modifiers ============

    modifier onlyOperator(address proxy, address account) {
        require(proxyOperator[proxy] == account, "only operator can call");
        _;
    }

    function operator() external view override returns (address) {
        return proxyOperator[msg.sender];
    }

    function setOperator(address sender, address newOperator)
        public
        override
        onlyOperator(msg.sender, sender)
    {
        address proxy = msg.sender;

        emit OperatorChanged(proxy, proxyOperator[proxy], newOperator);
        proxyOperator[proxy] = newOperator;
    }

    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external override returns (address) {
        address proxyAddress = msg.sender;

        require(
            proxyOperator[proxyAddress] == address(0),
            "proxy already registered"
        );

        proxyOperator[proxyAddress] = operator_;
        _tokenMetadata[proxyAddress] = TokenMetadata({
            name: name_,
            symbol: symbol_,
            decimals: decimals_
        });

        _mint(proxyAddress, operator_, totalSupply_);

        domainSeparators[proxyAddress] = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name_)),
                keccak256(bytes("1")),
                block.chainid,
                proxyAddress
            )
        );

        emit NewProxy(proxyAddress, operator_);

        return proxyAddress;
    }

    // ============ ERC-20 Methods ============

    function name() external view override returns (string memory) {
        address proxy = msg.sender;

        require(proxyOperator[proxy] != address(0), "unregistered proxy");

        return _tokenMetadata[proxy].name;
    }

    function symbol() external view override returns (string memory) {
        address proxy = msg.sender;

        require(proxyOperator[proxy] != address(0), "unregistered proxy");

        return _tokenMetadata[proxy].symbol;
    }

    function decimals() external view override returns (uint8) {
        address proxy = msg.sender;

        require(proxyOperator[proxy] != address(0), "unregistered proxy");

        return _tokenMetadata[proxy].decimals;
    }

    function totalSupply() external view override returns (uint256) {
        address proxy = msg.sender;

        require(proxyOperator[proxy] != address(0), "unregistered proxy");

        return _totalSupply[proxy];
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[msg.sender][owner];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowance[msg.sender][owner][spender];
    }

    function approve(
        address sender,
        address spender,
        uint256 value
    ) external override returns (bool) {
        address proxy = msg.sender;

        _approve(proxy, sender, spender, value);

        return true;
    }

    function transfer(
        address sender,
        address to,
        uint256 value
    ) external override returns (bool) {
        _transfer(msg.sender, sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        address proxy = msg.sender;

        // Decrement allowance, unless it's the maximum.
        if (_allowance[proxy][from][to] != type(uint256).max) {
            _allowance[proxy][from][to] -= value;
        }

        _transfer(proxy, from, to, value);

        return true;
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return domainSeparators[msg.sender];
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[msg.sender][owner];
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "ERC20: EXPIRED");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparators[msg.sender],
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        _nonces[msg.sender][owner]++,
                        deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20: INVALID_SIGNATURE"
        );

        _approve(msg.sender, owner, spender, value);
    }

    // ============ Minting ============

    function mint(
        address sender,
        address to,
        uint256 amount
    ) external override onlyOperator(msg.sender, sender) {
        _mint(msg.sender, to, amount);
    }

    // ============ Internal Methods ============

    function _transfer(
        address proxy,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[proxy][from] -= amount;
        _balances[proxy][to] += amount;
    }

    function _mint(
        address proxy,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "ERC20: mint to the zero address");

        _balances[proxy][to] += amount;
        _totalSupply[proxy] += amount;
    }

    function _approve(
        address proxy,
        address sender,
        address spender,
        uint256 value
    ) internal {
        _allowance[proxy][sender][spender] = value;
    }
}
