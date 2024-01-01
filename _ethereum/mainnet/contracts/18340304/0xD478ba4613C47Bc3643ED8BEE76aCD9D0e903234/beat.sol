// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) public addressAdmin;

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

    function addAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = false;
    }

    modifier admin() {
        require(
            addressAdmin[msg.sender] == true || owner() == _msgSender(),
            "You do not have auth to do this"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // modifier onlyOwner() {
    //     require(owner() == _msgSender() || addressAdmin[msg.sender] == true, "Ownable: caller is not the owner");
    //     _;
    // }

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

contract BeatToken is ERC20, Ownable {
    uint256 public initialTotalSupply;
    mapping(address => uint256) public stakes;
    mapping(address => bool) public proposerAddress;
    uint256 public totalStaked;
    address public surexTokenAddress;
    uint256 public burnedSureX;
    mapping(uint => Reward) public rewards;
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => uint256)) public userRewards;
    uint public proposalSum;
    uint[] public proposalIds;

    struct Reward {
        uint256 rewardId;
        address rewardTokenAddress;
        uint256 rewardAmount;
        uint256 claimDueDate;
    }

    struct Proposal {
        uint256 proposalId;
        uint256 yesCount;
        uint256 noCount;
        uint256 dueDate;
        address[] yesAddresses;
        address[] noAddresses;
    }

    constructor(address _surexTokenAddress , address coreTeamAddress,
        address techTeamAddress,
        address devFundAddress) ERC20("Beat Token", "BEAT") {
        initialTotalSupply = 500000 * 10 ** 18;
        _mint(address(this), initialTotalSupply);
        surexTokenAddress = _surexTokenAddress;

        // Allocate tokens
        _transfer(
            address(this),
            coreTeamAddress,
            (initialTotalSupply * 5) / 100
        ); // 5%
        _transfer(
            address(this),
            techTeamAddress,
            (initialTotalSupply * 3) / 100
        ); // 3%
        _transfer(
            address(this),
            devFundAddress,
            (initialTotalSupply * 2) / 100
        ); // 2%
    }

    //Update surexToken address
    function updateSTAddr(address _surexTokenAddress) external admin {
        surexTokenAddress = _surexTokenAddress;
    }

    function BurnAndMint(address adminAddr) external admin {
        IERC20 surexToken = IERC20(surexTokenAddress);
        IERC20 beatToken = IERC20(address(this));

        // 1. Check if admin has approved at least 1*10**8 surexToken for this contract
        uint256 approvedAmount = surexToken.allowance(adminAddr, address(this));
        require(
            approvedAmount >= 1 * 10 ** 8 * 10 ** 18,
            "Not enough surexToken approved"
        );

        // 2. Transfer 1*10**8 surexToken from admin to this contract
        surexToken.transferFrom(
            adminAddr,
            address(this),
            1 * 10 ** 8 * 10 ** 18
        );

        // 3. Transfer 50000 BEAT tokens from this contract to admin's address
        uint256 contractBalance = balanceOf(address(this));
        require(
            contractBalance >= 50000 * 10 ** 18,
            "Contract balance not enough"
        );
        beatToken.transfer(adminAddr, 50000 * 10 ** 18);
    }

    // AddProposer and RemoveProposer
    modifier onlyProposer() {
        require(proposerAddress[_msgSender()] == true, "Not a proposer");
        _;
    }

    function addProposer(address _proposer) external admin {
        proposerAddress[_proposer] = true;
    }

    function removeProposer(address _proposer) external admin {
        proposerAddress[_proposer] = false;
    }

    //submit proposal
    function submitProposal(
        uint256 proposal_id,
        uint256 proposal_due_time
    ) external onlyProposer {
        proposals[proposal_id] = Proposal(
            proposal_id,
            0,
            0,
            proposal_due_time,
            new address[](0),
            new address[](0)
        );
        proposalSum += 1;
        proposalIds.push(proposal_id);
    }

    //vote proposal
    // Define the event outside the function
    event UserVoted(
        address indexed user,
        uint256 indexed voteTime,
        bool indexed choice
    );

    function voteProposal(uint proposal_id, bool choice) external {
        Proposal storage p = proposals[proposal_id];

        // 1. Check if proposal is still valid (not outdated)
        require(p.dueDate > block.timestamp, "Proposal outdate");

        // 2. Check if user has already voted
        require(!hasVoted(_msgSender(), p), "You've voted before");

        if (choice) {
            p.yesCount++;
            p.yesAddresses.push(_msgSender());
        } else {
            p.noCount++;
            p.noAddresses.push(_msgSender());
        }

        // Emit the UserVoted event
        emit UserVoted(_msgSender(), block.timestamp, choice);
    }

    // Helper function to check if a user has already voted
    function hasVoted(
        address user,
        Proposal storage p
    ) internal view returns (bool) {
        for (uint i = 0; i < p.yesAddresses.length; i++) {
            if (p.yesAddresses[i] == user) {
                return true;
            }
        }
        for (uint i = 0; i < p.noAddresses.length; i++) {
            if (p.noAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    //Stake beat
    event Staked(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed stakeTime
    );

    function stakeBeat(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0");
        require(
            balanceOf(_msgSender()) - stakes[_msgSender()] >= amount,
            "Insufficient balance"
        );

        // Update the staked amount for the user and the total staked amount
        stakes[_msgSender()] += amount;
        totalStaked += amount;

        // Emit the Staked event
        emit Staked(_msgSender(), amount, block.timestamp);
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(sender, recipient, amount); // Call the parent contract's version of _beforeTokenTransfer
        if (sender != address(this) && sender != address(0)) {
            require(
                amount <= balanceOf(sender) - stakes[sender],
                "You can only transfer unstaked tokens"
            );
        }
    }

    // UnstakeBeat
    event Unstaked(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed stakeTime
    );

    function unstakeBeat() external {
        require(stakes[_msgSender()] > 0, "No staked amount");

        // Check for active votes
        require(
            !hasActiveVote(_msgSender()),
            "You have an active vote and cannot unstake until the vote ends."
        );

        uint256 amountToUnstake = stakes[_msgSender()];
        stakes[_msgSender()] = 0;
        totalStaked -= amountToUnstake;

        // Emit the Unstaked event
        emit Unstaked(_msgSender(), amountToUnstake, block.timestamp);
    }

    // Helper function to check if a user has an active vote
    function hasActiveVote(address user) internal view returns (bool) {
        for (uint i = 0; i < proposalSum; i++) {
            Proposal storage p = proposals[proposalIds[i]];
            for (uint j = 0; j < p.yesAddresses.length; j++) {
                if (p.yesAddresses[j] == user && p.dueDate > block.timestamp) {
                    return true;
                }
            }
            for (uint j = 0; j < p.noAddresses.length; j++) {
                if (p.noAddresses[j] == user && p.dueDate > block.timestamp) {
                    return true;
                }
            }
        }
        return false;
    }

    //Add distribute address and distribute amount
    function addDistributeAddress(
        uint256 reward_id,
        address[] memory address_list,
        uint[] memory amount_list
    ) external admin {
        // 1. Check the lengths of address_list and amount_list
        require(
            address_list.length == amount_list.length,
            "Address list and amount list must have the same length"
        );

        // 2. Record each reward for each address
        for (uint i = 0; i < address_list.length; i++) {
            address user = address_list[i];
            uint256 amount = amount_list[i];
            userRewards[user][reward_id] = amount; // Record the reward amount for the user and rewardId
        }
    }

    //For user to check how much rewards in their account of exact reward id
    function getRewardAmount(
        address user,
        uint rewardId
    ) external view returns (uint256) {
        return userRewards[user][rewardId];
    }

    //New reward distribution
    function newRewardDistribution(
        uint256 reward_id,
        address token_address,
        uint256 reward_amount,
        uint256 claim_due_date
    ) external admin {
        // Ensure that the reward_id is unique and hasn't been used before
        require(rewards[reward_id].rewardId == 0, "Reward ID already exists");

        // Construct a new Reward struct with the provided data
        Reward memory newReward = Reward({
            rewardId: reward_id,
            rewardTokenAddress: token_address,
            rewardAmount: reward_amount,
            claimDueDate: claim_due_date
        });

        // Store the newReward in the rewards mapping
        rewards[reward_id] = newReward;
    }

    //claim reward
    function claimReward(uint256 reward_id) external {
        // Ensure the reward exists
        require(rewards[reward_id].rewardId != 0, "Reward does not exist");

        // Check the reward's due time
        require(
            rewards[reward_id].claimDueDate > block.timestamp,
            "Claim period has ended"
        );

        // Get the reward amount for the user
        uint256 rewardAmount = userRewards[msg.sender][reward_id];
        // Get the balance of the reward token in this contract
        uint256 contractBalance = IERC20(rewards[reward_id].rewardTokenAddress)
            .balanceOf(address(this));
        require(rewardAmount > 0, "No reward to claim for this user");
        require(
            rewardAmount <= contractBalance,
            "Contract's reward balance is not enough"
        );
        require(
            rewardAmount <= rewards[reward_id].rewardAmount,
            "Exceed this reward's max limitation"
        );
        require(
            rewards[reward_id].rewardAmount > 0,
            "This reward has been claimed out"
        );

        // Reset the user's reward to 0 to prevent double claiming
        userRewards[msg.sender][reward_id] = 0;
        rewards[reward_id].rewardAmount -= rewardAmount;
        // Transfer the token to the user's address
        IERC20(rewards[reward_id].rewardTokenAddress).transfer(
            msg.sender,
            rewardAmount
        );
    }

    //Release unclaimed reward
    function releaseUnclaimedReward(uint256 reward_id) external onlyOwner {
        // Ensure the reward exists
        require(rewards[reward_id].rewardId != 0, "Reward does not exist");

        // Check that the reward's claimDueDate has passed
        require(
            rewards[reward_id].claimDueDate < block.timestamp,
            "Claim period not ended yet"
        );

        // Get the balance of the reward token in this contract
        uint256 contractBalance = IERC20(rewards[reward_id].rewardTokenAddress)
            .balanceOf(address(this));

        require(
            rewards[reward_id].rewardAmount <= contractBalance,
            "Contract's balance is not enough"
        );

        // Transfer the remaining balance to the owner
        IERC20(rewards[reward_id].rewardTokenAddress).transfer(
            msg.sender,
            rewards[reward_id].rewardAmount
        );
    }

    function withdrawTokens(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient token balance"
        );
        token.transfer(owner(), amount);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
