// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/*

Telegram -  https://t.me/joecoinportal
Twitter -   https://twitter.com/joecoin_
Website -   https://thejoecoin.com/
Merch Website: https://www.joecoinmerch.com/

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@* *+::. .::+  %#:.::.=@@@@@@@@@- *@@=.::.:+@@* .::::+#.-@@@@-.#+ :::::+@= ::::.+@@@@@
@@@@@* *@@@+ =@@@  @- *@@*:+@@@@@@@@: *%  #@@@# -@* #@@@@@@+ *@@# +@= %@@@@@@= %@@@: %@@@@
@@@@@* *@@@* =@@@@@@%=-:.:=%@@@@@@@@: *+ :@@@@@: @* .::::#@@:.%%.:@@= .::::#@= .:...*@@@@@
@@@@@* *@@@* =@@@@@@.-@@@#  @@@@%-#@: *#  %@@@% -@+ *@@@@@@@% -  %@@= %@@@@@@= %@%: *@@@@@
@@@@@* *@@@* +@@@@@@*:.::.-#@@@@@:.: :@@%=.:::.=%@* .::::-@@@+  *@@@= .::::=@= %@@@- =@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***+++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#**********#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###**********#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%####*******####%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%%####******##%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%%##########%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%%%%#########%%%%###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%%%%%########%%%%####%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%%%%########%%@%#####%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%%%########%%@%#**#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@%%%%########%%%@%%###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%%%%%########%%@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%%%%#######%%%%@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%########%%%@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%######%%%%@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%######%%%%%###**%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##***#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#++**##*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*++====+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#***+++++#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*******#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#**#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@####@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/
contract JoeBranding {

}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)



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


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)




// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)




// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)



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


/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}





interface IAuction { 
    //Total supply is 1b *10^18. log_2 (1b *10^18) < 90

    struct AuctionEntry {
        uint96 CurrentUserBid;
        uint40  BidTime;
    }

    /// @notice Claims a reward for a winner
    /// @dev Claims a reward for a winner
    function ClaimReward() external;

    /// @notice Returns a current state of Auction
    /// @dev Returns a current state of Auction
    /// @return bool true if auction is active, false - otherwise
    function IsAlive() external view returns (bool);

    /// @notice Placing a new bid or resizing user bid
    /// @dev Placing a new bid or resizing user bid
    /// @param bidSize New absolute size of user Bid
    function PlaceBid(uint256 bidSize) external;

    /// @notice Refunds outbid users
    /// @dev Refunds outbid users
    function RedeemRefund() external;

    
    /// @notice Returns current bid increment required to outbid previous user
    /// @dev Returns current bid increment required to outbid previous user
    /// @return uint96 bid increment
    function BidIncrement() external view returns (uint96);
    
    /// @notice Returns current auction time window when end time is extended
    /// @dev Returns current auction time window when end time is extended
    /// @return uint40 auction time window
    function AuctionTimeExtraWindow() external view returns (uint40);
    
    /// @notice Returns current Joe Merch NFT contract used to reward user
    /// @dev Returns current Joe Merch NFT contract used to reward user
    /// @return address Address of Joe Merch NFT contract
    function MerchNft() external view returns (address);
    
    /// @notice Returns timestamp when current Auction stops(-ed), inclusive
    /// @dev Returns timestamp when current Auction stops(-ed), inclusive
    /// @return uint40 Auction end time (same units as block.timestamp)
    function AuctionEndTime() external view returns (uint40);
    
    /// @notice Returns time when current Auction has been launched
    /// @dev Returns time when current Auction has been launched
    /// @return uint40 Auction start time (same units as block.timestamp)
    function AuctionStartTime() external view returns (uint40);
    
    /// @notice Returns current best bid wallet -or- 0xfffff..fff
    /// @dev Returns current best bid wallet -or- 0xfffff..fff
    /// @return address Current best bid wallet
    function BestBidWallet() external view returns (address);
    
    /// @notice Returns status of user's Bid
    /// @dev Returns status of user's Bid
    /// @return CurrentUserBid Current user's bid size
    /// @return BidTime Auction start timestamp described associated auction
    function Bids(address wallet) external view returns (uint96 CurrentUserBid, uint40 BidTime);

    event AuctionLaunched(
        uint256 indexed StartTime,
        uint256 indexed EndTime,
        uint256 StartBid
    );

    event RewardIssued(
        uint256 indexed AuctionStartTime,
        address indexed Wallet,
        uint256 indexed BidSize
    );

    event BidPlaced(
        address indexed Wallet,
        uint256 indexed AuctionStartTime,
        uint256 Size,
        uint256 AuctionEndTime,
        int256 Transferred
    );

    event RefundClaimed(
        address indexed Wallet,
        uint256 indexed AuctionStartTime,
        uint256 Size
    );
}




interface IJoeMerchNft {
    function Mint(address user) external;
}

abstract contract JoeAuctionsGeneric is JoeBranding, Ownable2Step, IAuction {
    constructor(address owner, address executor) 
        Ownable(owner) {

        Executor = executor;

        AuctionEntry memory emptyBid;

        emptyBid.BidTime = 1; //Gas saving
        emptyBid.CurrentUserBid = 0; 
        //emptyBid.Refund = 0;

        Bids[_bestBidDefault()] = emptyBid;
        BestBidWallet = _bestBidDefault();
    }


    address                             public              Executor;
    uint40                              public              AuctionEndTime;
    uint40                              public              AuctionStartTime;

    address                             public              BestBidWallet;
    mapping(address => AuctionEntry)    public              Bids;
    uint96                              public              WithdrawBalance;




    function _bidToken() internal virtual view returns (IERC20);
    function _bestBidDefault() internal virtual view returns (address);
    function _bidIncrement() internal virtual view returns (uint96);
    function _auctionTimeExtraWindow() internal virtual view returns (uint40);
    function _nftReward() internal virtual view returns (IJoeMerchNft);


    modifier onlyExecutor() {
        require(Executor == _msgSender(), "Unauthorized (E)");
        _;
    }

    //May be replace this function with some other "emergency" or "anti-stuck" measures?
    function Multicall(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] memory calldatas
       )
    public virtual payable onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call{value: values[i]}(calldatas[i]);

            require(success, "Unable to perfroma a call");
        }
    }

    function SetExecutor(address executor) public onlyOwner {
        Executor = executor;
    }

    function Withdraw() public onlyExecutor {
        uint256 withdrawAmount = WithdrawBalance;

        WithdrawBalance = 0;

        _bidToken().transfer(owner(), withdrawAmount);
    }

    function LaunchAuction(uint40 endTime, uint96 minBid) public onlyExecutor {
        require(!IsAlive(), "Auction in place, cannot start new");

        _issueUserReward();

        AuctionEndTime = endTime;
        AuctionStartTime = uint40(block.timestamp);

        BestBidWallet = _bestBidDefault();
        Bids[_bestBidDefault()].CurrentUserBid = minBid;

        emit AuctionLaunched(block.timestamp, endTime, minBid);
    }

    function ClaimReward() public {
        require(BestBidWallet == _msgSender(), "Only a winner can claim the reward");

        _issueUserReward();
    }

    function _issueUserReward() private {
        if (IsAlive())
            return;

        address bestBidUser = BestBidWallet;

        if (bestBidUser != _bestBidDefault() && (Bids[bestBidUser].CurrentUserBid != 0)) {
            uint96 bidSize = Bids[bestBidUser].CurrentUserBid;
            WithdrawBalance += bidSize;
            Bids[bestBidUser].CurrentUserBid = 0;

            _nftReward().Mint(bestBidUser);        
            
            emit RewardIssued(Bids[bestBidUser].BidTime, bestBidUser, bidSize);
        }
    }

    function _isAlive(uint40 endTime) private view returns (bool) {
        return block.timestamp <= endTime;
        
    }

    function IsAlive() public view returns (bool) {
        return _isAlive(AuctionEndTime);
    }

    function PlaceBid(uint256 bidSize) public {
        require(_msgSender().code.length == 0, "Only EOA can place a bids");
        require(bidSize < type(uint96).max, "bidSize too big");

        uint40 auctionEndTime = AuctionEndTime;
        require(_isAlive(auctionEndTime), "No active auctions");
        require(
            bidSize >= (Bids[BestBidWallet].CurrentUserBid + _bidIncrement()),
            "New bid shall be greater or equal on BidIncrement to current best bid"
        );
        
        AuctionEntry memory userEntry = Bids[_msgSender()];

        int256 transferDelta = int256(bidSize) - int96(userEntry.CurrentUserBid);
        userEntry.BidTime = AuctionStartTime;
        userEntry.CurrentUserBid = uint96(bidSize);

        Bids[_msgSender()] = userEntry;
        BestBidWallet = _msgSender();
        
        if ((auctionEndTime - block.timestamp) < _auctionTimeExtraWindow())
        {
            auctionEndTime = uint40(block.timestamp) + _auctionTimeExtraWindow();
            AuctionEndTime = auctionEndTime;
        }

        if (transferDelta > 0)
            _bidToken().transferFrom(_msgSender(), address(this), uint256(transferDelta));
        else if (transferDelta < 0)
            _bidToken().transfer(_msgSender(), uint256(-transferDelta));

        emit BidPlaced(
                _msgSender(), 
                userEntry.BidTime,
                bidSize,
                auctionEndTime,
                transferDelta
            );
    }

    function RedeemRefund() public {
        AuctionEntry memory userEntry = Bids[_msgSender()];
        uint40 auctionStartTime = AuctionStartTime;

        //if user in the competition
        if (
            IsAlive() 
            &&
            (userEntry.BidTime == auctionStartTime)
        )
            return;

        // if user won
        if (BestBidWallet == _msgSender())
            return;

        if (userEntry.CurrentUserBid == 0)
            return;

        uint256 repayAmount = userEntry.CurrentUserBid;
        userEntry.CurrentUserBid = 0;
        Bids[_msgSender()] = userEntry;

        _bidToken().transfer(_msgSender(), repayAmount);

        emit RefundClaimed(_msgSender(), auctionStartTime, repayAmount);
    }

}



contract JoeAuctionsMainnet is JoeAuctionsGeneric {
    constructor(address owner, address executor)
    JoeAuctionsGeneric(owner, executor) {
        BidIncrement = 1000 ether; //ether
        AuctionTimeExtraWindow = 15 minutes;
    }


    function _bidToken() internal override pure returns (IERC20) { return IERC20(0x76e222b07C53D28b89b0bAc18602810Fc22B49A8); }
    function _bestBidDefault() internal override pure returns (address) { return address(type(uint160).max); }
    function _bidIncrement() internal override view returns (uint96) { return BidIncrement; }
    function _auctionTimeExtraWindow() internal override view returns (uint40) { return AuctionTimeExtraWindow; }    
    function _nftReward() internal override view returns (IJoeMerchNft) { return IJoeMerchNft(MerchNft); }

    uint96                              public              BidIncrement;
    uint40                              public              AuctionTimeExtraWindow;
    address                             public              MerchNft;

    function SetBidIncrement(uint96 newValue) public onlyOwner {
        BidIncrement = newValue;
    }
    
    function SetAuctionTimeExtraWindow(uint40 newValue) public onlyOwner {
        AuctionTimeExtraWindow = newValue;
    }

    function SetMerchNft(address newValue) public onlyOwner {
        MerchNft = newValue;
    }
}