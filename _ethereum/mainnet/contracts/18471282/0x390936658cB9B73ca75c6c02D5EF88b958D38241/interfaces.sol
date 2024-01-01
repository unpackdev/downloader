//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./IERC20.sol";

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface IEulerTokens {
    function balanceOfUnderlying(
        address account
    ) external view returns (uint256); //To be used for E-Tokens

    function balanceOf(address) external view returns (uint256); //To be used for D-Tokens
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}

interface IMorphoAaveV2 {
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index. Note that for the stEth market, the pool supply index is tweaked to take into account the staking rewards.
        uint112 poolBorrowIndex; // Last pool borrow index. Note that for the stEth market, the pool borrow index is tweaked to take into account the staking rewards.
    }

    function poolIndexes(address) external view returns (PoolIndexes memory);

    // Current index from supply peer-to-peer unit to underlying (in ray).
    function p2pSupplyIndex(address) external view returns (uint256);

    // Current index from borrow peer-to-peer unit to underlying (in ray).
    function p2pBorrowIndex(address) external view returns (uint256);

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply scaled unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply scaled unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow scaled unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow scaled unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    // For a given market, the supply balance of a user. aToken -> user -> balances.
    function supplyBalanceInOf(
        address,
        address
    ) external view returns (SupplyBalance memory);

    // For a given market, the borrow balance of a user. aToken -> user -> balances.
    function borrowBalanceInOf(
        address,
        address
    ) external view returns (BorrowBalance memory);

    /// @notice Updates the peer-to-peer indexes and pool indexes (only stored locally).
    function updateIndexes(address _poolToken) external;
}

interface ILidoWithdrawalQueue {
    // code below from Lido WithdrawalQueueBase.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueueBase.sol

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    /// @notice length of the checkpoints. Last possible value for the claim hint
    function getLastCheckpointIndex() external view returns (uint256);

    // code below from Lido WithdrawalQueue.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueue.sol

    /// @notice Request the sequence of stETH withdrawals according to passed `withdrawalRequestInputs` data
    /// @param amounts an array of stETH amount values. The standalone withdrawal request will
    ///  be created for each item in the passed list.
    /// @param _owner address that will be able to transfer or claim the request.
    ///  If `owner` is set to `address(0)`, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal requests
    function requestWithdrawals(
        uint256[] calldata amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @notice Claim a batch of withdrawal requests once finalized (claimable) sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id.
    ///   Can be retrieved with `findCheckpointHints()`
    /// @dev
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /// @notice Returns all withdrawal requests that belongs to the `_owner` address
    ///
    /// WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`. NB! Array of request ids should be sorted
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range
    /// @param _lastIndex right boundary of the search range
    /// @return hintIds the hints for `claimWithdrawal` to find the checkpoint for the passed request ids
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);

    /// @notice Returns statuses for the array of request ids
    /// @param _requestIds array of withdrawal request ids
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    function balanceOf(address) external view returns (uint);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IWeth {
    function deposit() external payable;

    function transfer(address dst, uint wad) external returns (bool);
}

interface IMorphoAaveV3 {
    function marketsCreated() external view returns (address[] memory);

    /// @notice Contains the market side indexes as uint256 instead of uint128.
    struct MarketSideIndexes256 {
        uint256 poolIndex; // The pool index (in ray).
        uint256 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes as uint256 instead of uint128.
    struct Indexes256 {
        MarketSideIndexes256 supply; // The `MarketSideIndexes` related to the supply as uint256.
        MarketSideIndexes256 borrow; // The `MarketSideIndexes` related to the borrow as uint256.
    }

    /// @notice Returns the updated indexes (peer-to-peer and pool).
    function updatedIndexes(address underlying) external view returns (Indexes256 memory);

    /// @notice Returns the total borrow balance of `user` on the `underlying` market (in underlying).
    function borrowBalance(address underlying, address user) external view returns (uint256);

    /// @notice Returns the supply collateral balance of `user` on the `underlying` market (in underlying).
    function collateralBalance(address underlying, address user) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, supplied on pool & used as collateral (with `underlying` decimals).
    function scaledCollateralBalance(address underlying, address user) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, borrowed peer-to-peer (with `underlying` decimals).
    function scaledP2PBorrowBalance(address underlying, address user) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, borrowed from pool (with `underlying` decimals).
    function scaledPoolBorrowBalance(address underlying, address user) external view returns (uint256);
}
