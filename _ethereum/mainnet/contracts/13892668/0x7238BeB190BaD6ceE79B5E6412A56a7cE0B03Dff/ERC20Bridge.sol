// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./TransferHelper.sol";

/**
 * @title IMTERC20Bridge
 *
 * @dev An upgradeable contract for moving ERC20 tokens across blockchains. An
 * off-chain relayer is responsible for signing proofs of deposits to be used on destination
 * chains of the transactions. A multi-relayer set up can be used for enhanced security and
 * decentralization.
 *
 * @dev The relayer should wait for finality on the source chain before generating a deposit
 * proof. Otherwise a double-spending attack is possible.
 *
 *
 * @dev Note that transaction hashes shall NOT be used for re-entrance prevention as doing
 * so will result in false negatives when multiple transfers are made in a single
 * transaction (with the use of contracts).
 *
 * @dev Chain IDs in this contract currently refer to the ones introduced in EIP-155. However,
 * a list of custom IDs might be used instead when non-EVM compatible chains are added.
 */
contract IMTERC20Bridge is OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Emits when a deposit is made.
     *
     * @dev Addresses are represented with bytes32 to maximize compatibility with
     * non-Ethereum-compatible blockchains.
     *
     * @param srcChainId Chain ID of the source blockchain (current chain)
     * @param destChainId Chain ID of the destination blockchain
     * @param depositId Unique ID of the deposit on the current chain
     * @param depositor Address of the account on the current chain that made the deposit
     * @param recipient Address of the account on the destination chain that will receive the amount
     * @param currency A bytes32-encoded universal currency key
     * @param amount Amount of tokens being deposited to recipient's address.
     */
    event TokenDeposited(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    );
    event TokenWithdrawn(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    );
    event OperatorChanged(address oldOperator, address operator);
    event RelayerChanged(address oldRelayer, address newRelayer);
    event TokenAdded(bytes32 tokenKey, address tokenAddress);
    event TokenRemoved(bytes32 tokenKey);
    event ChainSupportForTokenAdded(bytes32 tokenKey, uint256 chainId);
    event ChainSupportForTokenDropped(bytes32 tokenKey, uint256 chainId);
    event LimitChanged(bool hasLimit, uint256 limitPeriod, uint256 limitBalance, uint256 limitNumber);

    struct TokenInfo {
        address tokenAddress;
    }

    struct Limit {
        uint256 lastDepositBlock;
        uint256 cumulativeBalance;
        uint256 numberOfTransactions;
    }
    uint256 public limitPeriod;
    uint256 public limitBalance;
    uint256 public limitNumber;
    bool public hasLimit;
    address public operator;
    uint256 public currentChainId;
    address public relayer;
    uint256 public depositCount;
    mapping(bytes32 => TokenInfo) public tokenInfos;
    mapping(bytes32 => mapping(uint256 => bool)) public tokenSupportedOnChain;
    mapping(uint256 => mapping(uint256 => bool)) public withdrawnDeposits;
    mapping(address => Limit) public userLimit;

    bytes32 public DOMAIN_SEPARATOR; // For EIP-712

    bytes32 public constant DEPOSIT_TYPEHASH =
        keccak256(
            "Deposit(uint256 srcChainId,uint256 destChainId,uint256 depositId,bytes32 depositor,bytes32 recipient,bytes32 currency,uint256 amount)"
        );

    modifier onlyOperator() {
        require(operator == msg.sender, "IMTERC20Bridge: caller is not the operator");
        _;
    }

    constructor () {
        __Ownable_init();

        hasLimit=false;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        currentChainId = chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Idle Mystic Token")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }


    function getTokenAddress(bytes32 tokenKey) public view returns (address) {
        return tokenInfos[tokenKey].tokenAddress;
    }

    function isTokenSupportedOnChain(bytes32 tokenKey, uint256 chainId) public view returns (bool) {
        return tokenSupportedOnChain[tokenKey][chainId];
    }

   

    function setRelayer(address _relayer) external onlyOwner {
        _setRelayer(_relayer);
    }

    function setOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    function setLimit(
        bool _hasLimit,
        uint256 _limitPeriod,
        uint256 _limitBalance,
        uint256 _limitNumber
    ) external onlyOperator {
        if (_hasLimit == false) {
            hasLimit = _hasLimit;
            limitPeriod = 0;
            limitBalance = 0;
            limitNumber = 0;
        } else {
            hasLimit = _hasLimit;

            require(_limitPeriod > 0, "IMTERC20Bridge: limitPeriod must be positive");
            require(_limitBalance > 0, "IMTERC20Bridge: limitBalance must be positive");
            require(_limitNumber > 0, "IMTERC20Bridge: limitNumber must be positive");

            limitPeriod = _limitPeriod;
            limitBalance = _limitBalance;
            limitNumber = _limitNumber;
        }

        emit LimitChanged(hasLimit, limitPeriod, limitBalance, limitNumber);
    }

    function addToken(bytes32 tokenKey, address tokenAddress) external onlyOwner {
        require(tokenInfos[tokenKey].tokenAddress == address(0), "IMTERC20Bridge: token already exists");
        require(tokenAddress != address(0), "IMTERC20Bridge: zero address");
        tokenInfos[tokenKey] = TokenInfo({tokenAddress: tokenAddress});
        emit TokenAdded(tokenKey, tokenAddress);
    }

    function removeToken(bytes32 tokenKey) external onlyOwner {
        require(tokenInfos[tokenKey].tokenAddress != address(0), "IMTERC20Bridge: token does not exists");
        delete tokenInfos[tokenKey];
        emit TokenRemoved(tokenKey);
    }

    function addChainSupportForToken(bytes32 tokenKey, uint256 chainId) external onlyOwner {
        require(!tokenSupportedOnChain[tokenKey][chainId], "IMTERC20Bridge: already supported");
        tokenSupportedOnChain[tokenKey][chainId] = true;
        emit ChainSupportForTokenAdded(tokenKey, chainId);
    }

    function dropChainSupportForToken(bytes32 tokenKey, uint256 chainId) external onlyOwner {
        require(tokenSupportedOnChain[tokenKey][chainId], "IMTERC20Bridge: not supported");
        tokenSupportedOnChain[tokenKey][chainId] = false;
        emit ChainSupportForTokenDropped(tokenKey, chainId);
    }

    function deposit(
        bytes32 token,
        uint256 amount,
        uint256 destChainId,
        bytes32 recipient
    ) external {
        if (hasLimit) {
            Limit memory limit = userLimit[msg.sender];

            require(amount <= limitBalance, "IMTERC20Bridge: over limit balance");
            if (block.number.sub(limit.lastDepositBlock) > limitPeriod) {
                userLimit[msg.sender].lastDepositBlock = block.number;
                userLimit[msg.sender].cumulativeBalance = amount;
                userLimit[msg.sender].numberOfTransactions = 1;
            } else {
                uint256 cumulativeBalance = limit.cumulativeBalance.add(amount);
                require(cumulativeBalance <= limitBalance, "IMTERC20Bridge: over limit balance");
                require(limit.numberOfTransactions < limitNumber, "IMTERC20Bridge: over limit number of transactions");

                userLimit[msg.sender].lastDepositBlock = block.number;
                userLimit[msg.sender].cumulativeBalance = cumulativeBalance;
                userLimit[msg.sender].numberOfTransactions = limit.numberOfTransactions.add(1);
            }
        }
        _deposit(token, amount, destChainId, recipient);
    }

    function withdraw(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount,
        bytes calldata signature
    ) external {
        require(destChainId == currentChainId, "IMTERC20Bridge: wrong chain");
        require(!withdrawnDeposits[srcChainId][depositId], "IMTERC20Bridge: already withdrawn");
        require(recipient != 0, "IMTERC20Bridge: zero address");
        require(amount > 0, "IMTERC20Bridge: amount must be positive");

        TokenInfo memory tokenInfo = tokenInfos[currency];
        require(tokenInfo.tokenAddress != address(0), "IMTERC20Bridge: token not found");

        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(DEPOSIT_TYPEHASH, srcChainId, destChainId, depositId, depositor, recipient, currency, amount))
            )
        );
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == relayer, "IMTERC20Bridge: invalid signature");

        withdrawnDeposits[srcChainId][depositId] = true;

        address decodedRecipient = address(uint160(uint256(recipient)));

        TransferHelper.safeTransfer(tokenInfo.tokenAddress, decodedRecipient, amount);

        emit TokenWithdrawn(srcChainId, destChainId, depositId, depositor, recipient, currency, amount);
    }

    function _setRelayer(address _relayer) private {
        require(_relayer != address(0), "IMTERC20Bridge: zero address");
        require(_relayer != relayer, "IMTERC20Bridge: relayer not changed");

        address oldRelayer = relayer;
        relayer = _relayer;

        emit RelayerChanged(oldRelayer, relayer);
    }

    function _setOperator(address _operator) private {
        require(_operator != address(0), "IMTERC20Bridge: zero address");
        require(_operator != operator, "IMTERC20Bridge: operator not changed");

        address oldOperator = operator;
        operator = _operator;

        emit OperatorChanged(oldOperator, operator);
    }

    function _deposit(
        bytes32 token,
        uint256 amount,
        uint256 destChainId,
        bytes32 recipient
    ) private {
        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.tokenAddress != address(0), "IMTERC20Bridge: token not found");

        require(amount > 0, "IMTERC20Bridge: amount must be positive");
        require(destChainId != currentChainId, "IMTERC20Bridge: dest must be different from src");
        require(isTokenSupportedOnChain(token, destChainId), "IMTERC20Bridge: token not supported on chain");
        require(recipient != 0, "IMTERC20Bridge: zero address");

        depositCount = depositCount + 1;

        TransferHelper.safeTransferFrom(tokenInfo.tokenAddress, msg.sender, address(this), amount);

        emit TokenDeposited(currentChainId, destChainId, depositCount, bytes32(uint256(msg.sender)), recipient, token, amount);
    }
}