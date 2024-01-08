// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./IUniswapV2Router02.sol";
import "./ECDSAOffsetRecovery.sol";
import "./FullMath.sol";

/// @title Swap contract for multisignature bridge
contract SwapContract is AccessControl, Pausable, ECDSAOffsetRecovery {
    using SafeERC20 for IERC20;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    uint128 public immutable numOfThisBlockchain;
    IUniswapV2Router02 public blockchainRouter;
    address public blockchainPool;
    mapping(uint256 => address) public RubicAddresses;
    mapping(uint256 => bool) public existingOtherBlockchain;
    mapping(uint256 => uint256) public feeAmountOfBlockchain;
    mapping(uint256 => uint256) public blockchainCryptoFee;

    uint256 public constant SIGNATURE_LENGTH = 65;

    struct processedTx {
        uint256 statusCode;
        bytes32 hashedParams;
    }

    mapping(bytes32 => processedTx) public processedTransactions;
    uint256 public minConfirmationSignatures = 3;

    uint256 public minTokenAmount;
    uint256 public maxTokenAmount;
    uint256 public maxGasPrice;
    uint256 public minConfirmationBlocks;
    uint256 public refundSlippage;

    // emitted every time when user gets crypto or tokens after success crossChainSwap
    event TransferFromOtherBlockchain(
        address user,
        uint256 amount,
        uint256 amountWithoutFee,
        bytes32 originalTxHash
    );
    // emitted every time when user get a refund
    event userRefunded(
        address user,
        uint256 amount,
        uint256 amountWithoutFee,
        bytes32 originalTxHash
    );
    // emitted if the recipient should receive crypto in the target blockchain
    event TransferCryptoToOtherBlockchainUser(
        uint256 blockchain,
        address sender,
        uint256 RBCAmountIn,
        uint256 amountSpent,
        string newAddress,
        uint256 cryptoOutMin,
        address[] path
    );
    // emitted if the recipient should receive tokens in the target blockchain
    event TransferTokensToOtherBlockchainUser(
        uint256 blockchain,
        address sender,
        uint256 RBCAmountIn,
        uint256 amountSpent,
        string newAddress,
        uint256 tokenOutMin,
        address[] path
    );

    /**
     * @param blockchain Number of blockchain
     * @param tokenInAmount Maximum amount of a token being sold
     * @param firstPath Path used for swapping tokens to *RBC (tokenIn address,.., *RBC addres)
     * @param secondPath Path used for swapping *RBC to tokenOut (*RBC address,.., tokenOut address)
     * @param exactRBCtokenOut Exact amount of RBC to get after first swap
     * @param tokenOutMin Minimal amount of tokens (or crypto) to get after second swap
     * @param newAddress Address in the blockchain to which the user wants to transfer
     * @param swapToCrypto This must be _true_ if swapping tokens to desired blockchain's crypto
     */
    struct swapToParams {
        uint256 blockchain;
        uint256 tokenInAmount;
        address[] firstPath;
        address[] secondPath;
        uint256 exactRBCtokenOut;
        uint256 tokenOutMin;
        string newAddress;
        bool swapToCrypto;
    }

    /**
     * @param user User address // "newAddress" from event
     * @param amountWithFee Amount of tokens with included fees to transfer from the pool // "RBCAmountIn" from event
     * @param amountOutMin Minimal amount of tokens to get after second swap // "tokenOutMin" from event
     * @param path Path used for a second swap // "secondPath" from event
     * @param originalTxHash Hash of transaction from other network, on which swap was called
     * @param concatSignatures Concatenated string of signature bytes for verification of transaction
     */
    struct swapFromParams {
        address user;
        uint256 amountWithFee;
        uint256 amountOutMin;
        address[] path;
        bytes32 originalTxHash;
        bytes concatSignatures;
    }

    /**
     * @dev throws if transaction sender is not in owner role
     */
    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Caller is not in owner role"
        );
        _;
    }

    /**
     * @dev throws if transaction sender is not in owner or manager role
     */
    modifier onlyOwnerAndManager() {
        require(
            hasRole(OWNER_ROLE, _msgSender()) ||
                hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not in owner or manager role"
        );
        _;
    }

    /**
     * @dev throws if transaction sender is not in relayer role
     */
    modifier onlyRelayer() {
        require(
            hasRole(RELAYER_ROLE, _msgSender()),
            "swapContract: Caller is not in relayer role"
        );
        _;
    }

    /**
     * @dev Performs check before swap*ToOtherBlockchain-functions and emits events
     * @param params The swapToParams structure
     * @param value The msg.value
     */
    modifier TransferTo(swapToParams memory params, uint256 value) {
        require(
            bytes(params.newAddress).length > 0,
            "swapContract: No destination address provided"
        );
        require(
            existingOtherBlockchain[params.blockchain] &&
                params.blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            params.firstPath.length > 0,
            "swapContract: firsPath length must be greater than 1"
        );
        require(
            params.secondPath.length > 0,
            "swapContract: secondPath length must be greater than 1"
        );
        require(
            params.firstPath[params.firstPath.length - 1] ==
                RubicAddresses[numOfThisBlockchain],
            "swapContract: the last address in the firstPath must be Rubic"
        );
        require(
            params.secondPath[0] == RubicAddresses[params.blockchain],
            "swapContract: the first address in the secondPath must be Rubic"
        );
        require(
            params.exactRBCtokenOut >= minTokenAmount,
            "swapContract: Not enough amount of tokens"
        );
        require(
            params.exactRBCtokenOut < maxTokenAmount,
            "swapContract: Too many RBC requested"
        );
        require(
            value >= blockchainCryptoFee[params.blockchain],
            "swapContract: Not enough crypto provided"
        );
        _;
        if (params.swapToCrypto) {
            emit TransferCryptoToOtherBlockchainUser(
                params.blockchain,
                _msgSender(),
                params.exactRBCtokenOut,
                params.tokenInAmount,
                params.newAddress,
                params.tokenOutMin,
                params.secondPath
            );
        } else {
            emit TransferTokensToOtherBlockchainUser(
                params.blockchain,
                _msgSender(),
                params.exactRBCtokenOut,
                params.tokenInAmount,
                params.newAddress,
                params.tokenOutMin,
                params.secondPath
            );
        }
    }

    /**
     * @dev Performs check before swap*ToUser-functions
     * @param params The swapFromParams structure
     */
    modifier TransferFrom(swapFromParams memory params) {
        require(
            params.amountWithFee >= minTokenAmount,
            "swapContract: Not enough amount of tokens"
        );
        require(
            params.amountWithFee < maxTokenAmount,
            "swapContract: Too many RBC requested"
        );
        require(
            params.path.length > 0,
            "swapContract: path length must be greater than 1"
        );
        require(
            params.path[0] == RubicAddresses[numOfThisBlockchain],
            "swapContract: the first address in the path must be Rubic"
        );
        require(
            params.user != address(0),
            "swapContract: Address cannot be zero address"
        );
        require(
            params.concatSignatures.length % SIGNATURE_LENGTH == 0,
            "swapContract: Signatures lengths must be divisible by 65"
        );
        require(
            params.concatSignatures.length / SIGNATURE_LENGTH >=
                minConfirmationSignatures,
            "swapContract: Not enough signatures passed"
        );

        _processTransaction(
            params.user,
            params.amountWithFee,
            params.originalTxHash,
            params.concatSignatures
        );
        _;
    }

    /**
     * @dev Constructor of contract
     * @param _numOfThisBlockchain Number of blockchain where contract is deployed
     * @param _numsOfOtherBlockchains List of blockchain number that is supported by bridge
     * @param tokenLimits A list where 0 element is minTokenAmount and 1 is maxTokenAmount
     * @param _maxGasPrice Maximum gas price on which relayer nodes will operate
     * @param _minConfirmationBlocks Minimal amount of blocks for confirmation on validator nodes
     * @param _refundSlippage Slippage represented as hundredths of a bip, i.e. 1e-6 that will be used on refund
     * @param _RubicAddresses Addresses of Rubic in different blockchains
     */
    constructor(
        uint128 _numOfThisBlockchain,
        uint128[] memory _numsOfOtherBlockchains,
        uint256[] memory tokenLimits,
        uint256 _maxGasPrice,
        uint256 _minConfirmationBlocks,
        uint256 _refundSlippage,
        IUniswapV2Router02 _blockchainRouter,
        address[] memory _RubicAddresses
    ) {
        for (uint256 i = 0; i < _numsOfOtherBlockchains.length; i++) {
            require(
                _numsOfOtherBlockchains[i] != _numOfThisBlockchain,
                "swapContract: Number of this blockchain is in array of other blockchains"
            );
            existingOtherBlockchain[_numsOfOtherBlockchains[i]] = true;
        }

        for (uint256 i = 0; i < _RubicAddresses.length; i++) {
            RubicAddresses[i + 1] = _RubicAddresses[i];
        }

        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");

        numOfThisBlockchain = _numOfThisBlockchain;
        minTokenAmount = tokenLimits[0];
        maxTokenAmount = tokenLimits[1];
        maxGasPrice = _maxGasPrice;
        refundSlippage = _refundSlippage;
        minConfirmationBlocks = _minConfirmationBlocks;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        blockchainRouter = _blockchainRouter;

        IERC20(RubicAddresses[_numOfThisBlockchain]).safeApprove(
            address(_blockchainRouter),
            type(uint256).max
        );
    }

    /**
     * @dev Returns true if blockchain of passed id is registered to swap
     * @param blockchain number of blockchain
     */
    function getOtherBlockchainAvailableByNum(uint256 blockchain)
        external
        view
        returns (bool)
    {
        return existingOtherBlockchain[blockchain];
    }

    function _processTransaction(
        address user,
        uint256 amountWithFee,
        bytes32 originalTxHash,
        bytes memory concatSignatures
    ) private {
        bytes32 hashedParams = getHashPacked(
            user,
            amountWithFee,
            originalTxHash
        );
        uint256 statusCode = processedTransactions[originalTxHash].statusCode;
        bytes32 savedHash = processedTransactions[originalTxHash].hashedParams;
        require(
            statusCode == 0 && savedHash != hashedParams,
            "swapContract: Transaction already processed"
        );

        uint256 signaturesCount = concatSignatures.length /
            uint256(SIGNATURE_LENGTH);
        address[] memory validatorAddresses = new address[](signaturesCount);
        for (uint256 i = 0; i < signaturesCount; i++) {
            address validatorAddress = ecOffsetRecover(
                hashedParams,
                concatSignatures,
                i * SIGNATURE_LENGTH
            );
            require(
                isValidator(validatorAddress),
                "swapContract: Validator address not in whitelist"
            );
            for (uint256 j = 0; j < i; j++) {
                require(
                    validatorAddress != validatorAddresses[j],
                    "swapContract: Validator address is duplicated"
                );
            }
            validatorAddresses[i] = validatorAddress;
        }
        processedTransactions[originalTxHash].hashedParams = hashedParams;
        processedTransactions[originalTxHash].statusCode = 1;
    }

    /**
     * @dev Transfers tokens from sender to the contract.
     * User calls this function when he wants to transfer tokens to another blockchain.
     * @notice User must have approved tokenInAmount of tokenIn
     */
    function swapTokensToOtherBlockchain(swapToParams memory params)
        external
        payable
        whenNotPaused
        TransferTo(params, msg.value)
    {
        IERC20 tokenIn = IERC20(params.firstPath[0]);
        if (params.firstPath.length > 1) {
            tokenIn.safeTransferFrom(
                msg.sender,
                address(this),
                params.tokenInAmount
            );
            tokenIn.safeApprove(address(blockchainRouter), 0);
            tokenIn.safeApprove(
                address(blockchainRouter),
                params.tokenInAmount
            );
            uint256[] memory amounts = blockchainRouter
                .swapTokensForExactTokens(
                    params.exactRBCtokenOut,
                    params.tokenInAmount,
                    params.firstPath,
                    blockchainPool,
                    block.timestamp
                );
            tokenIn.safeTransfer(
                _msgSender(),
                params.tokenInAmount - amounts[0]
            );
            params.tokenInAmount = amounts[0];
        } else {
            tokenIn.safeTransferFrom(
                msg.sender,
                blockchainPool,
                params.exactRBCtokenOut
            );
        }
    }

    /**
     * @dev Transfers tokens from sender to the contract.
     * User calls this function when he wants to transfer tokens to another blockchain.
     * @notice User must have approved tokenInAmount of tokenIn
     */
    function swapCryptoToOtherBlockchain(swapToParams memory params)
        external
        payable
        whenNotPaused
        TransferTo(params, msg.value)
    {
        uint256 cryptoWithoutFee = msg.value -
            blockchainCryptoFee[params.blockchain];
        uint256[] memory amounts = blockchainRouter.swapETHForExactTokens{
            value: cryptoWithoutFee
        }(
            params.exactRBCtokenOut,
            params.firstPath,
            blockchainPool,
            block.timestamp
        );
        params.tokenInAmount = amounts[0];
        bool success = payable(_msgSender()).send(
            cryptoWithoutFee - amounts[0]
        );
        require(success, "swapContract: crypto transfer back to caller failed");
    }

    /**
     * @dev Transfers tokens to end user in current blockchain
     */
    function swapTokensToUserWithFee(swapFromParams memory params)
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        uint256 amountWithoutFee = FullMath.mulDiv(
            params.amountWithFee,
            1e6 - feeAmountOfBlockchain[numOfThisBlockchain],
            1e6
        );

        IERC20 RBCToken = IERC20(params.path[0]);

        if (params.path.length == 1) {
            RBCToken.safeTransferFrom(
                blockchainPool,
                params.user,
                amountWithoutFee
            );
            RBCToken.safeTransferFrom(
                blockchainPool,
                address(this),
                params.amountWithFee - amountWithoutFee
            );
        } else {
            RBCToken.safeTransferFrom(
                blockchainPool,
                address(this),
                params.amountWithFee
            );
            blockchainRouter.swapExactTokensForTokens(
                amountWithoutFee,
                params.amountOutMin,
                params.path,
                params.user,
                block.timestamp
            );
        }
        emit TransferFromOtherBlockchain(
            params.user,
            params.amountWithFee,
            amountWithoutFee,
            params.originalTxHash
        );
    }

    /**
     * @dev Transfers tokens to end user in current blockchain
     */
    function swapCryptoToUserWithFee(swapFromParams memory params)
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        uint256 amountWithoutFee = FullMath.mulDiv(
            params.amountWithFee,
            1e6 - feeAmountOfBlockchain[numOfThisBlockchain],
            1e6
        );

        IERC20 RBCToken = IERC20(params.path[0]);
        RBCToken.safeTransferFrom(
            blockchainPool,
            address(this),
            params.amountWithFee
        );
        blockchainRouter.swapExactTokensForETH(
            amountWithoutFee,
            params.amountOutMin,
            params.path,
            params.user,
            block.timestamp
        );
        emit TransferFromOtherBlockchain(
            params.user,
            params.amountWithFee,
            amountWithoutFee,
            params.originalTxHash
        );
    }

    /**
     * @dev Swaps RBC from pool to initially spent by user tokens and transfers him
     * @notice There is used the same structure as in other similar functions but amountOutMin should be
     * equal to the amount of tokens initially spent by user (we are refunding them), AmountWithFee should
     * be equal to the amount of RBC tokens that the pool got after the first swap (RBCAmountIn in the event)
     * hashedParams of this originalTxHash
     */
    function refundTokensToUser(swapFromParams memory params)
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        IERC20 RBCToken = IERC20(params.path[0]);

        if (params.path.length == 1) {
            RBCToken.safeTransferFrom(
                blockchainPool,
                params.user,
                params.amountOutMin
            );
            emit userRefunded(
                params.user,
                params.amountOutMin,
                params.amountOutMin,
                params.originalTxHash
            );
        } else {
            uint256 amountIn = FullMath.mulDiv(
                params.amountWithFee,
                1e6 + refundSlippage,
                1e6
            );

            RBCToken.safeTransferFrom(blockchainPool, address(this), amountIn);

            uint256 RBCSpent = blockchainRouter.swapTokensForExactTokens(
                params.amountOutMin,
                amountIn,
                params.path,
                params.user,
                block.timestamp
            )[0];

            RBCToken.safeTransfer(blockchainPool, amountIn - RBCSpent);
            emit userRefunded(
                params.user,
                RBCSpent,
                RBCSpent,
                params.originalTxHash
            );
        }
    }

    function refundCryptoToUser(swapFromParams memory params)
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        IERC20 RBCToken = IERC20(params.path[0]);

        uint256 amountIn = FullMath.mulDiv(
            params.amountWithFee,
            1e6 + refundSlippage,
            1e6
        );

        RBCToken.safeTransferFrom(blockchainPool, address(this), amountIn);

        uint256 RBCSpent = blockchainRouter.swapTokensForExactETH(
            params.amountOutMin,
            amountIn,
            params.path,
            params.user,
            block.timestamp
        )[0];

        RBCToken.safeTransfer(blockchainPool, amountIn - RBCSpent);
        emit userRefunded(
            params.user,
            RBCSpent,
            RBCSpent,
            params.originalTxHash
        );
    }

    // OTHER BLOCKCHAIN MANAGEMENT
    /**
     * @dev Registers another blockchain for availability to swap
     * @param numOfOtherBlockchain number of blockchain
     */
    function addOtherBlockchain(uint128 numOfOtherBlockchain)
        external
        onlyOwner
    {
        require(
            numOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            !existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = true;
    }

    /**
     * @dev Unregisters another blockchain for availability to swap
     * @param numOfOtherBlockchain number of blockchain
     */
    function removeOtherBlockchain(uint128 numOfOtherBlockchain)
        external
        onlyOwner
    {
        require(
            existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = false;
    }

    /**
     * @dev Change existing blockchain id
     * @param oldNumOfOtherBlockchain number of existing blockchain
     * @param newNumOfOtherBlockchain number of new blockchain
     */
    function changeOtherBlockchain(
        uint128 oldNumOfOtherBlockchain,
        uint128 newNumOfOtherBlockchain
    ) external onlyOwner {
        require(
            oldNumOfOtherBlockchain != newNumOfOtherBlockchain,
            "swapContract: Cannot change blockchains with same number"
        );
        require(
            newNumOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            existingOtherBlockchain[oldNumOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        require(
            !existingOtherBlockchain[newNumOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );

        existingOtherBlockchain[oldNumOfOtherBlockchain] = false;
        existingOtherBlockchain[newNumOfOtherBlockchain] = true;
    }

    /**
     * @dev Changes/Set Router address
     * @param _router the new Router address
     */

    function setRouter(IUniswapV2Router02 _router)
        external
        onlyOwnerAndManager
    {
        blockchainRouter = _router;
    }

    /**
     * @dev Changes/Set Pool address
     * @param _poolAddress the new Pool address
     */

    function setPoolAddress(address _poolAddress) external onlyOwnerAndManager {
        blockchainPool = _poolAddress;
    }

    // FEE MANAGEMENT

    /**
     * @dev Sends collected crypto fee to the owner
     */
    function collectCryptoFee() external onlyOwner {
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "swapContract: fail collecting fee");
    }

    /**
     * @dev Sends collected token fee to the owner
     */
    function collectTokenFee() external onlyOwner {
        IERC20(RubicAddresses[numOfThisBlockchain]).safeTransfer(
            msg.sender,
            IERC20(RubicAddresses[numOfThisBlockchain]).balanceOf(address(this))
        );
    }

    /**
     * @dev Changes fee values for blockchains in feeAmountOfBlockchain variables
     * @notice fee is represented as hundredths of a bip, i.e. 1e-6
     * @param _blockchainNum Existing number of blockchain
     * @param feeAmount Fee amount to substruct from transfer amount
     */
    function setFeeAmountOfBlockchain(uint128 _blockchainNum, uint256 feeAmount)
        external
        onlyOwnerAndManager
    {
        feeAmountOfBlockchain[_blockchainNum] = feeAmount;
    }

    /**
     * @dev Changes crypto fee values for blockchains in blockchainCryptoFee variables
     * @param _blockchainNum Existing number of blockchain
     * @param feeAmount Fee amount that must be sent calling transferToOtherBlockchain
     */
    function setCryptoFeeOfBlockchain(uint128 _blockchainNum, uint256 feeAmount)
        external
        onlyOwnerAndManager
    {
        blockchainCryptoFee[_blockchainNum] = feeAmount;
    }

    /**
     * @dev Changes the address of Rubic in the certain blockchain
     * @param _blockchainNum Existing number of blockchain
     * @param _RubicAddress The Rubic address
     */
    function setRubicAddressOfBlockchain(
        uint128 _blockchainNum,
        address _RubicAddress
    ) external onlyOwnerAndManager {
        RubicAddresses[_blockchainNum] = _RubicAddress;
        if (_blockchainNum == numOfThisBlockchain) {
            if (
                IERC20(_RubicAddress).allowance(
                    address(this),
                    address(blockchainRouter)
                ) != 0
            ) {
                IERC20(_RubicAddress).safeApprove(address(blockchainRouter), 0);
            }
            IERC20(_RubicAddress).safeApprove(
                address(blockchainRouter),
                type(uint256).max
            );
        }
    }

    // VALIDATOR CONFIRMATIONS MANAGEMENT

    /**
     * @dev Changes requirement for minimal amount of signatures to validate on transfer
     * @param _minConfirmationSignatures Number of signatures to verify
     */
    function setMinConfirmationSignatures(uint256 _minConfirmationSignatures)
        external
        onlyOwner
    {
        require(
            _minConfirmationSignatures > 0,
            "swapContract: At least 1 confirmation can be set"
        );
        minConfirmationSignatures = _minConfirmationSignatures;
    }

    /**
     * @dev Changes requirement for minimal token amount on transfers
     * @param _minTokenAmount Amount of tokens
     */
    function setMinTokenAmount(uint256 _minTokenAmount)
        external
        onlyOwnerAndManager
    {
        minTokenAmount = _minTokenAmount;
    }

    /**
     * @dev Changes requirement for maximum token amount on transfers
     * @param _maxTokenAmount Amount of tokens
     */
    function setMaxTokenAmount(uint256 _maxTokenAmount)
        external
        onlyOwnerAndManager
    {
        maxTokenAmount = _maxTokenAmount;
    }

    /**
     * @dev Changes parameter of maximum gas price on which relayer nodes will operate
     * @param _maxGasPrice Price of gas in wei
     */
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwnerAndManager {
        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");
        maxGasPrice = _maxGasPrice;
    }

    /**
     * @dev Changes requirement for minimal amount of block to consider tx confirmed on validator
     * @param _minConfirmationBlocks Amount of blocks
     */

    function setMinConfirmationBlocks(uint256 _minConfirmationBlocks)
        external
        onlyOwnerAndManager
    {
        minConfirmationBlocks = _minConfirmationBlocks;
    }

    function setRefundSlippage(uint256 _refundSlippage)
        external
        onlyOwnerAndManager
    {
        refundSlippage = _refundSlippage;
    }

    /**
     * @dev Transfers permissions of contract ownership.
     * Will setup new owner and one manager on contract.
     * Main purpose of this function is to transfer ownership from deployer account ot real owner
     * @param newOwner Address of new owner
     * @param newManager Address of new manager
     */
    function transferOwnerAndSetManager(address newOwner, address newManager)
        external
        onlyOwner
    {
        require(
            newOwner != _msgSender(),
            "swapContract: New owner must be different than current"
        );
        require(
            newOwner != address(0x0),
            "swapContract: Owner cannot be zero address"
        );
        require(
            newManager != address(0x0),
            "swapContract: Owner cannot be zero address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(OWNER_ROLE, newOwner);
        _setupRole(MANAGER_ROLE, newManager);
        renounceRole(OWNER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Pauses transfers of tokens on contract
     */
    function pauseExecution() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes transfers of tokens on contract
     */
    function continueExecution() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to check if address is belongs to owner role
     * @param account Address to check
     */
    function isOwner(address account) public view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    /**
     * @dev Function to check if address is belongs to manager role
     * @param account Address to check
     */
    function isManager(address account) public view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    /**
     * @dev Function to check if address is belongs to relayer role
     * @param account Address to check
     */
    function isRelayer(address account) public view returns (bool) {
        return hasRole(RELAYER_ROLE, account);
    }

    /**
     * @dev Function to check if address is belongs to validator role
     * @param account Address to check
     *
     */
    function isValidator(address account) public view returns (bool) {
        return hasRole(VALIDATOR_ROLE, account);
    }

    /**
     * @dev Function changes values associated with certain originalTxHash
     * @param originalTxHash Transaction hash to change
     * @param statusCode Associated status: 0-Not processed, 1-Processed, 2-Reverted
     * @param hashedParams Hashed params with which the initial transaction was executed
     */
    function changeTxStatus(
        bytes32 originalTxHash,
        uint256 statusCode,
        bytes32 hashedParams
    ) external onlyRelayer {
        require(
            statusCode != 0,
            "swapContract: you cannot set the statusCode to 0"
        );
        require(
            processedTransactions[originalTxHash].statusCode != 1,
            "swapContract: transaction with this originalTxHash has already been set as succeed"
        );
        processedTransactions[originalTxHash].statusCode = statusCode;
        processedTransactions[originalTxHash].hashedParams = hashedParams;
    }

    /**
     * @dev Plain fallback function to receive crypto
     */
    receive() external payable {}
}
