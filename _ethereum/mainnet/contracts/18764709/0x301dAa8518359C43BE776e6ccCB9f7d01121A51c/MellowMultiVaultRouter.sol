// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./IMellowMultiVaultRouter.sol";
import "./IERC20RootVault.sol";
import "./IMarginEngine.sol";
import "./IVoltzVault.sol";
import "./MellowMultiVaultRouterStorage.sol";
import "./SafeTransferLib.sol";
import "./FullMath.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1967Proxy.sol";

contract MellowMultiVaultRouter is
    IMellowMultiVaultRouter,
    MellowMultiVaultRouterStorage,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeTransferLib for IERC20Minimal;
    using SafeTransferLib for IWETH;

    uint256 public constant WAD = 1e18;

    uint256 constant WEIGHT_SUM = 100;

    // -------------------  INITIALIZER  -------------------

    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
    // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        IWETH weth_,
        IERC20Minimal token_,
        IERC20RootVault[] memory vaults_
    ) external override initializer {
        require(vaults_.length > 0, "empty vaults");

        _weth = weth_;
        _token = token_;

        for (uint256 i = 0; i < vaults_.length; i++) {
            _addVault(vaults_[i]);
        }

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // -------------------  GETTERS -------------------

    function weth() external view override returns (IWETH) {
        return _weth;
    }

    function token() external view override returns (IERC20Minimal) {
        return _token;
    }

    function getBatchedDeposits(uint256 index)
        external
        view
        override
        returns (BatchedDeposit[] memory)
    {
        if (index >= _vaults.length) {
            BatchedDeposit[] memory emptyDeposits = new BatchedDeposit[](0);
            return emptyDeposits;
        }

        BatchedDeposits storage batchedDeposits = _batchedDeposits[index];

        uint256 activeDeposits = batchedDeposits.size - batchedDeposits.current;
        BatchedDeposit[] memory deposits = new BatchedDeposit[](activeDeposits);

        for (uint256 i = 0; i < activeDeposits; i++) {
            deposits[i] = batchedDeposits.batch[i + batchedDeposits.current];
        }

        return deposits;
    }

    function getLPTokenBalances(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory lpTokenBalances = getRawLPTokenBalances(owner);
        if (!_isRegisteredForAutoRollover[owner]) {
            return lpTokenBalances;
        }

        uint256[]
            memory propagatedAutoRolloverLPTokens = getPropagatedAutoRolloverLPTokens(
                owner
            );
        for (uint256 i = 0; i < _vaults.length; i += 1) {
            lpTokenBalances[i] += propagatedAutoRolloverLPTokens[i];
        }

        return lpTokenBalances;
    }

    function getActiveIndices(address owner)
        external
        view
        override
        returns (uint256[] memory activeIndices)
    {
        uint256[] memory lpTokenBalances = getLPTokenBalances(owner);

        uint256 activeIndicesCnt = 0;
        for (uint256 i = 0; i < _vaults.length; i += 1) {
            if (lpTokenBalances[i] > 0) {
                activeIndicesCnt += 1;
            }
        }

        activeIndices = new uint256[](activeIndicesCnt);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _vaults.length; i += 1) {
            if (lpTokenBalances[i] > 0) {
                activeIndices[currentIndex] = i;
                currentIndex += 1;
            }
        }
    }

    function getVaults()
        external
        view
        override
        returns (IERC20RootVault[] memory)
    {
        return _vaults;
    }

    function isVaultCompleted(uint256 index)
        external
        view
        override
        returns (bool)
    {
        return _isVaultCompleted[index];
    }

    function isVaultPaused(uint256 index)
        external
        view
        override
        returns (bool)
    {
        return _isVaultPaused[index];
    }

    function getVaultMaturity(uint256 vaultIndex)
        public
        view
        override
        returns (uint256)
    {
        uint256 latestMaturity = 0;

        // Get latest maturity of the underlying margin engines
        uint256[] memory subvaultNFTs = _vaults[vaultIndex].subvaultNfts();

        for (uint256 k = 1; k < subvaultNFTs.length; k++) {
            address voltzVault = _vaults[vaultIndex].subvaultAt(k);
            IMarginEngine marginEngine = IVoltzVault(voltzVault).marginEngine();
            uint256 maturity = marginEngine.termEndTimestampWad() / 1e18;
            if (maturity > latestMaturity) {
                latestMaturity = maturity;
            }
        }

        return latestMaturity;
    }

    function getCachedVaultMaturity(uint256 vaultIndex)
        public
        override
        returns (uint256)
    {
        if (_vaultMaturity[vaultIndex] == 0) {
            _vaultMaturity[vaultIndex] = getVaultMaturity(vaultIndex);
        }

        return _vaultMaturity[vaultIndex];
    }

    function getFee() external view override returns (uint256) {
        return _fee;
    }

    function getTotalFee() external view override returns (uint256) {
        return _totalFees;
    }

    function getVaultDepositsCount() external view override returns (uint256) {
        return _vaultDepositsCount;
    }

    // -------------------  CHECKS  -------------------

    function validWeights(uint256[] memory weights)
        public
        view
        override
        returns (bool)
    {
        if (weights.length != _vaults.length) {
            return false;
        }

        uint256 sum = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            if ((_isVaultCompleted[i] || _isVaultPaused[i]) && weights[i] > 0) {
                return false;
            }
            sum += weights[i];
        }

        return sum == WEIGHT_SUM;
    }

    function canWithdrawOrRollover(uint256 vaultIndex, address owner)
        public
        view
        override
        returns (bool)
    {
        if (!(vaultIndex < _vaults.length)) {
            return false;
        }

        if (!_isVaultCompleted[vaultIndex]) {
            return false;
        }

        if (_isVaultPaused[vaultIndex]) {
            return false;
        }

        uint256[]
            memory autoRolloverLpTokens = getPropagatedAutoRolloverLPTokens(
                owner
            );
        if (
            autoRolloverLpTokens[vaultIndex] > 0 &&
            _pendingAutoRolloverDeposits[vaultIndex] > 0
        ) {
            return false;
        }

        return true;
    }

    // -------------------  INTERNAL  -------------------

    function _addVault(IERC20RootVault vault_) internal {
        address[] memory vaultTokens = vault_.vaultTokens();
        require(
            vaultTokens.length == 1 && vaultTokens[0] == address(_token),
            "invalid vault"
        );

        _vaults.push(vault_);
        _token.safeIncreaseAllowanceTo(address(vault_), type(uint256).max);
    }

    function _trackDeposit(
        address author,
        uint256 amount,
        uint256[] memory weights
    ) internal {
        require(validWeights(weights), "invalid weights");

        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 weightedAmount = FullMath.mulDiv(
                amount,
                weights[i],
                WEIGHT_SUM
            );

            if (weightedAmount > 0) {
                BatchedDeposit memory instance = BatchedDeposit({
                    author: author,
                    amount: weightedAmount
                });

                _batchedDeposits[i].batch[_batchedDeposits[i].size] = instance;
                _batchedDeposits[i].size += 1;
                _vaultDepositsCount += 1;
            }
        }
    }

    function getMarginEngineBalance(IERC20RootVault vault)
        internal
        view
        returns (uint256 balance)
    {
        balance = 0;
        uint256[] memory subvaultNfts = vault.subvaultNfts();

        for (uint256 i = 1; i < subvaultNfts.length; i++) {
            address subVault = vault.subvaultAt(i);
            address marginEngine = address(
                IVoltzVault(subVault).marginEngine()
            );
            balance += _token.balanceOf(marginEngine);
        }
    }

    function getRawLPTokenBalances(address owner)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_vaults.length);
        for (uint256 i = 0; i < _vaults.length; i++) {
            balances[i] = _managedLpTokens[owner][i];
        }

        return balances;
    }

    function getRawAutoRolloverLPTokenBalances(address owner)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_vaults.length);
        for (uint256 i = 0; i < _vaults.length; i++) {
            balances[i] = _autoRolloverLpTokens[owner][i];
        }

        return balances;
    }

    // -------------------  SETTERS  -------------------

    function addVault(IERC20RootVault vault_) external override onlyOwner {
        _addVault(vault_);
    }

    function setCompletion(uint256 index, bool completed)
        external
        override
        onlyOwner
    {
        require(index < _vaults.length, "invalid index");
        require(_isVaultCompleted[index] != completed, "Already (un)completed");
        require(
            _batchedDeposits[index].current == _batchedDeposits[index].size,
            "batch non-empty"
        );

        _isVaultCompleted[index] = completed;
    }

    function setPausability(uint256 index, bool paused)
        external
        override
        onlyOwner
    {
        require(index < _vaults.length, "invalid index");
        require(_isVaultPaused[index] != paused, "Already (un)paused");
        require(
            _batchedDeposits[index].current == _batchedDeposits[index].size,
            "batch non-empty"
        );

        _isVaultPaused[index] = paused;
    }

    function setFee(uint256 fee_) external override onlyOwner {
        require(fee_ >= 0, "negative fee");
        for (uint256 i = 0; i < _vaults.length; i++) {
            require(
                _batchedDeposits[i].current == _batchedDeposits[i].size,
                "batch non-empty"
            );
        }
        _fee = fee_;
    }

    function refreshDepositCount() external override {
        uint256 remainingDeposits = 0;
        for (uint256 i = 0; i < _vaults.length; i++) {
            remainingDeposits +=
                _batchedDeposits[i].size -
                _batchedDeposits[i].current;
        }
        _vaultDepositsCount = remainingDeposits;
    }

    // -------------------  DEPOSITS  -------------------

    function depositEth(uint256[] memory weights) public payable override {
        require(address(_token) == address(_weth), "only ETH vaults");
        require(msg.value > _fee, "amount not sufficient");

        propagateAutoRolloverLPTokens();

        // 1. Wrap the ETH into WETH
        uint256 ethPassed = msg.value;
        _weth.deposit{value: ethPassed}();

        // 2. Track the deposit
        uint256 amountAfterFee = ethPassed - _fee;
        _trackDeposit(msg.sender, amountAfterFee, weights);
        _totalFees += _fee;
    }

    function depositEthAndRegisterForAutoRollover(
        uint256[] memory weights,
        bool registration
    ) public payable override {
        depositEth(weights);
        registerForAutoRollover(registration);
    }

    function depositErc20(uint256 amount, uint256[] memory weights)
        public
        override
    {
        propagateAutoRolloverLPTokens();

        // 1. Send the funds from the user to the router
        IERC20Minimal(_token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        require(amount > _fee, "amount not sufficient");
        uint256 amountAfterFee = amount - _fee;

        // 2. Track the deposit
        _trackDeposit(msg.sender, amountAfterFee, weights);
        _totalFees += _fee;
    }

    function depositErc20AndRegisterForAutoRollover(
        uint256 amount,
        uint256[] memory weights,
        bool registration
    ) public override {
        depositErc20(amount, weights);
        registerForAutoRollover(registration);
    }

    // -------------------  BATCH PUSH  -------------------
    function submitAllBatchesForFee() external override {
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (
                _batchedDeposits[i].current < _batchedDeposits[i].size &&
                !(_isVaultCompleted[i] || _isVaultPaused[i])
            ) {
                this.submitBatchForFee(i, 0, msg.sender);
            }
        }
    }

    function submitBatchForFee(
        uint256 index,
        uint256 batchSize,
        address account
    ) public override {
        // 1. Get the full size if batch size is 0 or more than neccessary
        BatchedDeposits storage batchedDeposits = _batchedDeposits[index];
        uint256 remainingDeposits = batchedDeposits.size -
            batchedDeposits.current;
        require(remainingDeposits > 0, "empty batch");
        if (batchSize == 0 || batchSize > remainingDeposits) {
            batchSize = remainingDeposits;
        }

        // 2. Get initial margin engine balance
        uint256 initialBalance = getMarginEngineBalance(_vaults[index]);
        uint256 vaultDepositsCount = _vaultDepositsCount;

        // 3. Submit Batch
        this.submitBatch(index, batchSize);

        // 4. Check if tokens arrived in margin engines
        uint256 afterBalance = getMarginEngineBalance(_vaults[index]);
        require(initialBalance < afterBalance, "deposit not completed");

        // 5. Transfer fees and update deposit count
        uint256 allocatedFee = FullMath.mulDiv(
            _totalFees,
            batchSize,
            vaultDepositsCount
        );
        _totalFees -= allocatedFee;
        _token.safeTransfer(account, allocatedFee);
    }

    function submitBatch(uint256 index, uint256 batchSize) public override {
        BatchedDeposits storage batchedDeposits = _batchedDeposits[index];
        IERC20RootVault vault = _vaults[index];

        uint256 remainingDeposits = batchedDeposits.size -
            batchedDeposits.current;

        // 1. Get the full size if batch size is 0 or more than neccessary
        if (batchSize == 0 || batchSize > remainingDeposits) {
            batchSize = remainingDeposits;
        }

        // 2. Set the local variables
        BatchedDeposit[] memory deposits = new BatchedDeposit[](batchSize);

        // 3. Get the target deposits and aggregate the funds to push
        uint256 fundsToPush = 0;
        for (uint256 i = 0; i < batchSize; i += 1) {
            deposits[i] = batchedDeposits.batch[i + batchedDeposits.current];

            fundsToPush += deposits[i].amount;
        }

        if (fundsToPush > 0) {
            // 4. Distribute the funds to the vaults according to their weights
            uint256 deltaLpTokens = vault.balanceOf(address(this));

            uint256[] memory tokenAmounts = new uint256[](1);
            tokenAmounts[0] = fundsToPush;

            // Deposit to Mellow
            vault.deposit(tokenAmounts, 0, "");

            // Track the delta lp tokens
            deltaLpTokens = vault.balanceOf(address(this)) - deltaLpTokens;

            // 5. Calculate and manage how many LP tokens each user gets
            for (
                uint256 batchIndex = 0;
                batchIndex < batchSize;
                batchIndex += 1
            ) {
                uint256 share = FullMath.mulDiv(
                    deltaLpTokens,
                    deposits[batchIndex].amount,
                    fundsToPush
                );

                _managedLpTokens[deposits[batchIndex].author][index] += share;

                if (_isRegisteredForAutoRollover[deposits[batchIndex].author]) {
                    registerUserVaultForAutoRollover(
                        deposits[batchIndex].author,
                        index,
                        true
                    );
                } else if (deposits[batchIndex].author == address(this)) {
                    updateAutoRolloverExchangeRates(index, share);
                }
            }
        }

        // 6. Advance the iterator
        batchedDeposits.current += batchSize;
        _vaultDepositsCount -= batchSize;
    }

    // -------------------  WITHDRAWALS  -------------------

    function claimLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external override {
        require(canWithdrawOrRollover(index, msg.sender), "Cannot withdraw");

        propagateAutoRolloverLPTokens();
        if (_autoRolloverLpTokens[msg.sender][index] > 0) {
            registerUserVaultForAutoRollover(msg.sender, index, false);
        }

        uint256 balance = _managedLpTokens[msg.sender][index];

        uint256 deltaLpTokens = _vaults[index].balanceOf(address(this));
        _vaults[index].withdraw(
            msg.sender,
            balance,
            minTokenAmounts,
            vaultsOptions
        );

        deltaLpTokens = deltaLpTokens - _vaults[index].balanceOf(address(this));
        if (deltaLpTokens > balance) {
            deltaLpTokens = balance;
        }

        _managedLpTokens[msg.sender][index] -= deltaLpTokens;
    }

    function rolloverLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions,
        uint256[] memory weights
    ) external override {
        require(canWithdrawOrRollover(index, msg.sender), "Cannot rollover");

        propagateAutoRolloverLPTokens();
        if (_autoRolloverLpTokens[msg.sender][index] > 0) {
            registerUserVaultForAutoRollover(msg.sender, index, false);
        }

        uint256 balance = _managedLpTokens[msg.sender][index];
        uint256 deltaLpTokens = _vaults[index].balanceOf(address(this));

        uint256[] memory actualTokenAmounts = _vaults[index].withdraw(
            address(this),
            balance,
            minTokenAmounts,
            vaultsOptions
        );

        deltaLpTokens = deltaLpTokens - _vaults[index].balanceOf(address(this));
        _managedLpTokens[msg.sender][index] -= deltaLpTokens;

        _trackDeposit(msg.sender, actualTokenAmounts[0], weights);
    }

    // -------------------  AUTO-ROLLOVERS  -------------------
    function getPropagatedAutoRolloverLPTokens(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        if (!_isRegisteredForAutoRollover[owner]) {
            return new uint256[](_vaults.length);
        }

        uint256[]
            memory propagatedAutoRolloverLPTokens = getRawAutoRolloverLPTokenBalances(
                owner
            );
        for (uint256 i = 0; i < _autoRolledOverVaults.length; i += 1) {
            uint256 fromVault = _autoRolledOverVaults[i];

            uint256 autoRolloverLPTokens = propagatedAutoRolloverLPTokens[
                fromVault
            ];
            if (
                autoRolloverLPTokens == 0 ||
                _pendingAutoRolloverDeposits[fromVault] > 0
            ) {
                continue;
            }

            for (uint256 toVault = 0; toVault < _vaults.length; toVault += 1) {
                if (_autoRolloverExchangeRatesWad[fromVault][toVault] == 0) {
                    continue;
                }

                propagatedAutoRolloverLPTokens[toVault] += FullMath.mulDiv(
                    autoRolloverLPTokens,
                    _autoRolloverExchangeRatesWad[fromVault][toVault],
                    WAD
                );
            }

            propagatedAutoRolloverLPTokens[fromVault] = 0;
        }

        return propagatedAutoRolloverLPTokens;
    }

    function propagateAutoRolloverLPTokens() internal {
        uint256[]
            memory propagatedAutoRolloverLPTokens = getPropagatedAutoRolloverLPTokens(
                msg.sender
            );
        for (uint256 i = 0; i < _vaults.length; i++) {
            _autoRolloverLpTokens[msg.sender][
                i
            ] = propagatedAutoRolloverLPTokens[i];
        }
    }

    function registerUserVaultForAutoRollover(
        address user,
        uint256 vaultIndex,
        bool registration
    ) internal {
        require(
            _pendingAutoRolloverDeposits[vaultIndex] == 0,
            "pending autorollover deposits"
        );

        if (registration) {
            _managedLpTokens[address(this)][vaultIndex] += _managedLpTokens[
                user
            ][vaultIndex];
            _autoRolloverLpTokens[user][vaultIndex] += _managedLpTokens[user][
                vaultIndex
            ];
            _managedLpTokens[user][vaultIndex] = 0;
        } else {
            _managedLpTokens[address(this)][
                vaultIndex
            ] -= _autoRolloverLpTokens[user][vaultIndex];
            _managedLpTokens[user][vaultIndex] += _autoRolloverLpTokens[user][
                vaultIndex
            ];
            _autoRolloverLpTokens[user][vaultIndex] = 0;
        }
    }

    function updateAutoRolloverExchangeRates(
        uint256 toVault,
        uint256 lpTokensReceived
    ) internal {
        require(
            _batchedAutoRollovers[toVault].current <
                _batchedAutoRollovers[toVault].size,
            "no batched autorollovers"
        );

        // pop first batched auto-rollover
        BatchedAutoRollover memory batchedAutoRollover = _batchedAutoRollovers[
            toVault
        ].batch[_batchedAutoRollovers[toVault].current];
        _batchedAutoRollovers[toVault].current += 1;

        // update auto-rollover exchange rate
        uint256 fromVault = batchedAutoRollover.fromVault;
        _autoRolloverExchangeRatesWad[fromVault][toVault] = FullMath.mulDiv(
            WAD,
            lpTokensReceived,
            batchedAutoRollover.lpTokensAutoRolledOver
        );
        _pendingAutoRolloverDeposits[fromVault] -= 1;

        // propagate auto-rollover exchange rates
        for (uint256 i = 0; i < _autoRolledOverVaults.length; i += 1) {
            uint256 pastAutoRolledOverVault = _autoRolledOverVaults[i];

            uint256 autoRolloverExchangeRateABWad = _autoRolloverExchangeRatesWad[
                    pastAutoRolledOverVault
                ][fromVault];
            if (autoRolloverExchangeRateABWad == 0) {
                continue;
            }

            uint256 autoRolloverExchangeRateBCWad = _autoRolloverExchangeRatesWad[
                    fromVault
                ][toVault];

            _autoRolloverExchangeRatesWad[pastAutoRolledOverVault][
                toVault
            ] += FullMath.mulDiv(
                autoRolloverExchangeRateABWad,
                autoRolloverExchangeRateBCWad,
                WAD
            );

            _autoRolloverExchangeRatesWad[pastAutoRolledOverVault][
                fromVault
            ] = 0;
        }
    }

    function registerForAutoRollover(bool registration) public override {
        require(
            _isRegisteredForAutoRollover[msg.sender] != registration,
            "Already registered"
        );

        propagateAutoRolloverLPTokens();

        for (uint256 i = 0; i < _vaults.length; i += 1) {
            require(
                _autoRolloverLpTokens[msg.sender][i] == 0 ||
                    _pendingAutoRolloverDeposits[i] == 0,
                "pending autorollover deposits"
            );

            require(!_isVaultPaused[i], "Vault paused");
        }

        address user = msg.sender;
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_isVaultAutoRolledOver[i]) {
                continue;
            }

            registerUserVaultForAutoRollover(user, i, registration);
        }

        _isRegisteredForAutoRollover[user] = registration;
    }

    function triggerAutoRollover(uint256 vaultIndex) external override {
        require(_isVaultCompleted[vaultIndex], "Vault not completed");
        require(!_isVaultPaused[vaultIndex], "Vault paused");
        require(!_isVaultAutoRolledOver[vaultIndex], "Vault already ARO");

        if (_managedLpTokens[address(this)][vaultIndex] == 0) {
            return;
        }

        uint256 lpTokensBeforeRollover = _managedLpTokens[address(this)][
            vaultIndex
        ];
        uint256[] memory batchedDepositsSizesBefore = new uint256[](
            _vaults.length
        );
        for (uint256 i = 0; i < _vaults.length; i += 1) {
            batchedDepositsSizesBefore[i] = _batchedDeposits[i].size;
        }

        this.rolloverLPTokens(
            vaultIndex,
            new uint256[](1),
            new bytes[](_vaults[vaultIndex].subvaultNfts().length),
            _autoRolloverWeights
        );
        uint256 lpTokensAfterRollover = _managedLpTokens[address(this)][
            vaultIndex
        ];

        require(lpTokensAfterRollover == 0, "partial rollover");

        BatchedAutoRollover memory batchedAutoRollover = BatchedAutoRollover({
            fromVault: vaultIndex,
            lpTokensAutoRolledOver: lpTokensBeforeRollover -
                lpTokensAfterRollover
        });

        uint256 pendingAutoRolloverDeposits = 0;
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_batchedDeposits[i].size > batchedDepositsSizesBefore[i]) {
                _batchedAutoRollovers[i].batch[
                    _batchedAutoRollovers[i].size
                ] = batchedAutoRollover;
                _batchedAutoRollovers[i].size += 1;

                pendingAutoRolloverDeposits += 1;
            }
        }

        _pendingAutoRolloverDeposits[vaultIndex] = pendingAutoRolloverDeposits;
        _autoRolledOverVaults.push(vaultIndex);
        _isVaultAutoRolledOver[vaultIndex] = true;
    }

    function setAutoRolloverWeights(uint256[] memory autoRolloverWeights)
        external
        override
        onlyOwner
    {
        require(validWeights(autoRolloverWeights), "invalid weights");

        _autoRolloverWeights = new uint256[](_vaults.length);
        for (uint256 i = 0; i < _vaults.length; i += 1) {
            _autoRolloverWeights[i] = autoRolloverWeights[i];
        }
    }

    function totalAutoRolloverLPTokens(uint256 vaultIndex)
        external
        view
        override
        returns (uint256)
    {
        return _managedLpTokens[address(this)][vaultIndex];
    }

    function isRegisteredForAutoRollover(address owner)
        external
        view
        override
        returns (bool)
    {
        return _isRegisteredForAutoRollover[owner];
    }

    function getBatchedAutoRollovers(uint256 index)
        external
        view
        override
        returns (BatchedAutoRollover[] memory)
    {
        if (index >= _vaults.length) {
            return new BatchedAutoRollover[](0);
        }

        BatchedAutoRollovers
            storage batchedAutoRollovers = _batchedAutoRollovers[index];

        uint256 batchedAutoRolloversCount = batchedAutoRollovers.size -
            batchedAutoRollovers.current;
        BatchedAutoRollover[]
            memory autoRolloverDeposits = new BatchedAutoRollover[](
                batchedAutoRolloversCount
            );

        for (uint256 i = 0; i < batchedAutoRolloversCount; i++) {
            autoRolloverDeposits[i] = batchedAutoRollovers.batch[
                i + batchedAutoRollovers.current
            ];
        }

        return autoRolloverDeposits;
    }

    function getAutoRolloverWeights()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _autoRolloverWeights;
    }

    function getAutoRolledOverVaults()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _autoRolledOverVaults;
    }

    function getPendingAutoRolloverDeposits(uint256 vaultIndex)
        external
        view
        override
        returns (uint256)
    {
        return _pendingAutoRolloverDeposits[vaultIndex];
    }

    function getAutoRolloverExchangeRatesWad(uint256 fromVault, uint256 toVault)
        external
        view
        override
        returns (uint256)
    {
        return _autoRolloverExchangeRatesWad[fromVault][toVault];
    }
}
