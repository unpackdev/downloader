/*
Christmas Box     
$BOX
Welcome to 'Christmas Box', a DApp that captures the essence of the festive season, 
bringing the joy and excitement of Christmas into the world of decentralised applications. 
Inspired by the warmth and generosity of Christmas gift-giving, 
"Christmas Box" offers a unique and engaging experience for users in the blockchain space.

Free to Claim
In the spirit of giving, Christmas Box allows users to get $BOX Coin for free, with a total of 1,226 places available on a first-come, 
first-served basis, splitting 7.43% of the $BOX token.

Grab the Box
By participating in various activities we organize, you can get mystery boxes as rewards. All boxes will be open on the box day. 
Please note: Every 28 boxes can exchange for 1ETH!

FAQ
1. What's In The Box?
Users will get different amounts of $BOX tokens when they open the box.

2. How To Get Box?
Users will get BOX in two ways, 1. by trading and buy $BOX 2. by solving puzzles posted on social media.

3. How To Get Code? If I Enter Three Valid Codes, Can I Get Three Boxes?
Team sends out three puzzles a day via social media and users can get a box if submit the correct answer(code). Users can only get one box per day via code.

4. What Will Happen On The Box Day?
On box day (26th Dec), Users will get a bunch of boxes based on their $BOX balance, and 28 boxes can be converted to 1ETH. Details are as follows:
0.01e<balance<=0.1e equivalent, credit 2 boxes
0.1e<balance<=0.5e equivalent, credit 4 boxes
0.5e<balance<=0.8e equivalent, then credit 8 boxes
0.8e<balance<=1e equivalent, credit 16 boxes
1e<balance<=1e equivalent, then credit 24 boxes.

5. If I Have 28 Boxes, How Do I Get 1ETH?
Users can redeem 1 ETH by destroying these boxes on the box day.
If you have thirty boxes, you can open two boxes and remain the rest 28 boxes to redeem 1 ETH. Please note that opening and destroying boxes are irreversible.

6. Is There A Limit To The Number Of Boxes You Can Get?
There is no limit to the number of boxes you can get.

7. Is There A Limit On The Number Of Free Claims Per Day?
Every user can only claim once. Total 1,226 places available, first-come, first-served.

8. Is There A Time Limit For Getting Boxes?
All boxes should be collected before the box day.

9. Is This Project Taxable?
Yes, every transaction will be charged 5% for tax, including the $BOX tokens gained from free claim.

website:  https://christmasbox.io/
telegram: https://t.me/Christmasbox_Portal
twitter:  https://twitter.com/ChristmasboxERC
*/

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: contract/reward.sol

pragma solidity ^0.8.20;




contract ChristmasTokenReward is Ownable, ReentrancyGuard {
    event e_ClaimReward(uint256 value, address from, uint256 nonce);
    // Token for rewards
    address public RewardTokenAddress = address(0);
    address public signer = address(0);
    uint256 public rewardMaxAmount = 2480348 * 1e18; // 12.26% of 20,231,226
    uint256 public freeClaimMaxAmount = 1503076 * 1e18; // (christmas * christmas) 7.43% of 20,231,226
    uint16 public freeClaimedCount = 0; // free claim count < 1226
    uint256 public freeClaimAmount = 1226 * 1e18; // free claim amount
    mapping(address => bool) public freeClaimed; // free claim amount total
    mapping(address => uint256) public Claimed; // user's reward amount total
    mapping(address => uint256) public claimNonceMap; // user's claimed amount total
    constructor(address rewardToken, address _signer) Ownable(msg.sender) {
        require(rewardToken != address(0), "Invalid reward token address");
        RewardTokenAddress = rewardToken;
        require(
            IERC20(RewardTokenAddress).totalSupply() >
                (rewardMaxAmount + freeClaimMaxAmount),
            "Invalid reward token supply"
        );
        require(_signer != address(0), "Invalid signer address");
        signer = _signer;
    }
    function initialize() external onlyOwner {
        require(balanceOfRewardToken() == 0, "initialized");
        require(
            IERC20(RewardTokenAddress).balanceOf(msg.sender) >=
                (rewardMaxAmount + freeClaimMaxAmount),
            "Invalid reward token balance"
        );
        safeTransferFrom(
            RewardTokenAddress,
            msg.sender,
            address(this),
            (rewardMaxAmount + freeClaimMaxAmount)
        );
    }
    // Reward part
    // ClaimRewards:
    function ClaimRewards(
        uint256 amount,
        uint256 claimNonce,
        uint256 deadline,
        bytes memory signature
    ) external nonReentrant returns (bool) {
        require(balanceOfRewardToken() > 0, "insufficient reward balance");
        (uint256 reward, bool freeClaim) = CalculateReward(
            amount,
            claimNonce,
            deadline,
            signature
        );
        require(
            balanceOfRewardToken() - reward > 0,
            "Insufficient reward balance"
        );
        require(
            withinAnHour(deadline) == true,
            "Deadline is not within an hour"
        );
        if (reward == 0) {
            return false;
        }
        if (freeClaim == true) {
            freeClaimedCount++;
            freeClaimed[msg.sender] = true;
        }
        Claimed[msg.sender] += reward;
        claimNonceMap[msg.sender] += 1;
        _claimRewards(reward, claimNonce);
        return true;
    }
    function CalculateReward(
        uint256 amount,
        uint256 claimNonce,
        uint256 deadline,
        bytes memory signature
    ) public view returns (uint256 reward, bool freeClaim) {
        // 1. check if free claim avaliable
        // free claim = 1226*1e18
        if (freeClaimed[msg.sender] == false) {
            if (freeClaimedCount < 1226) {
                freeClaim = true;
                reward += freeClaimAmount;
            }
        }
        // 2. check if claim nonce is valid
        require(
            claimNonce == getNextClaimNonce(msg.sender),
            "Invalid claim nonce"
        );
        // 3. verify signature by signer
        require(
            _verifySignature(amount, claimNonce, deadline, signature) == true,
            "Invalid signature"
        );
        // 4. calculate reward
        reward += amount;
        // 5. return reward
        return (reward, freeClaim);
    }
    function _verifySignature(
        uint256 amount,
        uint256 claimNonce,
        uint256 deadline,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 messageHash = getMessageHash(
            amount,
            msg.sender,
            claimNonce,
            deadline
        );
        address recoveredAddress = ECDSA.recover(messageHash, signature);
        if (recoveredAddress != signer) {
            return false;
        }
        return true;
    }
    function getMessageHash(
        uint256 amount,
        address sender,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(amount, sender, nonce, deadline))
                )
            );
    }
    function _claimRewards(uint256 amount, uint256 claimNonce) private {
        _transferRewardToken(msg.sender, amount);
        emit e_ClaimReward(amount, msg.sender, claimNonce);
        return;
    }
    function _transferRewardToken(
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(RewardTokenAddress).transfer(to, amount);
    }
    function getNextClaimNonce(address sender) public view returns (uint256) {
        return claimNonceMap[sender] + 1;
    }
    function withinAnHour(uint256 deadline) public view returns (bool) {
        if (deadline > block.timestamp) {
            return (deadline - block.timestamp) <= 3600;
        } else {
            return false;
        }
    }
    function balanceOfRewardToken() public view returns (uint256) {
        return IERC20(RewardTokenAddress).balanceOf(address(this));
    }
    function renounceOwnership() public virtual override onlyOwner {
        require(signer != address(0), "signer is not set");
        _transferOwnership(address(0));
    }
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20: TRANSFER_FROM_FAILED"
        );
    }
    function _setSigner(address _signer) public onlyOwner returns (bool) {
        signer = _signer;
        return true;
    }
}