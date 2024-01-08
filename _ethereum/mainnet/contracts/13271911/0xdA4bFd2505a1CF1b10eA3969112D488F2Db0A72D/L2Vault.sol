// SPDX-License-Identifier: MIT
// @unsupported: ovm

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transfered by external event-based system to another network.
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

//@title: Composable Finance L2 ERC20 Vault
contract L2Vault is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    uint256 nonce;
    uint256 public minFee;
    uint256 public maxFee;
    uint256 public minTransferDelay;
    uint256 public maxTransferDelay;
    uint256 public feeThreshold;
    uint256 public transferLockupTime;
    address public feeAddress;
    bool public paused;

    uint256 constant feeFactor = 10000;

    mapping(bytes32 => bool) public hasBeenWithdrawed;
    mapping(bytes32 => bool) public hasBeenUnlocked;
    mapping(bytes32 => bool) public hasBeenCompleted;

    bytes32 public lastWithdrawID;
    bytes32 public lastUnlockID;

    mapping(address => uint256) public lastTransfer;
    mapping(uint256 => mapping(address => address)) public remoteTokenAddress; // remoteTokenAddress[networkID][addressHere] = addressThere
    mapping(address => uint256) public inTransferFunds;

    mapping(address => uint256) public maxAssetTransferSize;
    mapping(address => uint256) public minAssetTransferSize;

    struct DepositInfo {
        address token;
        uint256 amount;
    }
    mapping(bytes32 => DepositInfo) public deposits;

    event DepositCompleted(
        address indexed account,
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 remoteNetworkID,
        address destination,
        uint256 value,
        bytes32 uniqueId,
        uint256 transferDelay
    );
    event TokenAdded(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 maxTransferSize,
        uint256 minTransferSize
    );
    event TokenRemoved(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID
    );
    event AssetMinTransferSizeChanged(
        address indexed erc20,
        uint256 newMinSize
    );
    event AssetMaxTransferSizeChanged(
        address indexed erc20,
        uint256 newMaxSize
    );
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinTransferDelayChanged(uint256 newMinTransferDelay);
    event MaxTransferDelayChanged(uint256 newMaxTransferDelay);
    event ThresholdFeeChanged(uint256 newFeeThreshold);
    event FeeAddressChanged(address feeAddress);
    event WithdrawalCompleted(
        address indexed accountTo,
        uint256 amount,
        uint256 receivedAmount,
        uint256 feeAmount,
        address indexed tokenAddress,
        bytes32 indexed uniqueId
    );
    event LiquidityMoved(
        address indexed _owner,
        address indexed _to,
        uint256 amount
    );
    event FundsUnlocked(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        bytes32 indexed uniqueId
    );
    event TransferFundsUnlocked(
        address indexed tokenAddress,
        uint256 amount,
        bytes32 uniqueId
    );
    event LockupTimeChanged(
        address indexed _owner,
        uint256 _oldVal,
        uint256 _newVal,
        string valType
    );
    event Pause(address admin);
    event Unpause(address admin);
    event FeeTaken(
        address indexed _owner,
        address indexed _user,
        address indexed _token,
        uint256 _amount,
        uint256 _fee,
        bytes32 uniqueId
    );

    function initialize(address _feeAddress) public initializer {
        nonce = 0;
        minFee = 25; // 0.25%
        maxFee = 400; // 4%
        minTransferDelay = 0;
        maxTransferDelay = 1 days;
        feeThreshold = 50; // 50% of liquidity
        transferLockupTime = 5 minutes;
        __ReentrancyGuard_init();
        __Ownable_init();
        feeAddress = _feeAddress;
    }

    function _generateId(uint256 destinationId) private returns (bytes32) {
        uint256 chainId = 0;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encodePacked(
                    block.number,
                    address(this),
                    chainId,
                    destinationId,
                    nonce++
                )
            );
    }

    // @notice: Adds a supported token to the contract, allowing for anyone to deposit their tokens.
    // @param tokenAddress  SC address of the ERC20 token to add to supported tokens

    function addSupportedToken(
        address tokenAddress,
        address tokenAddressRemote,
        uint256 remoteNetworkID,
        uint256 maxTransferSize,
        uint256 minTransferSize
    ) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAddressRemote != address(0), "Invalid token address");
        require(remoteNetworkID > 0, "Invalid network ID");
        require(
            maxTransferSize > minTransferSize,
            "Max transfer size must be bigger than min"
        );

        remoteTokenAddress[remoteNetworkID][tokenAddress] = tokenAddressRemote;

        maxAssetTransferSize[tokenAddress] = maxTransferSize;
        minAssetTransferSize[tokenAddress] = minTransferSize;

        emit TokenAdded(
            tokenAddress,
            tokenAddressRemote,
            remoteNetworkID,
            maxTransferSize,
            minTransferSize
        );
    }

    // @notice: removes supported token from the contract, avoiding new deposits and withdrawals.
    // @param tokenAddress  SC address of the ERC20 token to remove from supported tokens

    function removeSupportedToken(address tokenAddress, uint256 remoteNetworkID)
        external
        onlyOwner
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
    {
        emit TokenRemoved(
            tokenAddress,
            remoteTokenAddress[remoteNetworkID][tokenAddress],
            remoteNetworkID
        );
        delete remoteTokenAddress[remoteNetworkID][tokenAddress];
    }

    function setAssetMinTransferSize(address tokenAddress, uint256 _size)
        external
        onlyOwner
    {
        minAssetTransferSize[tokenAddress] = _size;
        emit AssetMinTransferSizeChanged(tokenAddress, _size);
    }

    function setAssetMaxTransferSize(address tokenAddress, uint256 _size)
        external
        onlyOwner
    {
        maxAssetTransferSize[tokenAddress] = _size;
        emit AssetMaxTransferSizeChanged(tokenAddress, _size);
    }

    function setTransferLockupTime(uint256 lockupTime) external onlyOwner {
        emit LockupTimeChanged(
            msg.sender,
            transferLockupTime,
            lockupTime,
            "Transfer"
        );
        transferLockupTime = lockupTime;
    }

    /// @notice External callable function to pause the contract
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Pause(msg.sender);
    }

    /// @notice External callable function to unpause the contract
    function unpause() external onlyOwner {
        paused = false;
        emit Unpause(msg.sender);
    }

    // @notice: Updates the minimum Transfer delay for the relayer
    // @param newMinTransferDelay

    function setMinTransferDelay(uint256 newMinTransferDelay)
        external
        onlyOwner
    {
        require(
            newMinTransferDelay < maxTransferDelay,
            "Min TransferDelay cannot be more than max TransferDelay"
        );

        minTransferDelay = newMinTransferDelay;
        emit MinTransferDelayChanged(newMinTransferDelay);
    }

    // @notice: Updates the maximum TransferDelay
    // @param newMaxTransferDelay

    function setMaxTransferDelay(uint256 newMaxTransferDelay)
        external
        onlyOwner
    {
        require(
            newMaxTransferDelay > minTransferDelay,
            "Max TransferDelay cannot be less than min TransferDelay"
        );

        maxTransferDelay = newMaxTransferDelay;
        emit MaxTransferDelayChanged(newMaxTransferDelay);
    }

    // @notice: Updates the minimum fee
    // @param newMinFee

    function setMinFee(uint256 newMinFee) external onlyOwner {
        require(
            newMinFee < feeFactor,
            "Min fee cannot be more than fee factor"
        );
        require(newMinFee < maxFee, "Min fee cannot be more than max fee");

        minFee = newMinFee;
        emit MinFeeChanged(newMinFee);
    }

    // @notice: Updates the maximum fee
    // @param newMaxFee

    function setMaxFee(uint256 newMaxFee) external onlyOwner {
        require(
            newMaxFee < feeFactor,
            "Max fee cannot be more than fee factor"
        );
        require(newMaxFee > minFee, "Max fee cannot be less than min fee");

        maxFee = newMaxFee;
        emit MaxFeeChanged(newMaxFee);
    }

    // @notice: Updates the fee threshold
    // @param newThresholdFee

    function setThresholdFee(uint256 newThresholdFee) external onlyOwner {
        require(
            newThresholdFee < 100,
            "Threshold fee cannot be more than threshold factor"
        );

        feeThreshold = newThresholdFee;
        emit ThresholdFeeChanged(newThresholdFee);
    }

    // @notice: Updates the account where to send deposit fees
    // @param newFeeAddress

    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), "Invalid fee address");

        feeAddress = newFeeAddress;
        emit FeeAddressChanged(feeAddress);
    }

    // @notice: checks for the current balance of this contract's address on the ERC20 contract
    // @param tokenAddress  SC address of the ERC20 token to get liquidity from

    function getCurrentTokenLiquidity(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return
            IERC20(tokenAddress).balanceOf(address(this)).sub(
                inTransferFunds[tokenAddress]
            );
    }

    // @notice Deposits ERC20 token into vault
    // @param amount amount of tokens to deposit
    // @param tokenAddress  SC address of the ERC20 token to deposit
    // @param destinationAddress  Receiver on the destination layer; if address(0) funds will be sent to msg.sender on the destination layer
    // @param transferDelay delay in seconds for the relayer to execute the transaction
    function depositERC20(
        uint256 amount,
        address tokenAddress,
        address destinationAddress,
        uint256 remoteNetworkID,
        uint256 transferDelay
    )
        external
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
        nonReentrant
        whenNotPaused
    {
        require(amount != 0, "Amount cannot be zero");

        require(
            lastTransfer[msg.sender].add(transferLockupTime) < block.timestamp,
            "Transfer not yet possible"
        );

        require(
            transferDelay >= minTransferDelay,
            "Transfer delay is below the minimum required"
        );

        require(
            transferDelay <= maxTransferDelay,
            "Transfer delay is below the maximum required"
        );

        require(
            amount <= maxAssetTransferSize[tokenAddress],
            "Transfer amount is above max transfer size for this asset"
        );

        require(
            amount <= maxAssetTransferSize[tokenAddress],
            "Transfer amount is above max transfer size for this asset"
        );

        require(
            amount >= minAssetTransferSize[tokenAddress],
            "Transfer amount is below min transfer size for this asset"
        );

        uint256 newinTransferFunds = inTransferFunds[tokenAddress].add(amount);
        inTransferFunds[tokenAddress] = newinTransferFunds;

        SafeERC20.safeTransferFrom(
            IERC20(tokenAddress),
            msg.sender,
            address(this),
            amount
        );

        lastTransfer[msg.sender] = block.timestamp;
        bytes32 id = _generateId(remoteNetworkID);
        deposits[id] = DepositInfo({token: tokenAddress, amount: amount});
        address sendTo = destinationAddress;
        if (sendTo == address(0)) {
            sendTo = msg.sender;
        }
        emit DepositCompleted(
            msg.sender,
            tokenAddress,
            remoteTokenAddress[remoteNetworkID][tokenAddress],
            remoteNetworkID,
            sendTo,
            amount,
            id,
            transferDelay
        );
    }

    function calculateFeePercentage(address tokenAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 tokenLiquidity = getCurrentTokenLiquidity(tokenAddress);

        if (tokenLiquidity == 0) {
            return maxFee;
        }

        if ((amount.mul(100)).div(tokenLiquidity) > feeThreshold) {
            // Flat fee since it's above threshold
            return maxFee;
        }

        uint256 maxTransfer = tokenLiquidity.mul(feeThreshold).div(100);
        uint256 percentTransfer = amount.mul(100).div(maxTransfer);

        return
            percentTransfer.mul(maxFee.sub(minFee)).add(minFee.mul(100)).div(
                100
            );
    }

    // @notice: method called by the relayer to release funds
    // @param accountTo eth adress to send the withdrawal tokens
    function withdrawTo(
        address accountTo,
        uint256 amount,
        address tokenAddress,
        uint256 remoteNetworkID,
        bytes32 id
    )
        external
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
        nonReentrant
        onlyOwner
        whenNotPaused
    {
        require(hasBeenWithdrawed[id] == false, "Already withdrawed");
        hasBeenWithdrawed[id] = true;
        lastWithdrawID = id;

        uint256 fee = calculateFeePercentage(tokenAddress, amount);
        uint256 feeAbsolute = amount.mul(fee).div(feeFactor);
        uint256 withdrawAmount = amount.sub(feeAbsolute);

        require(
            getCurrentTokenLiquidity(tokenAddress) >= amount,
            "Not enough tokens on balance"
        );

        SafeERC20.safeTransfer(IERC20(tokenAddress), accountTo, withdrawAmount);

        if (feeAbsolute > 0) {
            SafeERC20.safeTransfer(
                IERC20(tokenAddress),
                feeAddress,
                feeAbsolute
            );
            emit FeeTaken(
                msg.sender,
                accountTo,
                tokenAddress,
                amount,
                feeAbsolute,
                id
            );
        }

        emit WithdrawalCompleted(
            accountTo,
            amount,
            withdrawAmount,
            feeAbsolute,
            tokenAddress,
            id
        );
    }

    /**
     * @notice Will be called once the contract is paused and token's available liquidity will be manually moved back to L1
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */
    function saveFunds(address _token, address _to) external onlyOwner {
        require(paused == true, "contract is not paused");
        require(_token != address(0), "invalid _token address");
        require(_to != address(0), "invalid _to address");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "nothing to transfer");
        SafeERC20.safeTransfer(IERC20(_token), _to, balance);
        emit LiquidityMoved(msg.sender, _to, balance);
    }

    function unlockInTransferFunds(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) public whenNotPaused onlyOwner {
        require(hasBeenCompleted[_id] == false, "Already completed");
        require(
            inTransferFunds[_token] >= _amount,
            "More amount than available"
        );

        require(
            deposits[_id].token == _token && deposits[_id].amount == _amount,
            "Deposit not registered"
        );

        hasBeenCompleted[_id] = true;

        uint256 newinTransferFunds = inTransferFunds[_token].sub(_amount);
        inTransferFunds[_token] = newinTransferFunds;

        emit TransferFundsUnlocked(_token, _amount, _id);
    }

    function unlockFunds(
        address _token,
        address _user,
        uint256 amount,
        bytes32 id
    ) external onlyOwner nonReentrant {
        require(hasBeenUnlocked[id] == false, "Already unlocked");
        hasBeenUnlocked[id] = true;
        lastUnlockID = id;

        SafeERC20.safeTransfer(IERC20(_token), _user, amount);
        emit FundsUnlocked(_token, _user, amount, id);

        if (hasBeenCompleted[id] == false) {
            unlockInTransferFunds(_token, amount, id);
        }
    }

    function getRemoteTokenAddress(uint256 _networkID, address _tokenAddress)
        external
        view
        returns (address tokenAddressRemote)
    {
        tokenAddressRemote = remoteTokenAddress[_networkID][_tokenAddress];
    }

    modifier onlySupportedRemoteTokens(
        uint256 networkID,
        address tokenAddress
    ) {
        require(
            remoteTokenAddress[networkID][tokenAddress] != address(0),
            "Unsupported token in this network"
        );
        _;
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }
}
