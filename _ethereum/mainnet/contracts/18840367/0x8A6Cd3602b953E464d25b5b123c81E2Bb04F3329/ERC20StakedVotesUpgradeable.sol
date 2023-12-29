// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./SafeCastUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./draft-EIP712Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";

import "./BalanceQueue.sol";
import "./ERC20WrapperGluwacoin.sol";
import "./IStakedVotesUpgradeable.sol";
import "./IRewardToken.sol";

contract ERC20StakedVotesUpgradeable is
    IStakedVotesUpgradeable,
    Initializable,
    ERC20WrapperGluwacoin,
    ERC20PermitUpgradeable
{
    using BalanceQueue for BalanceQueue.QueueStorage;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 private constant _STAKE_TYPEHASH =
        keccak256(
            "stake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _UNSTAKE_TYPEHASH =
        keccak256(
            "unstake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _MINTTOSTAKE_TYPEHASH =
        keccak256(
            "mintToStake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256(
            "delegate(address delegatee,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    /// @dev due to limitted supply of GTD, we can minimize the checkpoint storage as below
    struct Checkpoint {
        uint32 fromBlock;
        uint96 balance;
    }

    IRewardToken private _rewardingToken;
    mapping(address => address) private _delegates;

    /// @dev checkpoints for staked amount
    mapping(address => Checkpoint[]) private _shareholderStakedCheckpoints;
    mapping(address => BalanceQueue.QueueStorage)
        private _tokenDelayedBalanceCheckpoints;
    mapping(address => Checkpoint[]) private _votingCheckpoints;

    Checkpoint[] private _totalStakedCheckpoints;

    uint8 private _processingCap;
    uint32 private _stakingLockup;
    uint32 private _unstakingLockup;
    uint32 private _wrappingRate;

    address public daoContract;

    function __ERC20StakedVotesUpgradeable_init(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) internal onlyInitializing {
        __ERC20StakedVotesUpgradeable_init_unchained(
            name,
            symbol,
            decimals_,
            admin,
            processingCap,
            wrappingRate,
            stakingLockup,
            unstakingLockup,
            token
        );
    }

    function __ERC20StakedVotesUpgradeable_init_unchained(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(token);
        __ERC20ETHless_init_unchained();
        __ERC20Reservable_init_unchained();
        __ERC20WrapperGluwacoin_init_unchained(decimals_, admin);
        _processingCap = processingCap;
        _wrappingRate = wrappingRate;
        _stakingLockup = stakingLockup;
        _unstakingLockup = unstakingLockup;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERC20StakedVotesUpgradeable: Restricted to Admin."
        );
        _;
    }

    function updateSupportedDAOContract(
        address daoContract_
    ) external onlyAdmin returns (bool) {
        daoContract = daoContract_;
        return true;
    }

    function setRewardingToken(IRewardToken rewardingToken) external onlyAdmin {
        _rewardingToken = rewardingToken;
    }

    function settings() external view returns (uint8, uint32, uint32, uint32) {
        return (
            _processingCap,
            _wrappingRate,
            _stakingLockup,
            _unstakingLockup
        );
    }

    function applySettings(
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup
    ) external onlyAdmin {
        _processingCap = processingCap;
        _wrappingRate = wrappingRate;
        _stakingLockup = stakingLockup;
        _unstakingLockup = unstakingLockup;
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(
        address account,
        uint32 pos
    ) public view virtual returns (Checkpoint memory) {
        return _shareholderStakedCheckpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints of staked amount for `account`.
     */
    function numStakedCheckpoints(
        address account
    ) public view virtual returns (uint32) {
        return
            SafeCastUpgradeable.toUint32(
                _shareholderStakedCheckpoints[account].length
            );
    }

    /**
     * @dev Get number of checkpoints of for `account` balance.
     */
    function numDelayedBalanceCheckpoints(
        address account
    ) public view virtual returns (uint32) {
        return
            SafeCastUpgradeable.toUint32(
                _tokenDelayedBalanceCheckpoints[account]._length()
            );
    }

    /**
     * @dev Get number of checkpoints of total staked amount.
     */
    function numTotalStakedCheckpoints() public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_totalStakedCheckpoints.length);
    }

    /**
     * @dev Gets the current votes balance for `account`.
     */
    function getVotes(address account) public view virtual returns (uint256) {
        uint256 pos = _votingCheckpoints[account].length;
        return pos == 0 ? 0 : _votingCheckpoints[account][pos - 1].balance;
    }

    /**
     * @dev Gets the current balance for `account`
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return super.balanceOf(account) - _getDelayedBalance(account);
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(
        address account,
        uint256 blockNumber
    ) public view virtual returns (uint256) {
        require(blockNumber <= block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_votingCheckpoints[account], blockNumber);
    }

    /**
     * @dev Returns the total tokens used to be staked token at the end of a past block (`blockNumber`).
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalStaked(
        uint256 blockNumber
    ) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalStakedCheckpoints, blockNumber);
    }

    /**
     * @dev Returns the current total staked tokens made by all users.
     * It is but NOT the sum of all the delegated votes!
     */
    function getTotalStaked() public view virtual override returns (uint256) {
        uint256 pos = _totalStakedCheckpoints.length;
        return pos == 0 ? 0 : _totalStakedCheckpoints[pos - 1].balance;
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(
        Checkpoint[] storage ckpts,
        uint256 blockNumber
    ) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        unchecked {
            while (low < high) {
                uint256 mid = MathUpgradeable.average(low, high);
                if (ckpts[mid].fromBlock > blockNumber) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
        }
        return high == 0 ? 0 : ckpts[high - 1].balance;
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount / _wrappingRate);
    }

    /// @dev to avoid unfair loss of token due to rounding down, we will exclude the remainder during token wrapping
    function __mint(address account, uint256 amount) internal override {
        uint256 remainder = amount % _wrappingRate;
        super.__mint(account, amount - remainder);
    }

    function __burn(address account, uint256 amount) internal override {
        _token.safeTransfer(account, amount * _wrappingRate);
        emit Burnt(account, amount);

        _burn(account, amount);
    }

    /**
     * @dev `mint` but with `minter`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a mint fee amount in Gluwacoin, which the minter will pay for the mint.
     * `sig` is a signature created by signing the mint information with the minter’s private key.
     * Anyone can initiate the mint for the minter by calling the Etherless Mint function
     * with the mint information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Transfers `amount` + `fee` of base tokens from the minter to the contract using `transferFrom`.
     * Creates `amount` + `fee` of tokens to the minter and transfers `fee` tokens to the caller.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the minter must have base tokens of at least `amount`.
     * - the contract must have allowance for receiver's base tokens of at least `amount`.
     * - `fee` will be deducted after successfully minting
     */
    function mint(
        address minter,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        _useWrapperNonce(minter, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Mint,
                block.chainid,
                address(this),
                minter,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, minter, sig);

        __mint(minter, amount);
        _transfer(minter, _msgSender(), fee);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(
        address account
    ) public view virtual override returns (address) {
        return _delegates[account];
    }

    function mintToStake(uint256 amount) external virtual returns (bool) {
        __mint(_msgSender(), amount);
        _stake(_msgSender(), amount / _wrappingRate);
        return true;
    }

    function mintToStakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (bool) {
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINTTOSTAKE_TYPEHASH,
                        amount,
                        fee,
                        nonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        __mint(stakeholder, amount);
        _transfer(stakeholder, _msgSender(), fee);
        _stake(stakeholder, (amount / _wrappingRate) - fee);
        return true;
    }

    function _stakeValidation() internal virtual {}

    function _stake(
        address stakeholder,
        uint256 amount
    ) internal returns (bool) {
        _stakeValidation();
        _transfer(stakeholder, daoContract, amount);
        _writeCheckpoint(_totalStakedCheckpoints, _add, amount, block.number);
        _writeCheckpoint(
            _shareholderStakedCheckpoints[stakeholder],
            _add,
            amount,
            block.number
        );
        if (_delegates[stakeholder] == address(0)) {
            _delegates[stakeholder] = stakeholder;
        }
        _rewardingToken.updateAccumulatedWhenStake(stakeholder, amount);

        _moveVotingPower(address(0), _delegates[stakeholder], amount);
        return true;
    }

    function _unstake(
        address stakeholder,
        uint256 amount
    ) internal returns (bool) {
        /// @dev amount must be > 0 to reduce queue item
        require(
            stakeOf(stakeholder) >= amount && amount > 0,
            "ERC20StakedVotesUpgradeable: Invalid amount"
        );
        _transfer(daoContract, stakeholder, amount);
        _writeCheckpoint(
            _totalStakedCheckpoints,
            _subtract,
            amount,
            block.number
        );
        _writeCheckpoint(
            _shareholderStakedCheckpoints[stakeholder],
            _subtract,
            amount,
            block.number
        );
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[stakeholder];
        uint8 processingCount;
        if (balanceQueue._isEmpty()) {
            balanceQueue._initialize();
        } else {
            while (
                !balanceQueue._isEmpty() &&
                balanceQueue._peek().blockNumber <= block.number &&
                processingCount < _processingCap
            ) {
                balanceQueue._dequeue();
                processingCount++;
            }
        }
        balanceQueue._enqueue(
            SafeCastUpgradeable.toUint32(block.number + _unstakingLockup),
            SafeCastUpgradeable.toUint96(amount)
        );

        _rewardingToken.updateAccumulatedWhenUnstake(stakeholder, amount);
        _moveVotingPower(_delegates[stakeholder], address(0), amount);
        return true;
    }

    function stake(uint256 amount) external virtual override returns (bool) {
        require(
            amount > 0,
            "ERC20StakedVotesUpgradeable: Cannot stake 0 amount"
        );
        return _stake(_msgSender(), amount);
    }

    function stakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(
            amount > 0,
            "ERC20StakedVotesUpgradeable: Cannot stake 0 amount"
        );
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_STAKE_TYPEHASH, amount, fee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        _transfer(stakeholder, _msgSender(), fee);
        return _stake(stakeholder, amount);
    }

    function unstake(uint256 amount) external virtual override returns (bool) {
        return _unstake(_msgSender(), amount);
    }

    function unstakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_UNSTAKE_TYPEHASH, amount, fee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        _transfer(stakeholder, _msgSender(), fee);
        return _unstake(stakeholder, amount);
    }

    function stakeOf(
        address stakeholder
    ) public view override returns (uint256) {
        uint256 pos = _shareholderStakedCheckpoints[stakeholder].length;
        return
            pos == 0
                ? 0
                : _shareholderStakedCheckpoints[stakeholder][pos - 1].balance;
    }

    /**
     * @dev Returns the total tokens of an address used to be staked token at the end of a past block (`blockNumber`).
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function stakeOf(
        address stakeholder,
        uint256 blockNumber
    ) public view override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return
            _checkpointsLookup(
                _shareholderStakedCheckpoints[stakeholder],
                blockNumber
            );
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _DELEGATION_TYPEHASH,
                        delegatee,
                        fee,
                        nonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(signer, nonce);
        _transfer(signer, _msgSender(), fee);
        _delegate(signer, delegatee);
        return true;
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = stakeOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    /// @notice Return a number of decimals of the token
    function decimals()
        public
        view
        override(ERC20Upgradeable, ERC20WrapperGluwacoin)
        returns (uint8)
    {
        return ERC20WrapperGluwacoin.decimals();
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _votingCheckpoints[src],
                    _subtract,
                    amount,
                    block.number
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _votingCheckpoints[dst],
                    _add,
                    amount,
                    block.number
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta,
        uint256 effectiveBlockNumber
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].balance;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && (ckpts[pos - 1].fromBlock == effectiveBlockNumber)) {
            ckpts[pos - 1].balance = SafeCastUpgradeable.toUint96(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCastUpgradeable.toUint32(
                        effectiveBlockNumber
                    ),
                    balance: SafeCastUpgradeable.toUint96(newWeight)
                })
            );
        }
    }

    /**
     * @dev allow to query the delayed balance of an `account` which can be only received after the current block from unstaked process
     */
    function getDelayedBalance(
        address account
    ) external view returns (uint256) {
        return _getDelayedBalance(account);
    }

    /**
     * @dev Get the balance for `account` which can be only received after the current block from unstaked process
     */
    function _getDelayedBalance(
        address account
    ) private view returns (uint256) {
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[account];
        uint32 queueIndex = balanceQueue.last;
        uint256 delayedBalance;
        while (true) {
            if (balanceQueue.data[queueIndex].blockNumber > block.number) {
                delayedBalance += balanceQueue.data[queueIndex].value;
                --queueIndex;
            } else {
                break;
            }
        }
        return delayedBalance;
    }

    function removeQueueData(address account, uint16 numberOfItem) public {
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[account];
        for (uint8 i = 0; i < numberOfItem; i++) {
            if (
                !balanceQueue._isEmpty() &&
                balanceQueue._peek().blockNumber <= block.number
            ) {
                balanceQueue._dequeue();
            } else {
                break;
            }
        }
    }

    function _updateCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].balance;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].balance = SafeCastUpgradeable.toUint96(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCastUpgradeable.toUint32(block.number),
                    balance: SafeCastUpgradeable.toUint96(newWeight)
                })
            );
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20WrapperGluwacoin) {
        require(
            from == address(0) || balanceOf(from) >= amount,
            "ERC20StakedVotesUpgradeable: Insufficient balance"
        );
        ERC20WrapperGluwacoin._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}
