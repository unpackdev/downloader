// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutoCoinageSnapshot2 {

    /// @notice This event is emitted when taking a snapshot. You can check the snashotAggregatorId.
    /// @param snashotAggregatorId snashotAggregatorId, By using snashotAggregatorId, you can query the balance and total amount for a specific snashotAggregatorId.
    event Snapshot(uint256 snashotAggregatorId);

    /// @notice This event is emitted when taking a snapshot of a specific layer2,
    ///         You can check the snapshot ID of a specific layer2.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SnapshotLayer2(address indexed layer2, uint256 id);

    /// @notice This event is emitted when a specific layer2's staking information is synchronized and a snapshot is taken.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SyncLayer2(address indexed layer2, uint256 id);

    /// @notice This event is emitted when a specific layer2's and account's  staking information is synchronized and a snapshot is taken.
    /// @param layer2 a layer2 address
    /// @param account an account address
    /// @param id  a layer2's snapshotId
    event SyncLayer2Address(address indexed layer2, address account, uint256 id);

    /// @notice This event is emitted when synchronizes multiple accounts of a specific layer2, takes a snapshot.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SyncLayer2Batch(address indexed layer2, uint256 id);

    /// @notice This event is emitted when the PowerTONSwapper calls during staking and unstaking,
    ///         and you can know the Layer2 and account information that are saved for later syncs.
    /// @param layer2 a layer2 address
    /// @param account  an account
    event AddSync(address indexed layer2, address indexed account);


    /// @notice Set the segManager and layer2Registry address. onlyRole(ADMIN_ROLE) can call it.
    /// @param _seigManager a segManager address
    /// @param _layer2Registry  a layer2Registry address
    function setAddress(address _seigManager, address _layer2Registry) external;

    /// @notice To support the basic interface of ERC20, set name, symbol, decimals.
    /// @param name_ name
    /// @param symbol_  symbol
    /// @param decimals_  decimals
    function setNameSymbolDecimals(string memory name_, string memory symbol_, uint256 decimals_) external;

    /// @notice Managed Layer 2 addresses can be added by the administrator.
    /// @param _layers  layer2's addresses
    function addLayer2s(address[] memory _layers) external;

    /// @notice Managed Layer2 address can be deleted by the administrator.
    /// @param _layer  layer2's address
    function delLayer2(address _layer) external;

    /// @notice This functions is called when the PowerTONSwapper calls during staking and unstaking,
    ///         and  Layer2 and account information are saved for later syncs. onlyRole(ADMIN_ROLE) can call it.
    /// @param layer2 a layer2 address
    /// @param account  an account
    /// @return uint256  account's length in needSyncs's layer2
    function addSync(address layer2, address account) external returns (uint256);


    /// @notice This function is used to execute batch synchronization for the first time after contract deployment.
    ///          onlyRole(ADMIN_ROLE) can call it.
    /// @param layer2  layer2's addresses
    /// @param accounts  accounts's addresses
    /// @param balances  balances of AutoRefactorCoinageI(coinage).balances(account);
    /// @param refactoredCounts  refactoredCounts of AutoRefactorCoinageI(coinage).balances(account);
    /// @param remains  remains of AutoRefactorCoinageI(coinage).balances(account);
    /// @param layerTotal  _totalSupply of AutoRefactorCoinage(coinage)
    /// @param layerFactor  _factor, refactorCount of AutoRefactorCoinage(coinage)
    /// @return bool  true
    function syncBactchOffline(
        address layer2,
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory refactoredCounts,
        uint256[] memory remains,
        uint256[3] memory layerTotal,
        uint256[2] memory layerFactor
        )
        external returns (bool) ;


    /// @notice You can calculate the balance with the saved snapshot information.
    /// @param v  balances of AutoRefactorCoinageI(coinage).balances(account);
    /// @param refactoredCount  refactoredCounts of AutoRefactorCoinageI(coinage).balances(account);
    /// @param _factor  _factor of AutoRefactorCoinage(coinage)
    /// @param refactorCount  refactorCount of AutoRefactorCoinage(coinage)
    /// @return balance  balance
    function applyFactor(uint256 v, uint256 refactoredCount, uint256 _factor, uint256 refactorCount) external view returns (uint256);

    /// @notice Snapshot all layer2 staking information.
    /// @return snashotAggregatorId
    function snapshot() external returns (uint256);

    /// @notice Snapshot the current staking information of a specific Layer2.
    /// @param layer2  layer2's address
    /// @return snashotId of layer2
    function snapshot(address layer2) external returns (uint256) ;

    /// @notice Synchronize the staking information of specific layer 2.
    /// @param layer2  layer2's address
    /// @return snashotId of layer2
    function sync(address layer2) external returns (uint256);

    /// @notice Synchronize the staking information of specific layer2's account.
    /// @param layer2  layer2's address
    /// @param account  account's address
    /// @return snashotId of layer2
    function sync(address layer2, address account) external returns (uint256);

    /// @notice Synchronize the staking information of specific layer2's accounts.
    /// @param layer2  layer2's address
    /// @param accounts  accounts's address
    function syncBatch(address layer2,  address[] memory accounts) external returns (uint256);


    /// @notice return snapshot ids for all layer2.
    /// @param snashotAggregatorId  a snashotAggregatorId
    /// @return layer2's addresses
    /// @return layer2's snashotIds
    function layerSnapshotIds(uint256 snashotAggregatorId) external view returns (address[] memory, uint256[] memory) ;


    /// @notice Total amount staked in Layer2 of Tokamak
    /// @param layer2  a layer2 address
    /// @return totalSupplyLayer2 totalSupply of layer2
    /// @return balance a balance of layer2.balances
    /// @return refactoredCount a refactoredCount of layer2.balances
    /// @return remain a remain of layer2.balances
    function getLayer2TotalSupplyInTokamak(address layer2) external view
        returns (
                uint256 totalSupplyLayer2,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    /// @notice balance amount staked in Layer2's account of Tokamak
    /// @param layer2  a layer2 address
    /// @param user  account
    /// @return balanceOfLayer2Amount balanceOf of layer2's account
    /// @return balance a balance of layer2's account.balances
    /// @return refactoredCount a refactoredCount of layer2's account.balances
    /// @return remain a remain of layer2's account.balances
    function getLayer2BalanceOfInTokamak(address layer2, address user) external view
        returns (
                uint256 balanceOfLayer2Amount,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    /// @notice balance amount staked in account of Tokamak
    /// @param account  account
    /// @return accountAmount  user's staked balance
    function getBalanceOfInTokamak(address account) external view
        returns (
                uint256 accountAmount
        );

    /// @notice total amount staked in Tokamak
    /// @return amount  total amount staked
    function getTotalStakedInTokamak() external view
        returns (
                uint256 amount
        );

    /*
    /// @notice Returns information staked in the current tokamak of layer2 and information stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @param account account
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotBalance Balance in Snapshot
    /// @return snapShotRefactoredCount RefactoredCounts in Snapshot
    /// @return snapShotRemain Remain in Snapshot
    /// @return currentBalanceOf a current balanceOf in tokamak
    /// @return AutoRefactorCoinageI.Balance balances of layer's account in tokamak
    function currentAccountBalanceSnapshots(address layer2, address account) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentBalanceOf,
                AutoRefactorCoinageI.Balance balances
        );


    /// @notice information staked in the current tokamak of layer2 and information stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotBalance Balance in Snapshot
    /// @return snapShotRefactoredCount RefactoredCounts in Snapshot
    /// @return snapShotRemain Remain in Snapshot
    /// @return currentTotalSupply a current total staked amount in tokamak
    /// @return AutoRefactorCoinageI.Balance _totalSupply() of layer2 in tokamak
    function currentTotalSupplySnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentTotalSupply,
                AutoRefactorCoinageI.Balance _total
        );
    */

    /// @notice Returns factor in the current tokamak of layer2 and factor stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotFactor factor in Snapshot
    /// @return snapShotRefactorCount RefactorCount in Snapshot
    /// @return curFactorValue a current FactorValue in tokamak
    /// @return curFactor a current Factor in tokamak
    /// @return curRefactorCount a current RefactorCount in tokamak
    function currentFactorSnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotFactor,
                uint256 snapShotRefactorCount,
                uint256 curFactorValue,
                uint256 curFactor,
                uint256 curRefactorCount
        );

    /// @notice Current snapshotId of the layer2
    /// @param layer2 a layer2 address
    /// @return Layer2SnapshotId Layer2's SnapshotId
    function getCurrentLayer2SnapshotId(address layer2) external view returns (uint256) ;

    /// @notice account's balance staked amount
    /// @param account a account address
    /// @return amount account's balance staked amount
    function balanceOf(address account) external view returns (uint256);

    /// @notice total staked amount in tokamak
    /// @return total staked amount
    function totalSupply() external view returns (uint256);


    /// @notice account's balance staked amount in current snapshot
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return amount account's balance staked amount
    function balanceOf(address layer2, address account) external view returns (uint256);

    /// @notice account's balance staked amount in snashotAggregatorId
    /// @param account a account address
    /// @param snashotAggregatorId a snashotAggregatorId
    /// @return amount account's balance staked amount
    function balanceOfAt(address account, uint256 snashotAggregatorId) external view returns (uint256);

    /// @notice account's balance staked amount in snapshotId
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @param snapshotId a snapshotId
    /// @return amount account's balance staked amount
    function balanceOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256);

    /// @notice layer2's staked amount in current snapshot
    /// @param layer2 a layer2 address
    /// @return amount layer2's staked amount
    function totalSupply(address layer2) external view returns (uint256);

    /// @notice total staked amount in snashotAggregatorId
    /// @param snashotAggregatorId  snashotAggregatorId
    /// @return totalStaked total staked amount
    function totalSupplyAt(uint256 snashotAggregatorId) external view returns (uint256 totalStaked);

    /// @notice layer2's staked amount in snapshotId
    /// @param layer2 a layer2 address
    /// @param snapshotId a snapshotId
    /// @return layer2's staked amount
    function totalSupplyAt(address layer2, uint256 snapshotId) external view returns (uint256);

    /// @notice account's staked amount in snashotAggregatorId
    /// @param account a account address
    /// @return accountStaked  account's staked amount
    /// @return totalStaked   total staked amount
    function stakedAmountWithSnashotAggregator(address account, uint256 snashotAggregatorId) external view
        returns (uint256 accountStaked, uint256 totalStaked);

    /// @notice last SnapShotIndex
    /// @param layer2 a layer2 address
    /// @return SnapShotIndex  SnapShotIndex
    function lastSnapShotIndex(address layer2) external view returns (uint256);

    /// @notice snapshot's information by snapshotIndex
    /// @param id  id
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return ids  snapshot's id
    /// @return balances  snapshot's balance
    /// @return refactoredCounts  snapshot's refactoredCount
    /// @return remains  snapshot's remain
    function getAccountBalanceSnapsByIds(uint256 id, address layer2, address account) external view
        returns (uint256, uint256, uint256, uint256);

    /// @notice snapshot's information by snapshotId
    /// @param snapshotId  snapshotId
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return ids  snapshot's id
    /// @return balances  snapshot's balance
    /// @return refactoredCounts  snapshot's refactoredCount
    /// @return remains  snapshot's remain
    function getAccountBalanceSnapsBySnapshotId(uint256 snapshotId, address layer2, address account) external view
        returns (uint256, uint256, uint256, uint256);

}
