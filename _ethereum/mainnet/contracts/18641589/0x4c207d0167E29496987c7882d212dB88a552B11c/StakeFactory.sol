pragma solidity ^0.8.4;
pragma abicoder v2;


// SPDX-License-Identifier: Unlicensed

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract Stake is Ownable, Pausable {
    using ECDSA for address;
    address public signer;
    address public stakeFactory;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public APR_PERCENT;
    uint256 public duration = 1 days;
    uint256 public stakeDuration = 30 days;
    uint256 public phase_duration_1 = 9 days;
    uint256 public phase_duration_2 = 25 days;
    uint256 public phase_duration_3 = 29 days;
    uint256 public adminPercent = 4e18;
    uint256[2] public penalityPercent = [50e18, 80e18];
    bool public isInitialized;
    bool public isBurn;

    IERC20 public rewardToken;
    IERC20 public stakeToken;

    event StakeDetails(
        address indexed from,
        uint256 amount,
        bool autoRenewal,
        uint16 time
    );
    event Withdraw(
        address indexed from,
        uint256 amount,
        uint256 reward,
        uint256 burnPercentage,
        uint16 time
    );
    event AutoInjection(
        address indexed from,
        uint256 amount,
        uint256 depositTime,
        uint256 APR
    );

    struct UserDetails {
        uint256 depositAmount;
        bool autoDeposit;
        uint256 stakeTime;
        uint256 endTime;
        uint256 earnings;
        uint256 apr;
    }

    mapping(address => UserDetails) public users;
    mapping(bytes32 => bool)public msgHash;

    constructor() { stakeFactory = _msgSender(); }

    receive() external payable {}

    function initialize (
        IERC20 _stake,
        IERC20 _reward,
        uint256 _apr,
        bool _burnEnable,
        address _admin,
        address _signer
    ) external {
        require(!isInitialized, "Already initialized");
        require(_msgSender() == stakeFactory, "Not factory");

        isInitialized = true;

        stakeToken = _stake;
        rewardToken = _reward;

        APR_PERCENT = _apr;
        isBurn = _burnEnable;
        signer = _signer;

        transferOwnership(_admin);
    }

    function updateTokens(IERC20 _stake,IERC20 _reward) external onlyOwner {
        stakeToken = _stake;
        rewardToken = _reward;
    }

    function emergencyWithdraw(
        address _token,
        address _user,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(0)) payable(_user).transfer(_amount);
        else tokenSafeTransfer(IERC20(_token), _user, _amount);
    }

    function updateBurnOption (bool _status) external onlyOwner {
        isBurn = _status;
    }

    function updateSigner (address _signer) external onlyOwner {
        signer = _signer;
    }

    function updateBurnWallet (address _burn) external  onlyOwner {
        burnWallet = _burn;
    }

    function updatePenalityPercent(
        uint256 _percent_1,
        uint256 _percent_2
    ) external onlyOwner {
        penalityPercent[0] = _percent_1;
        penalityPercent[1] = _percent_2;
    }

    function updateDurations(
        uint256 _stakeDuration,
        uint256 _duration
    ) external onlyOwner {
        stakeDuration = _stakeDuration;
        duration = _duration;
    }

    function updatePhaseeDuration(
        uint256 _phase_duration_1,
        uint256 _phase_duration_2,
        uint256 _phase_duration_3
    ) external onlyOwner {
        phase_duration_1 = _phase_duration_1;
        phase_duration_2 = _phase_duration_2;
        phase_duration_3 = _phase_duration_3;
    }

    function updateAPR_Percent(uint256 _apr) external onlyOwner {
        APR_PERCENT = _apr;
    }

    function updateAdminPercent(uint256 _adminPercent) external onlyOwner {
        adminPercent = _adminPercent;
    }

    function manageAutoRnewal (bool _isAutoDeposit) external {
        UserDetails storage user = users[_msgSender()];
        require (user.depositAmount > 0 && user.stakeTime > 0,'No current staking');
        user.autoDeposit = _isAutoDeposit;
    }

    function stake(uint256 _amount, bool _isAutoDeposit) external {
        require(address(stakeToken) != address(0), "Invalid token");
        require(_amount > 0, "Invalid amount");
        address caller = _msgSender();
        tokenSafeTransferFrom(stakeToken, caller, address(this), _amount);
        internalUpdate(caller, _amount, _isAutoDeposit);
        emit StakeDetails(
            caller,
            _amount,
            _isAutoDeposit,
            uint16(block.timestamp)
        );
    }

    function internalUpdate(
        address _user,
        uint256 _amt,
        bool _isAutoDeposit
    ) internal {
        UserDetails storage user = users[_user];
        user.depositAmount += _amt;
        user.autoDeposit = _isAutoDeposit;
        user.stakeTime = block.timestamp;
        user.endTime = user.stakeTime + stakeDuration;
        user.earnings = 0;
        user.apr = (user.depositAmount * APR_PERCENT / 100e18) * 10 ** rewardToken.decimals();
        user.apr = user.apr / 10 ** stakeToken.decimals();
    }

    function withdraw(bytes calldata signature,uint256 _percent,uint256 _expiry) external {

        address _user = _msgSender();

        bytes32 messageHash = message(_user,_percent,_expiry);
        require(!msgHash[messageHash], "claim: signature duplicate");

        address src = verifySignature(messageHash, signature);
        require(signer == src, " claim: unauthorized");

        UserDetails storage user = users[_user];
        require(user.depositAmount > 0, "Invalid user");
        require(
            block.timestamp > user.stakeTime + phase_duration_1,
            "No unstake on cooling period"
        );
        uint256 reward = this.viewReward(_user);
        rewardValidate(_user, reward,_percent);
        msgHash[messageHash] = true;
    }

    function resetAmt(address _user) internal {
        UserDetails storage user = users[_user];
        user.stakeTime = 0;
        user.endTime = 0;
        user.depositAmount = 0;
        user.autoDeposit = false;
    }

    function amountSpilit(
        uint256 depAmt,
        address user,
        uint256 reward,
        uint256 _fee,
        uint256 _burnPercent
    ) internal {
        tokenSafeTransfer(stakeToken, user, depAmt);

        if (_fee > 0) tokenSafeTransfer(rewardToken, owner(), _fee);

        if (reward > 0) {
            if (_burnPercent > 0 && isBurn) {
                uint256 burnFee = reward * _burnPercent / 100e18;
                reward = reward - burnFee;
                tokenSafeTransfer(rewardToken, burnWallet, burnFee);
            }
            tokenSafeTransfer(rewardToken, user, reward);
            users[user].earnings = reward;
        }

        emit Withdraw(user, depAmt, reward, _burnPercent,uint16(block.timestamp));
    }

    function rewardValidate(address _user, uint256 _reward,uint256 _percent) internal {
        UserDetails storage user = users[_user];
        uint256 adminFee;

        if (
            block.timestamp > user.stakeTime + stakeDuration + duration &&
            user.autoDeposit
        ) {
            internalUpdate(
                _user,
                _reward - ((_reward * adminPercent) / 100e18),
                false
            );
            emit AutoInjection(
                _user,
                user.depositAmount,
                user.stakeTime,
                user.apr
            );
            return;
        } else if (block.timestamp >= user.stakeTime + phase_duration_3) {
            amountSpilit(
                user.depositAmount,
                _user,
                _reward - ((_reward * adminPercent) / 100e18),
                0,
                _percent
            );
            resetAmt(_user);
            return;
        } else if (block.timestamp >= user.stakeTime + phase_duration_2) {
            adminFee = (_reward * adminPercent) / 100e18;
            amountSpilit(
                user.depositAmount,
                _user,
                (((_reward - adminFee) * penalityPercent[1]) / 100e18),
                adminFee,
                _percent
            );
            resetAmt(_user);
            return;
        } else if (
            block.timestamp >= user.stakeTime + phase_duration_1 &&
            block.timestamp <= user.stakeTime + phase_duration_2
        ) {
            adminFee = (_reward * adminPercent) / 100e18;
            amountSpilit(
                user.depositAmount,
                _user,
                (((_reward - adminFee) * penalityPercent[0]) / 100e18),
                adminFee,
                _percent
            );
            resetAmt(_user);
            return;
        }
    }

    function viewReward(address _user) external view returns (uint256 reward) {
        UserDetails storage user = users[_user];

        require(user.depositAmount > 0, "Invalid user");

        uint256 calc;

        if (user.endTime > block.timestamp)
            calc = (block.timestamp - user.stakeTime) / duration;
        else calc = stakeDuration / duration;

        reward = (user.apr / 365) * calc;
    }

    function tokenSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function tokenSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function message(address  _receiver,uint256 _burnPercent,uint256 time)
        public view returns(bytes32 messageHash)
    {
        messageHash = keccak256(abi.encodePacked(_receiver,isBurn,_burnPercent,time));
    }

    function verifySignature(bytes32 _messageHash, bytes memory _signature) public pure returns (address signatureAddress)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(_messageHash);
        signatureAddress = ECDSA.recover(hash, _signature);
    }


}

contract StakeFactory is Ownable {

    event NewStakeContract(address indexed smartChef);
    address[] public stakeAddressList;
    uint public stakePoolCount;


    function deploy (
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _apr,
        bool _activateBurn,
        address _admin,
        address _signer
    ) external onlyOwner {

        require(_stakedToken.totalSupply() >= 0,"revert by staked token");
        require(_rewardToken.totalSupply() >= 0,"revert by reward token");

        bytes memory bytecode = type(Stake).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _apr,_activateBurn,_admin,block.timestamp));
        address payable stakeAddress;

        assembly {
            stakeAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Stake(stakeAddress).initialize(
            _stakedToken,
            _rewardToken,
            _apr,
            _activateBurn,
            _admin,
            _signer
        );
        stakeAddressList.push(stakeAddress);
        stakePoolCount = stakeAddressList.length;

        emit NewStakeContract(stakeAddress);

    }

}