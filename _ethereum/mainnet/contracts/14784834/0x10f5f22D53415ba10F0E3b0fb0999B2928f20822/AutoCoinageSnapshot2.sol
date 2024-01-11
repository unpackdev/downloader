// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoCoinageSnapshotStorage2.sol";
// import "./console.sol";

import "./AutoRefactorCoinageI.sol";
import "./SeigManagerI.sol";
import "./Layer2RegistryI.sol";

import "./IAutoCoinageSnapshot2.sol";

import "./Counters.sol";
import "./SArrays.sol";
import "./DSMath.sol";

/// @title A snapshot contract that records the amount of staked TON on the tokamak network.
contract AutoCoinageSnapshot2 is AutoCoinageSnapshotStorage2, DSMath, IAutoCoinageSnapshot2 {
    using SArrays for uint256[];
    using Counters for Counters.Counter;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Set the address of seigManager and layer2Registry.
    /// @inheritdoc IAutoCoinageSnapshot2
    function setAddress(address _seigManager, address _layer2Registry) external override  onlyRole(ADMIN_ROLE) {
        require(_seigManager != address(0) && _layer2Registry != address(0) , "zero address");
        seigManager = _seigManager;
        layer2Registry = _layer2Registry;
    }

    /// @notice To support the basic interface of ERC20, set name, symbol, decimals.
    /// @inheritdoc IAutoCoinageSnapshot2
    function setNameSymbolDecimals(string memory name_, string memory symbol_, uint256 decimals_) external override onlyRole(ADMIN_ROLE) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// @notice Managed Layer 2 addresses can be added by the administrator.
    /// @inheritdoc IAutoCoinageSnapshot2
    function addLayer2s(address[] memory _layers) external override onlyRole(ADMIN_ROLE) {

        for (uint256 i = 0; i < _layers.length; i++) {
            if (!existLayer2s[_layers[i]]) {
                existLayer2s[_layers[i]] = true;
                layer2s.push(_layers[i]);
            }
        }
    }

    /// @notice Managed Layer2 address can be deleted by the administrator.
    /// @inheritdoc IAutoCoinageSnapshot2
    function delLayer2(address _layer) external override onlyRole(ADMIN_ROLE) {

        if (existLayer2s[_layer]) {
            existLayer2s[_layer] = false;

            if (layer2s.length > 0) {
                if (layer2s[0] == _layer && layer2s.length == 1) {
                    layer2s.pop();
                } else if (layer2s[0] == _layer) {
                    layer2s[0] = layer2s[layer2s.length - 1];
                    layer2s.pop();
                } else {
                    uint256 maxIndex = layer2s.length - 1;
                    for (uint256 j = maxIndex; j > 0; j--) {
                        if (layer2s[j] == _layer && j < (layer2s.length - 1)) {
                            layer2s[j] = layer2s[layer2s.length - 1];
                            layer2s.pop();
                            break;
                        } else if (layer2s[j] == _layer && j == (layer2s.length - 1)) {
                            layer2s.pop();
                            break;
                        }
                    }
                }
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function addSync(address layer2, address account) public override onlyRole(ADMIN_ROLE) returns (uint256) {

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        address[] memory accounts = needSyncs[layer2];
        for (uint256 i = 0; i < accounts.length; i++) {
            if(accounts[i] == account) return needSyncs[layer2].length;
        }
        needSyncs[layer2].push(account);

        emit AddSync(layer2, account);
        return needSyncs[layer2].length;
    }

    function _factorAt(address layer2, uint256 snapshotId) internal view virtual returns (bool, uint256, uint256) {

        FactorSnapshots storage snapshots = factorSnapshots[layer2];

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 index = snapshots.ids.findIndex(snapshotId);

            if (index == snapshots.ids.length) {
                return (false, 0, 0);
            } else {
                return (true, snapshots.factors[index], snapshots.refactorCounts[index]);
            }
        } else {
            return (false, 0, 0);
        }

    }


    function _getRefactoredCounts(address layer2, address account, uint256 index) internal view
        returns (uint256 refactoredCounts, uint256 remains)
    {
        refactoredCounts = 0;
        remains = 0;
        if (
            account != address(0)
            && accountRefactoredCounts[layer2][account][index] > 0
        ){
            refactoredCounts = accountRefactoredCounts[layer2][account][index];

        } else if (
            account == address(0)
            && totalSupplyRefactoredCounts[layer2][index] > 0
        ){
            refactoredCounts = totalSupplyRefactoredCounts[layer2][index];
        }

        if (
            account != address(0)
            && accountRemains[layer2][account][index] > 0
        ){
            remains = accountRemains[layer2][account][index];

        } else if (
            account != address(0)
            && totalSupplyRemains[layer2][index] > 0
        ){
            remains = totalSupplyRemains[layer2][index];
        }
    }

    function _valueAt(address layer2, uint256 snapshotId, BalanceSnapshots storage snapshots, address account) internal view
        returns (bool, uint256, uint256, uint256)
    {

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 index = snapshots.ids.findIndex(snapshotId);
            if (index == snapshots.ids.length) {
                // return (false, 0, 0, 0);
                if (index > 0) {
                    (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, index-1);
                    return (true, snapshots.balances[index-1], refactoredCounts, remains);
                } else {
                    return (false, 0, 0, 0);
                }
            } else {
                (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, index);
                return (true, snapshots.balances[index], refactoredCounts, remains);
            }
        } else {
            return (false, 0, 0, 0);
        }
    }

    function _balanceOfAt(address layer2, address account, uint256 snapshotId) internal view virtual
        returns (bool, uint256, uint256, uint256)
    {

        (bool snapshotted, uint256 balances, uint256 refactoredCounts, uint256 remains) = _valueAt(layer2, snapshotId, accountBalanceSnapshots[layer2][account], account);

        return (snapshotted, balances, refactoredCounts, remains);
        //return snapshotted ? value : balanceOf(account);
    }

    function _totalSupplyAt(address layer2, uint256 snapshotId) internal view virtual
        returns (bool, uint256, uint256, uint256)
    {
        (bool snapshotted, uint256 balances, uint256 refactoredCounts, uint256 remains)  = _valueAt(layer2, snapshotId, totalSupplySnapshots[layer2], address(0));

        return (snapshotted, balances, refactoredCounts, remains);
        //return snapshotted ? value : totalSupply();
    }

    /// @notice You can calculate the balance with the saved snapshot information.
    /// @inheritdoc IAutoCoinageSnapshot2
    function applyFactor(uint256 v, uint256 refactoredCount, uint256 _factor, uint256 refactorCount) public view override returns (uint256)
    {
        if (v == 0) {
            return 0;
        }

        v = rmul2(v, _factor);

        for (uint256 i = refactoredCount; i < refactorCount; i++) {
            v = v * REFACTOR_DIVIDER ;
        }

        return v;
    }

    function _snapshot(address layer2) internal virtual returns (uint256) {
        currentLayer2SnapshotId[layer2]++;

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);
        emit SnapshotLayer2(layer2, currentId);
        return currentId;

    }

    function _lastSnapshotId(uint256[] storage ids) internal view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    function _updateBalanceSnapshots(
            address layer2,
            BalanceSnapshots storage snapshots,
            uint256 balances,
            uint256 refactoredCounts,
            uint256 remains,
            address account
    ) internal  {

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        uint256 index = _lastSnapshotId(snapshots.ids);

        if (index < currentId) {
            snapshots.ids.push(currentId);
            snapshots.balances.push(balances);

            if(refactoredCounts > 0 && account != address(0)) accountRefactoredCounts[layer2][account][snapshots.ids.length-1] = refactoredCounts;
            else if(refactoredCounts > 0 && account == address(0)) totalSupplyRefactoredCounts[layer2][snapshots.ids.length-1] = refactoredCounts;

            if(remains > 0 && account != address(0)) accountRemains[layer2][account][snapshots.ids.length-1] = remains;
            else if(remains > 0 && account == address(0)) totalSupplyRemains[layer2][snapshots.ids.length-1] = remains;
        }
    }

    function _updateFactorSnapshots(
        address layer2,
        FactorSnapshots storage snapshots,
        uint256 factors,
        uint256 refactorCounts
    ) internal {

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.factors.push(factors);
            snapshots.refactorCounts.push(refactorCounts);
        }
    }

    function updateLayer2Account(address layer2, address account, uint256 balances, uint256 refactoredCounts, uint256 remains) internal {

        _updateBalanceSnapshots(
            layer2,
            accountBalanceSnapshots[layer2][account],
            balances,
            refactoredCounts,
            remains,
            account
            );
    }


    function updateLayer2TotalSupply(address layer2, uint256 balances, uint256 refactoredCounts, uint256 remains) internal {

        _updateBalanceSnapshots(
            layer2,
            totalSupplySnapshots[layer2],
            balances,
            refactoredCounts,
            remains,
            address(0)
            );
    }

    function updateLayer2Factor(address layer2, uint256 factor, uint256 refactorCount) internal {

        _updateFactorSnapshots(
            layer2,
            factorSnapshots[layer2],
            factor,
            refactorCount
        );
    }

    /// @notice Snapshot all layer2 staking information.
    /// @inheritdoc IAutoCoinageSnapshot2
    function snapshot() public override returns (uint256) {
        bool boolChange = false;

        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        address[] memory _layer2 = new address[](numberOfLayer2s);
        uint256[] memory _snapshotId = new uint256[](numberOfLayer2s);
        Layer2Snapshots memory cursnapshot_ = snashotAggregator[snashotAggregatorTotal];

        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            if (needSyncs[layer2].length > 0) {
                syncBatch(layer2,  needSyncs[layer2]);
                if (!boolChange) boolChange = true;
                delete needSyncs[layer2];
            }
            uint256 id = getCurrentLayer2SnapshotId(layer2);

            _layer2[i] = layer2;
            _snapshotId[i] = id;
            if (!boolChange && cursnapshot_.layer2s.length != numberOfLayer2s) boolChange = true;
            else if (!boolChange && cursnapshot_.layer2s[i] != layer2) boolChange = true;
            else if (!boolChange && cursnapshot_.snapshotIds[i] != id) boolChange = true;
        }

        if (boolChange) {
            snashotAggregatorTotal++;
            Layer2Snapshots storage snapshot_ = snashotAggregator[snashotAggregatorTotal];
            for (uint256 j = 0; j < _layer2.length; j++){
                snapshot_.layer2s.push(_layer2[j]);
                snapshot_.snapshotIds.push(_snapshotId[j]);
            }
        }
        emit Snapshot(snashotAggregatorTotal);
        return snashotAggregatorTotal;
    }

    /// @notice Snapshot the current staking information of a specific Layer2.
    /// @inheritdoc IAutoCoinageSnapshot2
    function snapshot(address layer2) public override returns (uint256) {
        return _snapshot(layer2);
    }

    /// @notice Synchronize the staking information of specific layer 2.
    /// @inheritdoc IAutoCoinageSnapshot2
    function sync(address layer2) public override returns (uint256){

        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        uint256 tbalances = totalBalance.balance;
        uint256 trefactoredCounts = totalBalance.refactoredCount;
        uint256 tremains = totalBalance.remain;

        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        uint256 snapshotId = _snapshot(layer2);
        updateLayer2TotalSupply(layer2, tbalances, trefactoredCounts, tremains);
        updateLayer2Factor(layer2, _factor, refactorCount);

        emit SyncLayer2(layer2, snapshotId);
        return snapshotId;
    }

    /// @notice Synchronize the staking information of specific layer2's account.
    /// @inheritdoc IAutoCoinageSnapshot2
    function sync(address layer2, address account) public override returns (uint256) {

        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");
        require(account != address(0), "zero account");

        AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(account);
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();

        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        uint256 snapshotId = _snapshot(layer2);
        updateLayer2Account(layer2, account, accountBalance.balance, accountBalance.refactoredCount, accountBalance.remain);
        updateLayer2TotalSupply(layer2, totalBalance.balance, totalBalance.refactoredCount, totalBalance.remain);
        updateLayer2Factor(layer2, _factor, refactorCount);

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        emit SyncLayer2Address(layer2, account, snapshotId);
        return snapshotId;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function syncBatch(
        address layer2,
        address[] memory accounts
        )
        public override returns (uint256)
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");
        require(accounts.length > 0, "zero accounts");

        uint256 snapshotId = _snapshot(layer2);

        for (uint256 i = 0; i < accounts.length; i++) {
            AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(accounts[i]);
            updateLayer2Account(layer2, accounts[i], accountBalance.balance, accountBalance.refactoredCount, accountBalance.remain);
        }

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        updateLayer2TotalSupply(layer2, totalBalance.balance, totalBalance.refactoredCount, totalBalance.remain);
        updateLayer2Factor(layer2, _factor, refactorCount);

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        emit SyncLayer2Batch(layer2, snapshotId);
        return snapshotId;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function syncBactchOffline(
        address layer2,
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory refactoredCounts,
        uint256[] memory remains,
        uint256[3] memory layerTotal,
        uint256[2] memory layerFactor
        )
        external onlyRole(ADMIN_ROLE) override returns (bool)
    {
        require(accounts.length == balances.length, "No balances same length");
        require(accounts.length == refactoredCounts.length, "No refactoredCounts same length");
        require(accounts.length == remains.length, "No remains same length");

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        _snapshot(layer2);

        for (uint256 i = 0; i < accounts.length; i++) {
            updateLayer2Account(
                layer2,
                accounts[i],
                balances[i],
                refactoredCounts[i],
                remains[i]
                );
        }

        updateLayer2TotalSupply(layer2, layerTotal[0], layerTotal[1], layerTotal[2]);
        updateLayer2Factor(layer2, layerFactor[0], layerFactor[1]);

        return true;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function layerSnapshotIds(uint256 snashotAggregatorId) public view override returns (address[] memory, uint256[] memory) {
        Layer2Snapshots memory snapshot_ = snashotAggregator[snashotAggregatorId];
        return (snapshot_.layer2s, snapshot_.snapshotIds);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getLayer2TotalSupplyInTokamak(address layer2) public view override
        returns (
                uint256 totalSupplyLayer2,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        totalSupplyLayer2 = AutoRefactorCoinageI(coinage).totalSupply();
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();

        balance = totalBalance.balance;
        refactoredCount = totalBalance.refactoredCount;
        remain = totalBalance.remain;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getLayer2BalanceOfInTokamak(address layer2, address user) public view override
        returns (
                uint256 balanceOfLayer2Amount,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        balanceOfLayer2Amount = AutoRefactorCoinageI(coinage).balanceOf(user);

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage).balances(user);
        balance = totalBalance.balance;
        refactoredCount = totalBalance.refactoredCount;
        remain = totalBalance.remain;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getBalanceOfInTokamak(address account) public view override
        returns (
                uint256 accountAmount
        )
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        accountAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if(coinage != address(0)){
                accountAmount += AutoRefactorCoinageI(coinage).balanceOf(account);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getTotalStakedInTokamak() public view override
        returns (
                uint256 accountAmount
        )
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        accountAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if (coinage != address(0)) {
                accountAmount += AutoRefactorCoinageI(coinage).totalSupply();
            }
        }
    }


    function currentAccountBalanceSnapshots(address layer2, address account) public view
        returns (
                bool ,
                uint256,
                uint256,
                uint256,
                uint256 ,
                AutoRefactorCoinageI.Balance memory
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        uint256 currentBalanceOf = AutoRefactorCoinageI(coinage).balanceOf(account);
        AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(account);
        BalanceSnapshots storage snapshots = accountBalanceSnapshots[layer2][account];

        address account_ = account;
        address layer2_ = layer2;
        (bool snapshotted, uint256 snapShotBalance, uint256 snapShotRefactoredCount, uint256 snapShotRemain)
            = _valueAt(layer2_, getCurrentLayer2SnapshotId(layer2_), snapshots, account_);

        return (
            snapshotted, snapShotBalance, snapShotRefactoredCount, snapShotRemain,
            currentBalanceOf, accountBalance);
    }


    function currentTotalSupplySnapshots(address layer2) public view
        returns (
                bool ,
                uint256 ,
                uint256 ,
                uint256 ,
                uint256 ,
                AutoRefactorCoinageI.Balance memory
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        uint256 currentTotalSupply = AutoRefactorCoinageI(coinage).totalSupply();
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        BalanceSnapshots storage snapshots = totalSupplySnapshots[layer2];

        address layer2_ = layer2;
        (bool snapshotted, uint256 snapShotBalance, uint256 snapShotRefactoredCount, uint256 snapShotRemain)
            = _valueAt(layer2_, getCurrentLayer2SnapshotId(layer2_), snapshots, address(0));

        return (snapshotted, snapShotBalance, snapShotRefactoredCount, snapShotRemain, currentTotalSupply, totalBalance);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function currentFactorSnapshots(address layer2) public view override
        returns (
                bool snapshotted,
                uint256 snapShotFactor,
                uint256 snapShotRefactorCount,
                uint256 curFactorValue,
                uint256 curFactor,
                uint256 curRefactorCount
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        curFactorValue = AutoRefactorCoinageI(coinage).factor();
        curFactor  = AutoRefactorCoinageI(coinage)._factor();
        curRefactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        (snapshotted, snapShotFactor, snapShotRefactorCount) = _factorAt(layer2, currentId);

    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getCurrentLayer2SnapshotId(address layer2) public view override returns (uint256) {
        return currentLayer2SnapshotId[layer2];
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOf(address account) public view override returns (uint256)
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        uint256 accountAmount = 0;

        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            accountAmount += SeigManagerI(seigManager).stakeOf(layer2, account);
        }
        return accountAmount;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupply() public view override returns (uint256)
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            totalAmount += totalSupply(layer2);
        }
        return totalAmount;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOf(address layer2, address account)
        public view override returns (uint256)
    {
        return balanceOfAt(layer2, account, getCurrentLayer2SnapshotId(layer2));
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOfAt(address layer2, address account, uint256 snapshotId)
        public view override returns (uint256)
    {
        if (snapshotId > 0) {
            (bool snapshotted1, uint256 balances, uint256 refactoredCounts, uint256 remains) = _balanceOfAt(layer2, account, snapshotId);
            (bool snapshotted2, uint256 factors, uint256 refactorCounts) = _factorAt(layer2, snapshotId);

            if (snapshotted1 && snapshotted2) {
                uint256 bal = applyFactor(balances, refactoredCounts, factors, refactorCounts);
                bal += remains;
                return bal;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOfAt(address account, uint256 snashotAggregatorId)
        public view override returns (uint256 accountStaked)
    {
        accountStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return 0;
            for (uint256 i = 0; i< snapshots.layer2s.length; i++) {
                accountStaked += balanceOfAt(snapshots.layer2s[i], account, snapshots.snapshotIds[i]);
            }
        }
    }


    /// @inheritdoc IAutoCoinageSnapshot2
    function stakedAmountWithSnashotAggregator(address account, uint256 snashotAggregatorId)
        public view override returns (uint256 accountStaked, uint256 totalStaked)
    {
        accountStaked = 0;
        totalStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return (0, 0);
            for (uint256 i = 0; i< snapshots.layer2s.length; i++) {
                accountStaked += balanceOfAt(snapshots.layer2s[i], account, snapshots.snapshotIds[i]);
                totalStaked += totalSupplyAt(snapshots.layer2s[i], snapshots.snapshotIds[i]);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupply(address layer2) public view override returns (uint256)
    {
        return totalSupplyAt(layer2, getCurrentLayer2SnapshotId(layer2));
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupplyAt(uint256 snashotAggregatorId) public view override returns (uint256 totalStaked)
    {
        totalStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return 0;
            for (uint256 i = 0; i < snapshots.layer2s.length; i++) {
                totalStaked += totalSupplyAt(snapshots.layer2s[i], snapshots.snapshotIds[i]);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupplyAt(address layer2, uint256 snapshotId) public view override returns (uint256)
    {
        if (snapshotId > 0) {
            (bool snapshotted1, uint256 balances, uint256 refactoredCounts, uint256 remains) = _totalSupplyAt(layer2, snapshotId);
            (bool snapshotted2, uint256 factors, uint256 refactorCounts) = _factorAt(layer2, snapshotId);

            if (snapshotted1 &&  snapshotted2) {
                uint256 bal = applyFactor(balances, refactoredCounts, factors, refactorCounts);
                bal += remains;
                return bal;
            } else {
                return 0;
            }
        } else {
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if (coinage != address(0)) return AutoRefactorCoinageI(coinage).totalSupply();
            return 0;
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function lastSnapShotIndex(address layer2) public view override returns (uint256)
    {
        if (totalSupplySnapshots[layer2].ids.length == 0) return 0;
        return totalSupplySnapshots[layer2].ids.length-1;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getAccountBalanceSnapsByIds(uint256 id, address layer2, address account) public view override
        returns (uint256, uint256, uint256, uint256)
    {
        BalanceSnapshots memory snapshot_ =  accountBalanceSnapshots[layer2][account];
        uint256 len = snapshot_.ids.length;
        if (id >= len){
            (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, len-1);
            return (snapshot_.ids[len-1], snapshot_.balances[len-1], refactoredCounts, remains);
        }
        (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, id);
        return (snapshot_.ids[id], snapshot_.balances[id], refactoredCounts, remains);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getAccountBalanceSnapsBySnapshotId(uint256 snapshotId, address layer2, address account) public view override
        returns (uint256, uint256, uint256, uint256)
    {
        BalanceSnapshots storage snapshot_ =  accountBalanceSnapshots[layer2][account];

        if (snapshot_.ids.length == 0) return (0,0,0,0);

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 id = snapshot_.ids.findIndex(snapshotId);
            (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, id);
            return (snapshot_.ids[id], snapshot_.balances[id], refactoredCounts, remains);
        } else {
            return (0,0,0,0);
        }
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual  returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return 0;
    }
}
