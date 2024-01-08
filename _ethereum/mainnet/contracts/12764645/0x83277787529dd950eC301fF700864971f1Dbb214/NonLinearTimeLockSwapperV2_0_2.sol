// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ds-hub.sol";
import "./StorageSlotOwnable.sol";
import "./ERC20OnApprove.sol";

import "./NonLinearTimeLockSwapperV2_0_0___2_0_2Storage.sol";

contract NonLinearTimeLockSwapperV2_0_2 is
    NonLinearTimeLockSwapperV2_0_0___2_0_2Storage,
    StorageSlotOwnable,
    DSMath,
    OnApprove
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    modifier onlyValidAddress(address account) {
        require(account != address(0), "zero-address");
        _;
    }

    modifier onlyDeposit(address sourceToken, address account) {
        require(depositAmounts[sourceToken][account] != 0, "no-deposit");
        _;
    }

    modifier onlyMigrationNotStopped() {
        require(!migrationStopped, "migration-stopped");
        _;
    }

    event Deposited(
        address indexed sourceToken,
        address indexed beneficiary,
        uint256 sourceTokenAmount,
        uint256 targetTokenAmount
    );

    event Undeposited(address indexed sourceToken, address indexed beneficiary, uint256 amount, address receiver);

    event Claimed(address indexed sourceToken, address indexed beneficiary, uint256 targetTokenAmount);

    //////////////////////////////////////////
    //
    // kernel
    //
    //////////////////////////////////////////

    function implementationVersion() public view virtual override returns (string memory) {
        return "2.0.2";
    }

    function _initializeKernel(bytes memory data) internal override {
        (address owner_, address token_, address tokenWallet_) = abi.decode(data, (address, address, address));
        _initializeV2(owner_, token_, tokenWallet_);
    }

    function _initializeV2(
        address owner_,
        address token_,
        address tokenWallet_
    ) private onlyValidAddress(owner_) onlyValidAddress(token_) onlyValidAddress(tokenWallet_) {
        _setOwner(owner_);
        token = IERC20(token_);
        tokenWallet = tokenWallet_;

        _registerInterface(OnApprove(this).onApprove.selector);
    }

    //////////////////////////////////////////
    //
    // token wallet
    //
    //////////////////////////////////////////

    function setTokenWallet(address tokenWallet_) external onlyOwner onlyValidAddress(tokenWallet_) {
        tokenWallet = tokenWallet_;
    }

    //////////////////////////////////////////
    //
    // migation
    //
    //////////////////////////////////////////

    /**
     * @dev event is not fired to reduce gas cost
     */
    function setInitialBalances(
        address sourceToken,
        address[] calldata beneficiaries,
        uint256[] calldata amounts
    ) external onlyOwner onlyMigrationNotStopped {
        require(beneficiaries.length == amounts.length, "invalid-length");
        for (uint256 i = 0; i < amounts.length; i++) {
            depositAmounts[sourceToken][beneficiaries[i]] = amounts[i];
        }
    }

    /**
     * @dev event is not fired to reduce gas cost
     */
    function setClaimedAmounts(
        address sourceToken,
        address[] calldata beneficiaries,
        uint256[] calldata amounts
    ) external onlyOwner onlyMigrationNotStopped {
        require(beneficiaries.length == amounts.length, "invalid-length");
        for (uint256 i = 0; i < amounts.length; i++) {
            claimedAmounts[sourceToken][beneficiaries[i]] = amounts[i];
        }
    }

    /**
     * @dev undeposit and transfer source token to `receiver` if not claimed yet
     */
    function undeposit(
        address sourceToken,
        address beneficiary,
        uint256 amount,
        address receiver
    ) public onlyMigrationNotStopped {
        require(msg.sender == beneficiary || msg.sender == owner(), "no-auth");

        uint256 depositAmount = depositAmounts[sourceToken][beneficiary];
        require(depositAmount > 0, "no-deposit");
        require(claimedAmounts[sourceToken][beneficiary] == 0, "already-claimed");

        if (amount == 0) {
            amount = depositAmount;
        }

        require(depositAmount >= amount, "insufficient-deposits");

        depositAmounts[sourceToken][beneficiary] = depositAmount - amount;

        IERC20(sourceToken).safeTransfer(receiver, amount);

        emit Undeposited(sourceToken, beneficiary, amount, receiver);
    }

    function undeposits(
        address[] calldata sourceToken,
        address[] calldata beneficiary,
        uint256[] calldata amount,
        address[] calldata receiver
    ) external {
        uint256 n = sourceToken.length;
        require(beneficiary.length == n, "invalid-length");
        require(amount.length == n, "invalid-length");
        require(receiver.length == n, "invalid-length");

        for (uint256 i = 0; i < n; i++) {
            undeposit(sourceToken[i], beneficiary[i], amount[i], receiver[i]);
        }
    }

    function stopMigration() external onlyOwner {
        migrationStopped = true;
    }

    //////////////////////////////////////////
    //
    // register source token
    //
    //////////////////////////////////////////

    /**
     * @dev register source token with vesting data
     */
    function register(
        address sourceToken,
        uint128 rate,
        uint128 startTime,
        uint256[] memory stepEndTimes,
        uint256[] memory stepRatio
    ) external onlyOwner {
        require(!isRegistered(sourceToken), "duplicate-register");

        require(rate > 0, "invalid-rate");

        require(stepEndTimes.length == stepRatio.length, "invalid-array-length");

        uint256 n = stepEndTimes.length;
        uint256[] memory accStepRatio = new uint256[](n);

        uint256 accRatio;
        for (uint256 i = 0; i < n; i++) {
            accRatio = add(accRatio, stepRatio[i]);
            accStepRatio[i] = accRatio;
        }
        require(accRatio == WAD, "invalid-acc-ratio");

        for (uint256 i = 1; i < n; i++) {
            require(stepEndTimes[i - 1] < stepEndTimes[i], "unsorted-times");
        }

        sourceTokenDatas[sourceToken] = SourceTokeData({
            rate: rate,
            startTime: startTime,
            stepEndTimes: stepEndTimes,
            accStepRatio: accStepRatio
        });
    }

    function isRegistered(address sourceToken) public view returns (bool) {
        return sourceTokenDatas[sourceToken].startTime > 0;
    }

    function getStepEndTimes(address sourceToken) external view returns (uint256[] memory) {
        return sourceTokenDatas[sourceToken].stepEndTimes;
    }

    function getAccStepRatio(address sourceToken) external view returns (uint256[] memory) {
        return sourceTokenDatas[sourceToken].accStepRatio;
    }

    //////////////////////////////////////////
    //
    // source token deposit
    //
    //////////////////////////////////////////

    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(spender == address(this), "invalid-approval");
        require(isRegistered(msg.sender), "unregistered-source-token");

        deposit(msg.sender, owner, amount);

        data;
        return true;
    }

    // deposit sender's token
    function deposit(
        address sourceToken,
        address beneficiary,
        uint256 sourceTokenAmount
    ) public onlyValidAddress(beneficiary) {
        require(isRegistered(sourceToken), "unregistered-source-token");
        require(sourceTokenAmount > 0, "invalid-amount");

        require(msg.sender == address(sourceToken) || msg.sender == beneficiary, "no-auth");

        SourceTokeData storage data = sourceTokenDatas[sourceToken];
        uint256 targetTokenAmount = wmul(sourceTokenAmount, data.rate);

        // update initial balance
        depositAmounts[sourceToken][beneficiary] = depositAmounts[sourceToken][beneficiary].add(sourceTokenAmount);

        // get source token
        IERC20(sourceToken).safeTransferFrom(beneficiary, address(this), sourceTokenAmount);

        // get target token from token wallet
        token.safeTransferFrom(tokenWallet, address(this), targetTokenAmount);

        emit Deposited(sourceToken, beneficiary, sourceTokenAmount, targetTokenAmount);
    }

    //////////////////////////////////////////
    //
    // claim
    //
    //////////////////////////////////////////

    function claim(address sourceToken) public onlyDeposit(sourceToken, msg.sender) {
        uint256 amount = claimable(sourceToken, msg.sender);
        require(amount > 0, "invalid-amount");

        claimedAmounts[sourceToken][msg.sender] = claimedAmounts[sourceToken][msg.sender].add(amount);
        token.safeTransferFrom(tokenWallet, msg.sender, amount);

        emit Claimed(sourceToken, msg.sender, amount);
    }

    function claimTokens(address[] calldata sourceTokens) external {
        for (uint256 i = 0; i < sourceTokens.length; i++) {
            claim(sourceTokens[i]);
        }
    }

    /**
     * @dev get claimable tokens now
     */
    function claimable(address sourceToken, address beneficiary) public view returns (uint256) {
        return claimableAt(sourceToken, beneficiary, block.timestamp);
    }

    /**
     * @dev get claimable tokens at `timestamp`
     */
    function claimableAt(
        address sourceToken,
        address beneficiary,
        uint256 timestamp
    ) public view returns (uint256) {
        require(block.timestamp <= timestamp, "invalid-timestamp");

        SourceTokeData storage sourceTokenData = sourceTokenDatas[sourceToken];

        uint256 totalClaimable = wmul(depositAmounts[sourceToken][beneficiary], sourceTokenData.rate);
        uint256 claimedAmount = claimedAmounts[sourceToken][beneficiary];

        if (timestamp < sourceTokenData.startTime) return 0;
        if (timestamp >= sourceTokenData.stepEndTimes[sourceTokenData.stepEndTimes.length - 1])
            return totalClaimable.sub(claimedAmount);

        uint256 step = getStepAt(sourceToken, timestamp);
        uint256 accRatio = sourceTokenData.accStepRatio[step];

        uint256 claimableAmount = wmul(totalClaimable, accRatio);

        return claimableAmount > claimedAmount ? claimableAmount.sub(claimedAmount) : 0;
    }

    function initialBalance(address sourceToken, address beneficiary) external view returns (uint256) {
        return depositAmounts[sourceToken][beneficiary];
    }

    /**
     * @dev get current step
     */
    function getStep(address sourceToken) public view returns (uint256) {
        return getStepAt(sourceToken, block.timestamp);
    }

    /**
     * @dev get step at `timestamp`
     */
    function getStepAt(address sourceToken, uint256 timestamp) public view returns (uint256) {
        SourceTokeData storage sourceTokenData = sourceTokenDatas[sourceToken];

        require(timestamp >= sourceTokenData.startTime, "not-started");
        uint256 n = sourceTokenData.stepEndTimes.length;
        if (timestamp >= sourceTokenData.stepEndTimes[n - 1]) {
            return n - 1;
        }
        if (timestamp <= sourceTokenData.stepEndTimes[0]) {
            return 0;
        }

        uint256 lo = 1;
        uint256 hi = n - 1;
        uint256 md;

        while (lo < hi) {
            md = (hi + lo + 1) / 2;
            if (timestamp < sourceTokenData.stepEndTimes[md - 1]) {
                hi = md - 1;
            } else {
                lo = md;
            }
        }

        return lo;
    }
}
