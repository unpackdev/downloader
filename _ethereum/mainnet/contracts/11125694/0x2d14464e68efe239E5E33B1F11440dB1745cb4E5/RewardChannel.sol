pragma solidity ^0.4.20;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract RewardChannel {
    address _owner;
    IERC20 reward_token;
    claimRecord[] claimHistory;
    claimRecord[] pending;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function moveToNewChannel(address newChannel) public onlyOwner {
        require(newChannel != address(0));
        uint256 bal = reward_token.balanceOf(address(this));
        reward_token.transfer(newChannel, bal);
    }

    struct claimRecord {
        uint256 amount;
        uint256 blcok_number;
        uint256 expired_block;
        bytes sig;
        address receiver;
    }

    function RewardChannel(IERC20 _reward_token) public payable {
        _owner = msg.sender;
        reward_token = _reward_token;
    }

    function claimReward(
        uint256 amount,
        uint256 expired_block,
        bytes signature
    ) public {
        clear_pending_list();
        require(amount != 0);
        bool signature_not_exist = true;
        for (uint256 i = 0; i < claimHistory.length; i++) {
            claimRecord memory record = claimHistory[i];
            if (signature_compare(signature, record.sig) == true) {
                signature_not_exist = false;
            }
            if (block.number > record.expired_block) {
                delete (claimHistory[i]);
            }
        }
        require(signature_not_exist);
        bytes32 message = keccak256(msg.sender, amount, expired_block);
        require(recoverSigner(message, signature) == _owner);
        require(block.number < expired_block);
        claimRecord memory newRecord = claimRecord({
            amount: amount,
            blcok_number: block.number,
            expired_block: expired_block,
            sig: signature,
            receiver: msg.sender
        });
        claimHistory.push(newRecord);
        pending.push(newRecord);
    }

    function signature_compare(bytes a, bytes b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function clear_pending_list() public {
        for (uint256 i = 0; i < pending.length; i++) {
            claimRecord memory record = pending[i];
            if (is_duplicate(record.sig) == false) {
                safeTGXTransfer(record.receiver, record.amount);
            } else {
                delete (pending[i]);
            }
        }
        delete (pending);
    }

    function is_duplicate(bytes sig) internal view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < pending.length; i++) {
            claimRecord memory record = pending[i];
            if (signature_compare(sig, record.sig) == true) {
                if (count == 1) {
                    return true;
                }
                count++;
            }
        }
        return false;
    }

    function safeTGXTransfer(address _to, uint256 _amount) internal {
        uint256 reward_pool_balance = reward_token.balanceOf(address(this));
        if (_amount > reward_pool_balance) {
            reward_token.transfer(_to, reward_pool_balance);
        } else {
            reward_token.transfer(_to, _amount);
        }
    }

    function splitSignature(bytes sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}