pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Storage.sol";
import "./Config.sol";
import "./Events.sol";

import "./Bytes.sol";
import "./Operations.sol";

import "./UpgradeableMaster.sol";
import "./PairTokenManager.sol";

/// @title zkSync main contract
/// @author Matter Labs
/// @author ZKSwap L2 Labs
/// @author Stars Labs
contract ZkSync is PairTokenManager, UpgradeableMaster, Storage, Config, Events, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    bytes32 private constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;


    function pairFor(address tokenA, address tokenB, bytes32 _salt) external view returns (address pair) {
        pair = pairmanager.pairFor(tokenA, tokenB, _salt);
    }

    function createPair(address _tokenA, address _tokenB, bytes32 salt) external {
        require(_tokenA != _tokenB ||
                keccak256(abi.encodePacked(IERC20(_tokenA).symbol())) == keccak256(abi.encodePacked("EGS")),
                "pair same token invalid");

        requireActive();
        governance.requireGovernor(msg.sender);

        //check _tokenA is registered or not
        uint16 tokenAID = governance.validateTokenAddress(_tokenA);
        //check _tokenB is registered or not
        uint16 tokenBID = governance.validateTokenAddress(_tokenB);

        //create pair
        (address token0, address token1, uint16 token0_id, uint16 token1_id) = _tokenA < _tokenB ? (_tokenA, _tokenB, tokenAID, tokenBID) : (_tokenB, _tokenA, tokenBID, tokenAID);

        address pair = pairmanager.createPair(token0, token1, salt);
        require(pair != address(0), "pair is invalid");

	    addPairToken(pair);

        registerCreatePair(
            token0_id,
            token1_id,
		    validatePairTokenAddress(pair),
            pair
        );
    }

    //create pair including ETH
    function createETHPair(address _tokenERC20, bytes32 salt) external {
        requireActive();
        governance.requireGovernor(msg.sender);
        //check _tokenERC20 is registered or not
        uint16 erc20ID = governance.validateTokenAddress(_tokenERC20);

        //create pair
        address pair = pairmanager.createPair(address(0), _tokenERC20, salt);
        require(pair != address(0), "pair is invalid");

	    addPairToken(pair);

        registerCreatePair(
            0,
            erc20ID,
            validatePairTokenAddress(pair),
            pair);
    }

    function registerCreatePair(uint16 _tokenA, uint16 _tokenB, uint16 _tokenPair, address _pair) internal {
        // Priority Queue request
        (uint16 token0, uint16 token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        Operations.CreatePair memory op = Operations.CreatePair({
            accountId: 0,  //unknown at this point
            tokenA: token0,
            tokenB: token1,
            tokenPair: _tokenPair,
            pair: _pair
        });
        // pubData
        bytes memory pubData = Operations.writeCreatePairPubdata(op);

        addPriorityRequest(Operations.OpType.CreatePair, pubData);

        emit OnchainCreatePair(token0, token1, _tokenPair, _pair);
    }

    // Upgrade functional
    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external pure override returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    /// @notice Notification that upgrade notice period started
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeNoticePeriodStarted() external override {}

    /// @notice Notification that upgrade preparation status is activated
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradePreparationStarted() external override {
        upgradePreparationActive = true;
        upgradePreparationActivationTime = block.timestamp;
    }

    /// @notice Notification that upgrade canceled
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeCanceled() external override {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Notification that upgrade finishes
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeFinishes() external override {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external view override returns (bool) {
        return !exodusMode;
    }

    /// @notice zkSync contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    /// @dev _governanceAddress The address of Governance contract
    /// @dev _verifierAddress The address of Verifier contract
    /// @dev _pairManagerAddress the address of UniswapV2Factory contract
    /// @dev _zkSyncCommitBlockAddress the address of ZkSyncCommitBlockAddress contract
    /// @dev _genesisStateHash Genesis blocks (first block) state tree root hash
    function initialize(bytes calldata initializationParameters) external {
        initializeReentrancyGuard();

        (
        address _governanceAddress,
        address _verifierAddress,
        address _verifierExitAddress,
        address _pairManagerAddress,
        address _zkSyncCommitBlockAddress,
        bytes32 _genesisStateHash
        ) = abi.decode(initializationParameters, (address, address, address, address, address, bytes32));

        governance = Governance(_governanceAddress);
        verifier = Verifier(_verifierAddress);
        verifier_exit = VerifierExit(_verifierExitAddress);
        pairmanager = UniswapV2Factory(_pairManagerAddress);
        zkSyncCommitBlockAddress = _zkSyncCommitBlockAddress;

        // We need initial state hash because it is used in the commitment of the next block
        StoredBlockInfo memory storedBlockZero =
        StoredBlockInfo(0, 0, EMPTY_STRING_KECCAK, 0, _genesisStateHash, bytes32(0));

        storedBlockHashes[0] = hashStoredBlockInfo(storedBlockZero);
    }

    // Priority queue
    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(
        Operations.OpType _opType,
        bytes memory _pubData
    ) internal {
        // Expiration block is: current block number + priority expiration delta
        uint64 expirationBlock = uint64(block.number + PRIORITY_EXPIRATION);

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        bytes20 hashedPubData = Utils.hashBytesToBytes20(_pubData);

        priorityRequests[nextPriorityRequestId] = PriorityOperation({
            hashedPubData: hashedPubData,
            expirationBlock: expirationBlock,
            opType: _opType
            });

        emit NewPriorityRequest(msg.sender, nextPriorityRequestId, _opType, _pubData, uint256(expirationBlock));

        totalOpenPriorityRequests++;
    }

    /// @notice zkSync contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external nonReentrant {
        require(totalBlocksCommitted == totalBlocksProven, "wq1"); // All the blocks must be proven
        require(totalBlocksCommitted == totalBlocksExecuted, "w12"); // All the blocks must be executed

        if (upgradeParameters.length != 0) {
            StoredBlockInfo memory lastBlockInfo;
            (lastBlockInfo) = abi.decode(upgradeParameters, (StoredBlockInfo));
            storedBlockHashes[totalBlocksExecuted] = hashStoredBlockInfo(lastBlockInfo);
        }

        zkSyncCommitBlockAddress = address(0xcb4c185cC1bC048742D3b6AB760Efd2D3592c58f);
    }

    /// @notice Checks that current state not is exodus mode
    function requireActive() internal view {
        require(!exodusMode, "L"); // exodus mode activated
    }

    /// @notice Accrues users balances from deposit priority requests in Exodus mode
    /// @dev WARNING: Only for Exodus mode
    /// @dev Canceling may take several separate transactions to be completed
    /// @param _n number of requests to process
    function cancelOutstandingDepositsForExodusMode(uint64 _n, bytes[] memory _depositsPubdata) external nonReentrant {
        require(exodusMode, "8"); // exodus mode not active
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess == _depositsPubdata.length, "A");
        require(toProcess > 0, "9"); // no deposits to process
        uint64 currentDepositIdx = 0;
        for (uint64 id = firstPriorityRequestId; id < firstPriorityRequestId + toProcess; id++) {
            if (priorityRequests[id].opType == Operations.OpType.Deposit) {
                bytes memory depositPubdata = _depositsPubdata[currentDepositIdx];
                require(Utils.hashBytesToBytes20(depositPubdata) == priorityRequests[id].hashedPubData, "a");
                ++currentDepositIdx;

                Operations.Deposit memory op = Operations.readDepositPubdata(depositPubdata);
                bytes22 packedBalanceKey = packAddressAndTokenId(op.owner, op.tokenId);
                pendingBalances[packedBalanceKey].balanceToWithdraw += op.amount;
            }
            delete priorityRequests[id];
        }
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    /// @notice Deposit ETH to Layer 2 - transfer ether from user into contract, validate it, register deposit
    function depositETH() external payable {
        require(msg.value > 0, "1");
        requireActive();
        require(tokenIds[msg.sender] == 0, "da");
        registerDeposit(0, SafeCast.toUint128(msg.value), msg.sender);
    }

    /// @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @param _token Token address
    /// @param _amount Token amount
    function depositERC20(IERC20 _token, uint104 _amount) external nonReentrant {
        requireActive();
        require(tokenIds[msg.sender] == 0, "db");

        // Get token id by its address
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
            require(!governance.pausedTokens(tokenId), "b"); // token deposits are paused
            require(_token.balanceOf(address(this)) + _amount <= MAX_ERC20_TOKEN_BALANCE, "bgt");
        } else {
            // lpToken
            lpTokenId = validatePairTokenAddress(address(_token));
        }

        uint256 balance_before = 0;
        uint256 balance_after = 0;
        uint128 deposit_amount = 0;
        // lpToken
        if (lpTokenId > 0) {
            // Note: For lp token, main contract always has no money
            balance_before = _token.balanceOf(msg.sender);
            pairmanager.burn(address(_token), msg.sender, SafeCast.toUint128(_amount)); //
            balance_after = _token.balanceOf(msg.sender);
            deposit_amount = SafeCast.toUint128(balance_before.sub(balance_after));
            require(deposit_amount <= MAX_DEPOSIT_AMOUNT, "C1");
            registerDeposit(lpTokenId, deposit_amount, msg.sender);
        } else {
            // token
            balance_before = _token.balanceOf(address(this));
            require(Utils.transferFromERC20(_token, msg.sender, address(this), SafeCast.toUint128(_amount)), "fd012"); // token transfer failed deposit
            balance_after = _token.balanceOf(address(this));
            deposit_amount = SafeCast.toUint128(balance_after.sub(balance_before));
            require(deposit_amount <= MAX_DEPOSIT_AMOUNT, "C2");
            registerDeposit(tokenId, deposit_amount, msg.sender);
        }
    }

    /// @notice Returns amount of tokens that can be withdrawn by `address` from zkSync contract
    /// @param _address Address of the tokens owner
    /// @param _token Address of token, zero address is used for ETH
    function getPendingBalance(address _address, address _token) public view returns (uint128) {
        uint16 tokenId = 0;
        if (_token != address(0)) {
            tokenId = governance.validateTokenAddress(_token);
        }
        return pendingBalances[packAddressAndTokenId(_address, tokenId)].balanceToWithdraw;
    }

    /// @notice Returns amount of tokens that can be withdrawn by `address` from zkSync contract
    /// @param _address Address of the tokens owner
    /// @param _tokenId token id, 0 is used for ETH
    function getBalanceToWithdraw(address _address, uint16 _tokenId) public view returns (uint128) {
        return pendingBalances[packAddressAndTokenId(_address, _tokenId)].balanceToWithdraw;
    }

    /// @notice Register full exit request - pack pubdata, add priority request
    /// @param _accountId Numerical id of the account
    /// @param _token Token address, 0 address for ether
    function requestFullExit(uint32 _accountId, address _token) public nonReentrant {
        requireActive();
        require(_accountId <= MAX_ACCOUNT_ID, "e");

        uint16 tokenId;
        uint16 lpTokenId = tokenIds[_token];
        if (_token == address(0)) {
            tokenId = 0;
        } else if (lpTokenId == 0) {
            // This means it is not a pair address
            // 非lpToken
            tokenId = governance.validateTokenAddress(_token);
            require(!governance.pausedTokens(tokenId), "b"); // token deposits are paused
        } else {
            // lpToken
            tokenId = lpTokenId;
        }

        // Priority Queue request
        Operations.FullExit memory op =
            Operations.FullExit({
                accountId: _accountId,
                owner: msg.sender,
                tokenId: tokenId,
                amount: 0, // unknown at this point
                pairAccountId: 0
            });
        bytes memory pubData = Operations.writeFullExitPubdataForPriorityQueue(op);
        addPriorityRequest(Operations.OpType.FullExit, pubData);

        // User must fill storage slot of balancesToWithdraw(msg.sender, tokenId) with nonzero value
        // In this case operator should just overwrite this slot during confirming withdrawal
        bytes22 packedBalanceKey = packAddressAndTokenId(msg.sender, tokenId);
        pendingBalances[packedBalanceKey].gasReserveValue = FILLED_GAS_RESERVE_VALUE;
    }

   /// @notice Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
    /// @dev Exodus mode must be entered in case of current ethereum block number is higher than the oldest
    /// @dev of existed priority requests expiration block number.
    /// @return bool flag that is true if the Exodus mode must be entered.
    function activateExodusMode() public returns (bool) {
        bool trigger =
            block.number >= priorityRequests[firstPriorityRequestId].expirationBlock &&
                priorityRequests[firstPriorityRequestId].expirationBlock != 0;
        if (trigger) {
            if (!exodusMode) {
                exodusMode = true;
                emit ExodusMode();
            }
            return true;
        } else {
            return false;
        }
    }

    /// @notice Register deposit request - pack pubdata, add priority request and emit OnchainDeposit event
    /// @param _tokenId Token by id
    /// @param _amount Token amount
    /// @param _owner Receiver
    function registerDeposit(
        uint16 _tokenId,
        uint128 _amount,
        address _owner
    ) internal {
        // Priority Queue request
        Operations.Deposit memory op =
            Operations.Deposit({
                accountId: 0, // unknown at this point
                owner: _owner,
                tokenId: _tokenId,
                amount: _amount,
                pairAccountId: 0
            });
        bytes memory pubData = Operations.writeDepositPubdataForPriorityQueue(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData);

        emit OnchainDeposit(
            msg.sender,
            _tokenId,
            _amount,
            _owner
        );
    }

    // The contract is too large. Break some functions to zkSyncCommitBlockAddress
    fallback() external payable {
        address nextAddress = zkSyncCommitBlockAddress;
        require(nextAddress != address(0), "zkSyncCommitBlockAddress should be set");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), nextAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }
}
