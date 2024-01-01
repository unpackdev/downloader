// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./IDToken.sol";

/// @title DBridge: A decentralized bridge contract for token transfers
/// @notice This contract facilitates token transfers between different chains using a decentralized approach.
contract DBridge is Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    bytes32 public immutable domainHash;
    address payable immutable exchangePool;

    uint256 private _bridgeIdCounter = 0;

    IDToken private rewardToken;
    uint256 private baseVoteFee;
    uint256 private rewardFee;

    /// @dev Enum representing the types of transactions (Deposit or Withdraw).
    enum TxnType {
        DEPOSIT,
        WITHDRAW
    }

    struct TokenDetails {
        mapping(uint256 => address) bridgeTokenAddress;
        uint256 platformFee;
        bool isAvailable;
        bool isMintableBurnable;
    }

    struct BridgeTxn {
        uint256 bridgeIndex;
        TxnType txnType;
        address sender;
        uint256 chainId;
        address tokenAddress;
        uint256 amount;
        bool isWithdrawed;
        bool isVerifiedByRelayer;
        address[] confirmations;
        mapping(address => uint256) reward;
    }

    struct VoteData {
        bytes32 bridgeId;
        uint256 bridgeIndex;
        address sender;
        uint256 chainId;
        uint256 sourceChainId;
        address sourceBridgeAddress;
        address tokenAddress;
        uint256 amount;
    }

    struct WithdrawData {
        bytes32 bridgeId;
        uint256 bridgeIndex;
        address sender;
        uint256 chainId;
        uint256 sourceChainId;
        address sourceBridgeAddress;
        address tokenAddress;
        uint256 amount;
        bytes[] signatures;
    }

    mapping(address => TokenDetails) public supportedTokens;
    mapping(bytes32 => BridgeTxn) public bridgeTxn;

    event Deposit(
        bytes32 indexed bridgeId,
        uint256 indexed bridgeIndex,
        address sender,
        uint256 chainId,
        address tokenAddress,
        uint256 amount
    );

    event Bridge(
        bytes32 indexed bridgeId,
        uint256 sourceChainId,
        address receiver,
        address tokenAddress,
        uint256 amount,
        address[] validators
    );

    event Confirmation(
        bytes32 indexed bridgeId,
        uint256 sourceChainId,
        address receiver,
        address tokenAddress,
        uint256 amount,
        address confirmer
    );

    event Withdraw(
        bytes32 indexed bridgeId,
        address indexed receiver,
        address bridgeTokenAddress,
        uint256 amount
    );

    /// @notice Deploy the DBridge contract with the provided parameters.
    /// @param name The name of the contract.
    /// @param version The version of the contract.
    /// @param exchangePoolAddress The address of the exchange pool.
    /// @param rewarTokenAddress The address of the reward token.
    /// @param _baseVoteFee The base vote fee.
    /// @param _rewardFee The reward fee.
    constructor(
        string memory name,
        string memory version,
        address payable exchangePoolAddress,
        IDToken rewarTokenAddress,
        uint256 _baseVoteFee,
        uint256 _rewardFee
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);
        exchangePool = exchangePoolAddress;
        rewardToken = rewarTokenAddress;
        baseVoteFee = _baseVoteFee;
        rewardFee = _rewardFee;
        domainHash = keccak256(
            abi.encode(
                keccak256(
                    abi.encodePacked(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    )
                ),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Pause the contract, preventing new transactions.
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing transactions to continue.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Add a new token to the supported tokens list.
    /// @param tokenAddress The address of the token to be added.
    /// @param tokenPlatformFee The platform fee associated with the token.
    /// @param isMintableBurnableToken A flag indicating if the token is mintable/burnable.
    function addToken(
        address tokenAddress,
        uint256 tokenPlatformFee,
        bool isMintableBurnableToken
    ) external onlyRole(GOVERNOR_ROLE) whenNotPaused {
        try IDToken(tokenAddress).totalSupply() returns (uint256) {
            try IDToken(tokenAddress).name() returns (string memory) {
                TokenDetails storage token = supportedTokens[tokenAddress];
                token.isAvailable = true;
                token.platformFee = tokenPlatformFee;
                token.isMintableBurnable = isMintableBurnableToken;
            } catch {
                revert("Address not token");
            }
        } catch {
            revert("Address not token");
        }
    }

    /// @notice Add support for a new chain for a specific token.
    /// @param tokenAddress The address of the token.
    /// @param chainId The ID of the supported chain.
    /// @param bridgeTokenAddress The address of the corresponding bridge token.
    function addSupportedChain(
        address tokenAddress,
        uint256 chainId,
        address bridgeTokenAddress
    ) external onlyRole(GOVERNOR_ROLE) whenNotPaused {
        supportedTokens[tokenAddress].bridgeTokenAddress[
            chainId
        ] = bridgeTokenAddress;
    }

    /// @notice Enable or disable a token for transfers.
    /// @param tokenAddress The address of the token.
    /// @param isEnable Set to true to enable the token, or false to disable it.
    function enableDisableToken(
        address tokenAddress,
        bool isEnable
    ) external onlyRole(GOVERNOR_ROLE) whenNotPaused {
        supportedTokens[tokenAddress].isAvailable = isEnable;
    }

    /// @notice Edit the platform fee of an existing token.
    /// @param tokenAddress The address of the token.
    /// @param newPlatformFee The updated platform fee for the token.
    function updateTokenPlatformFee(
        address tokenAddress,
        uint256 newPlatformFee
    ) external onlyRole(GOVERNOR_ROLE) {
        require(
            supportedTokens[tokenAddress].isAvailable,
            "Token is not supported"
        );
        supportedTokens[tokenAddress].platformFee = newPlatformFee;
    }

    /// @notice Get the bridge token address for a specific token on a given chain.
    /// @param tokenAddress The address of the token.
    /// @param chainId The ID of the chain.
    /// @return bridgeTokenAddress The bridge token address for the token on the specified chain.
    function getBridgeTokenAddress(
        address tokenAddress,
        uint256 chainId
    ) external view whenNotPaused returns (address bridgeTokenAddress) {
        return supportedTokens[tokenAddress].bridgeTokenAddress[chainId];
    }

    /// @notice Deposit tokens into the bridge for cross-chain transfer.
    /// @param chainId The ID of the target chain.
    /// @param tokenAddress The address of the token being deposited.
    /// @param amount The amount of tokens to deposit.
    /// @return bridgeId The unique ID for the bridge transaction.
    function deposit(
        uint256 chainId,
        address tokenAddress,
        uint256 amount
    ) external whenNotPaused returns (bytes32 bridgeId) {
        require(
            supportedTokens[tokenAddress].isAvailable,
            "Token is not supported"
        );
        require(
            supportedTokens[tokenAddress].bridgeTokenAddress[chainId] !=
                address(0),
            "Chain ID is not supported"
        );
        _bridgeIdCounter += 1;
        bridgeId = keccak256(
            abi.encodePacked(
                _msgSender(),
                address(this),
                chainId,
                supportedTokens[tokenAddress].bridgeTokenAddress[chainId],
                amount,
                _bridgeIdCounter
            )
        );

        require(
            bridgeTxn[bridgeId].sender == address(0),
            "Bridge already exists"
        );

        if (supportedTokens[tokenAddress].isMintableBurnable) {
            IDToken(tokenAddress).burnFrom(_msgSender(), amount);
        } else {
            IERC20(tokenAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                amount
            );
        }

        BridgeTxn storage txn = bridgeTxn[bridgeId];
        txn.txnType = TxnType.DEPOSIT;
        txn.sender = _msgSender();
        txn.chainId = chainId;
        txn.tokenAddress = tokenAddress;
        txn.amount = amount;
        txn.isWithdrawed = false;
        txn.isVerifiedByRelayer = false;

        emit Deposit(
            bridgeId,
            _bridgeIdCounter,
            _msgSender(),
            chainId,
            supportedTokens[tokenAddress].bridgeTokenAddress[chainId],
            amount
        );
    }

    /// @notice Bridge a withdrawal request initiated on another chain.
    /// @param withdrawData The data for the withdrawal request.
    function bridge(WithdrawData calldata withdrawData) external whenNotPaused {
        require(hasRole(RELAYER_ROLE, _msgSender()), "Not a relayer");
        BridgeTxn storage txn = bridgeTxn[withdrawData.bridgeId];
        require(!txn.isVerifiedByRelayer, "Bridge already verified");

        bytes32 bridgeId_ = keccak256(
            abi.encodePacked(
                withdrawData.sender,
                withdrawData.sourceBridgeAddress,
                block.chainid,
                withdrawData.tokenAddress,
                withdrawData.amount,
                withdrawData.bridgeIndex
            )
        );
        require(withdrawData.bridgeId == bridgeId_, "Invalid bridge id");
        require(
            withdrawData.signatures.length >= 3,
            "should have 3 or more signatures"
        );

        address[] memory signers = _verifyWithdraw(withdrawData);

        for (uint256 i = 0; i < signers.length; i++) {
            require(
                hasRole(RELAYER_ROLE, signers[i]),
                "Unauthorized signature"
            );
        }

        if (txn.sender == address(0)) {
            txn.bridgeIndex = withdrawData.bridgeIndex;
            txn.txnType = TxnType.WITHDRAW;
            txn.sender = withdrawData.sender;
            txn.chainId = withdrawData.sourceChainId;
            txn.tokenAddress = withdrawData.tokenAddress;
            txn.amount = withdrawData.amount;
            txn.isWithdrawed = false;
        } else {
            require(
                txn.txnType == TxnType.WITHDRAW,
                "Not a withdrawal transaction"
            );
        }
        txn.isVerifiedByRelayer = true;

        emit Bridge(
            withdrawData.bridgeId,
            withdrawData.sourceChainId,
            withdrawData.sender,
            withdrawData.tokenAddress,
            withdrawData.amount,
            signers
        );
    }

    /// @notice Add a new bridge transaction initiated on another chain.
    /// @param voteData The data for the bridge transaction.
    function addBridge(VoteData calldata voteData) external payable whenNotPaused {
        require(
            supportedTokens[voteData.tokenAddress].isAvailable,
            "Token is not supported"
        );
        bytes32 bridgeId_ = keccak256(
            abi.encodePacked(
                voteData.sender,
                voteData.sourceBridgeAddress,
                block.chainid,
                voteData.tokenAddress,
                voteData.amount,
                voteData.bridgeIndex
            )
        );
        require(voteData.bridgeId == bridgeId_, "Invalid bridge id");
        require(voteData.sender != _msgSender(), "Cannot vote for self");
        BridgeTxn storage txn = bridgeTxn[voteData.bridgeId];
        require(txn.sender == address(0), "Bridge already exists");

        uint256 rewardMultiple = msg.value / baseVoteFee;
        require(rewardMultiple > 0, "Insufficient fee");
        exchangePool.transfer(msg.value);

        txn.bridgeIndex = voteData.bridgeIndex;
        txn.txnType = TxnType.WITHDRAW;
        txn.sender = voteData.sender;
        txn.chainId = voteData.sourceChainId;
        txn.tokenAddress = voteData.tokenAddress;
        txn.amount = voteData.amount;
        txn.isWithdrawed = false;
        txn.isVerifiedByRelayer = false;
        txn.confirmations.push(_msgSender());
        txn.reward[_msgSender()] = rewardMultiple * rewardFee;

        emit Confirmation(
            voteData.bridgeId,
            voteData.sourceChainId,
            voteData.sender,
            voteData.tokenAddress,
            voteData.amount,
            _msgSender()
        );
    }

    /// @notice Confirm a previously initiated bridge transaction.
    /// @param voteData The data for confirming the bridge transaction.
    function confirmBridge(VoteData calldata voteData) external payable whenNotPaused {
        bytes32 bridgeId_ = keccak256(
            abi.encodePacked(
                voteData.sender,
                voteData.sourceBridgeAddress,
                voteData.chainId,
                voteData.tokenAddress,
                voteData.amount,
                voteData.bridgeIndex
            )
        );
        require(voteData.bridgeId == bridgeId_, "Invalid bridge id");
        require(voteData.sender != _msgSender(), "Cannot vote for self");
        BridgeTxn storage txn = bridgeTxn[voteData.bridgeId];
        require(txn.sender != address(0), "Bridge doesn't exist");
        require(!txn.isWithdrawed, "Bridge already withdrawn");
        require(txn.txnType == TxnType.WITHDRAW, "Not a withdrawal type");

        require(
            txn.bridgeIndex == voteData.bridgeIndex &&
                txn.sender == voteData.sender &&
                txn.chainId == voteData.sourceChainId &&
                txn.tokenAddress == voteData.tokenAddress &&
                txn.amount == voteData.amount,
            "Data verification failed"
        );

        uint256 rewardMultiple = msg.value / baseVoteFee;
        require(rewardMultiple > 0, "Insufficient fee");
        exchangePool.transfer(msg.value);

        txn.confirmations.push(_msgSender());
        txn.reward[_msgSender()] = rewardMultiple * rewardFee;
    }

    /// @notice Withdraw tokens from the bridge after all confirmations are received.
    /// @param bridgeId The ID of the bridge transaction to withdraw from.
    function withdraw(bytes32 bridgeId) external payable whenNotPaused {
        BridgeTxn storage txn = bridgeTxn[bridgeId];
        require(txn.sender != address(0), "Bridge doesn't exist");
        require(!txn.isWithdrawed, "Bridge already withdrawn");
        require(txn.txnType == TxnType.WITHDRAW, "Not a withdrawal type");
        require(txn.isVerifiedByRelayer, "Bridge not verified");

        require(
            supportedTokens[txn.tokenAddress].platformFee == msg.value,
            "Not Platform fee"
        );
        if (supportedTokens[txn.tokenAddress].platformFee > 0) {
            exchangePool.transfer(msg.value);
        }
        txn.isWithdrawed = true;

        if (supportedTokens[txn.tokenAddress].isMintableBurnable) {
            IDToken(txn.tokenAddress).mint(txn.sender, txn.amount);
        } else {
            IERC20(txn.tokenAddress).safeTransfer(txn.sender, txn.amount);
        }

        for (uint256 i = 0; i < txn.confirmations.length; i++) {
            IDToken(rewardToken).mint(
                txn.confirmations[i],
                txn.reward[txn.confirmations[i]]
            );
        }

        emit Withdraw(bridgeId, txn.sender, txn.tokenAddress, txn.amount);
    }

    /**
     * @dev Verifies the withdrawal request by recovering the signers from provided ECDSA signatures.
     *
     * @param withdrawData_ The withdrawal data including the bridge ID, sender, chain ID, token address, amount, and signatures.
     * @return signers An array of addresses representing the verified signers of the withdrawal request.
     */
    function _verifyWithdraw(
        WithdrawData calldata withdrawData_
    ) internal view returns (address[] memory) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                "BridgeToken(bytes32 bridgeId,address sender,uint256 chainId,address tokenAddress,uint256 amount)"
                            )
                        ),
                        withdrawData_.bridgeId,
                        withdrawData_.sender,
                        block.chainid,
                        withdrawData_.tokenAddress,
                        withdrawData_.amount
                    )
                )
            )
        );
        // Create an array of addresses to store the recovered signers.
        address[] memory signers = new address[](
            withdrawData_.signatures.length
        );

        // Recover signers from the provided ECDSA signatures.
        for (uint256 i = 0; i < withdrawData_.signatures.length; i++) {
            bytes memory _signature = withdrawData_.signatures[i];
            signers[i] = ECDSA.recover(hash, _signature);
        }
        return signers;
    }
}
