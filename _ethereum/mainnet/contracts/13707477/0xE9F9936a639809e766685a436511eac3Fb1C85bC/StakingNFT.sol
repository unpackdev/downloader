// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract StakingNFT is ReentrancyGuard, ERC1155Holder {
    using SafeMath for uint256;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);

    // the address of the erc1155 token required for the pools for this Staking
    address public immutable erc1155TokenAddress;

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public immutable epoch1Start;

    // duration of each epoch
    uint256 public immutable epochDuration;

    // holds the current balance of the user for each token for a specific NFT ID
    mapping(address => mapping(address => mapping(uint256 => uint256))) private balances;

    // holds the current balance of the user for each erc1155TokenId - user => tokenId => balance
    mapping(address => mapping(uint256 => uint256)) private erc1155Balance;

    // holds the total poolTokenBalance for erc1155TokenId poolToken => tokenId => balance
    mapping(address => mapping(uint256 => uint256)) private poolTokenBalance;

    struct Pool {
        uint256 size;
        bool set;
    }

    // for each token and erc1155TokenId, we store the total pool size
    // poolSize[tokenAddress][erc1155TokenId][epoch]
    mapping(address => mapping(uint256 => mapping(uint256 => Pool))) private poolSize;

    // balanceCheckpoints[user][token][erc1155TokenId][]
    mapping(address => mapping(address => mapping(uint256 => Checkpoint[]))) private balanceCheckpoints;

    mapping(address => uint128) private lastWithdrawEpochId;

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    event Deposit(address indexed user, address indexed tokenAddress, uint256 indexed erc1155TokenId, uint256 amount);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 indexed erc1155TokenId, uint256 amount);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId, address[] tokens, uint256[] erc1155TokenIds);
    event EmergencyWithdraw(address indexed user, address indexed tokenAddress, uint256 indexed erc1155TokenId, uint256 amount);

    constructor (address _erc1155Token, uint256 _epoch1Start, uint256 _epochDuration) public {
        erc1155TokenAddress = _erc1155Token;
        epoch1Start = _epoch1Start;
        epochDuration = _epochDuration;
    }

    /*
     * Stores `amount` of `tokenAddress` tokens for the `user` into the vault
     */
    function deposit(address tokenAddress, uint256 erc1155TokenId, uint256 amount) public nonReentrant {
        require(amount > 0, "Staking: Amount must be > 0");

        if (erc1155Balance[msg.sender][erc1155TokenId] == 0) {
            // Stake the erc1155 NFT, users can deposit only 1 of the NFT
            erc1155Balance[msg.sender][erc1155TokenId] = 1;
            IERC1155(erc1155TokenAddress).safeTransferFrom(msg.sender, address(this), erc1155TokenId, 1, new bytes(0));
        }

        balances[msg.sender][tokenAddress][erc1155TokenId] = balances[msg.sender][tokenAddress][erc1155TokenId].add(amount);
        poolTokenBalance[tokenAddress][erc1155TokenId] = poolTokenBalance[tokenAddress][erc1155TokenId].add(amount);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();
        uint128 currentMultiplier = currentEpochMultiplier();

        if (!epochIsInitialized(tokenAddress, erc1155TokenId, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            uint256[] memory erc1155TokenIds = new uint256[](1);
            erc1155TokenIds[0] = erc1155TokenId;

            manualEpochInit(tokens, erc1155TokenIds, currentEpoch);
        }

        // update the next epoch pool size
        Pool storage pNextEpoch = poolSize[tokenAddress][erc1155TokenId][currentEpoch + 1];
        pNextEpoch.size = poolTokenBalance[tokenAddress][erc1155TokenId];
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress][erc1155TokenId];

        uint256 balanceBefore = getEpochUserBalance(msg.sender, tokenAddress, erc1155TokenId, currentEpoch);

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (checkpoints.length == 0) {
            checkpoints.push(Checkpoint(currentEpoch, currentMultiplier, 0, amount));

            // next epoch => multiplier is 1, epoch deposits is 0
            checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0));
        } else {
            uint256 last = checkpoints.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            if (checkpoints[last].epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    BASE_MULTIPLIER,
                    amount,
                        currentMultiplier
                );
                checkpoints.push(Checkpoint(currentEpoch, multiplier, getCheckpointBalance(checkpoints[last]), amount));
                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress][erc1155TokenId], 0));
            }
            // the last action happened in the previous epoch
            else if (checkpoints[last].epochId == currentEpoch) {
                checkpoints[last].multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    checkpoints[last].multiplier,
                    amount,
                    currentMultiplier
                );
                checkpoints[last].newDeposits = checkpoints[last].newDeposits.add(amount);

                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress][erc1155TokenId], 0));
            }
            // the last action happened in the current epoch
            else {
                if (last >= 1 && checkpoints[last - 1].epochId == currentEpoch) {
                    checkpoints[last - 1].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last - 1]),
                        checkpoints[last - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last - 1].newDeposits = checkpoints[last - 1].newDeposits.add(amount);
                }

                checkpoints[last].startBalance = balances[msg.sender][tokenAddress][erc1155TokenId];
            }
        }

        uint256 balanceAfter = getEpochUserBalance(msg.sender, tokenAddress, erc1155TokenId, currentEpoch);

        poolSize[tokenAddress][erc1155TokenId][currentEpoch].size = poolSize[tokenAddress][erc1155TokenId][currentEpoch].size.add(balanceAfter.sub(balanceBefore));

        emit Deposit(msg.sender, tokenAddress, erc1155TokenId, amount);
    }

    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `user`
     */
    function withdraw(address tokenAddress, uint256 erc1155TokenId, uint256 amount) public nonReentrant {
        require(balances[msg.sender][tokenAddress][erc1155TokenId] >= amount, "Staking: balance too small");

        balances[msg.sender][tokenAddress][erc1155TokenId] = balances[msg.sender][tokenAddress][erc1155TokenId].sub(amount);
        poolTokenBalance[tokenAddress][erc1155TokenId] = poolTokenBalance[tokenAddress][erc1155TokenId].sub(amount);

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);

        // withdraw the staked NFT if all funds are withdrawn
        if (erc1155Balance[msg.sender][erc1155TokenId] > 0 && balances[msg.sender][tokenAddress][erc1155TokenId] == 0) {
            erc1155Balance[msg.sender][erc1155TokenId] = 0;
            IERC1155(erc1155TokenAddress).safeTransferFrom(address(this), msg.sender, erc1155TokenId, 1, new bytes(0));
        }

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();

        lastWithdrawEpochId[tokenAddress] = currentEpoch;

        if (!epochIsInitialized(tokenAddress, erc1155TokenId, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            uint256[] memory erc1155TokenIds = new uint256[](1);
            erc1155TokenIds[0] = erc1155TokenId;
            manualEpochInit(tokens, erc1155TokenIds, currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[tokenAddress][erc1155TokenId][currentEpoch + 1];
        pNextEpoch.size = poolTokenBalance[tokenAddress][erc1155TokenId];
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress][erc1155TokenId];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(Checkpoint(currentEpoch, BASE_MULTIPLIER, balances[msg.sender][tokenAddress][erc1155TokenId], 0));

            poolSize[tokenAddress][erc1155TokenId][currentEpoch].size = poolSize[tokenAddress][erc1155TokenId][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = balances[msg.sender][tokenAddress][erc1155TokenId];
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[tokenAddress][erc1155TokenId][currentEpoch].size = poolSize[tokenAddress][erc1155TokenId][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore.sub(currentEpochCheckpoint.startBalance).mul(BASE_MULTIPLIER).div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint.newDeposits.sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint.startBalance.sub(
                    amount.sub(currentEpochCheckpoint.newDeposits)
                );
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[tokenAddress][erc1155TokenId][currentEpoch].size = poolSize[tokenAddress][erc1155TokenId][currentEpoch].size.sub(balanceBefore.sub(balanceAfter));

            checkpoints[last].startBalance = balances[msg.sender][tokenAddress][erc1155TokenId];
        }

        emit Withdraw(msg.sender, tokenAddress, erc1155TokenId, amount);
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(address[] memory tokens, uint256[] memory erc1155TokenIds, uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");
        require(tokens.length == erc1155TokenIds.length, "tokens and tokenIds arrays should be the same length");

        for (uint i = 0; i < tokens.length; i++) {
            Pool storage p = poolSize[tokens[i]][erc1155TokenIds[i]][epochId];

            if (epochId == 0) {
                p.size = uint256(0);
                p.set = true;
            } else {
                require(!epochIsInitialized(tokens[i], erc1155TokenIds[i], epochId), "Staking: epoch already initialized");
                require(epochIsInitialized(tokens[i], erc1155TokenIds[i], epochId - 1), "Staking: previous epoch not initialized");

                p.size = poolSize[tokens[i]][erc1155TokenIds[i]][epochId - 1].size;
                p.set = true;
            }
        }

        emit ManualEpochInit(msg.sender, epochId, tokens, erc1155TokenIds);
    }

    function emergencyWithdraw(address tokenAddress, uint256 erc1155TokenId) public {
        require((getCurrentEpoch() - lastWithdrawEpochId[tokenAddress]) >= 10, "At least 10 epochs must pass without success");

        uint256 totalUserBalance = balances[msg.sender][tokenAddress][erc1155TokenId];
        require(totalUserBalance > 0, "Amount must be > 0");

        uint256 totalUserERC1155Balance = erc1155Balance[msg.sender][erc1155TokenId];
        require(totalUserERC1155Balance > 0, "ERC1155Balance must be > 0");

        balances[msg.sender][tokenAddress][erc1155TokenId] = 0;
        erc1155Balance[msg.sender][erc1155TokenId] = 0;
        poolTokenBalance[tokenAddress][erc1155TokenId] = poolTokenBalance[tokenAddress][erc1155TokenId].sub(totalUserBalance);

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, totalUserBalance);
        IERC1155(erc1155TokenAddress).safeTransferFrom(address(this), msg.sender, erc1155TokenId, 1, new bytes(0));

        emit EmergencyWithdraw(msg.sender, tokenAddress, erc1155TokenId, totalUserBalance);
    }

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, address token, uint256 erc1155TokenId, uint128 epochId) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user][token][erc1155TokenId];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint min = 0;
        uint max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function erc1155BalanceOf(address user, uint256 erc1155TokenId) public view returns (uint256) {
        return erc1155Balance[user][erc1155TokenId];
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceOf(address user, address token, uint256 erc1155TokenId) public view returns (uint256) {
        return balances[user][token][erc1155TokenId];
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(address tokenAddress, uint256 erc1155TokenId, uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(tokenAddress, erc1155TokenId, epochId)) {
            return poolSize[tokenAddress][erc1155TokenId][epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(tokenAddress, erc1155TokenId, 0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract for this erc1155TokenId
        return poolTokenBalance[tokenAddress][erc1155TokenId];
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(timeLeft * BASE_MULTIPLIER / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(uint256 prevBalance, uint128 prevMultiplier, uint256 amount, uint128 currentMultiplier) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier = uint128(prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(prevBalance.add(amount)));

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(address token, uint256 erc1155TokenId, uint128 epochId) public view returns (bool) {
        return poolSize[token][erc1155TokenId][epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c) internal pure returns (uint256) {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c) internal pure returns (uint256) {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }
}
