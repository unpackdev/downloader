// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: ShieldStakingMainnet.sol

//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.0;




    
contract ShieldStaking is Ownable {

    IERC20 public token;
    IERC721 public nft;

    constructor( address _token, address _nft, address _treasury) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        treasury = _treasury;
    }

    bool public stakingPaused = true;

    address treasury;
   
    uint256 public tokensStaked = 0;//total tokens staked

    uint256 public stakers = 0;//total wallets staking 

    uint256 public totalEthPaid = 0;//total eth paid out

    uint256 public rate1 = 50;//No NFTs

    uint256 public rate2 = 80;//1 NFT

    uint256 public rate3 = 90;//2 NFTs

    uint256 public rate4 = 100;//3 NFTs

    uint256 public stakeTime1 = 3888000;//45 Days

    uint256 public nftFund = 0;//The amount of rewards not sent from people not having 3 Shield NFTs
 
    uint256 public earlyClaimFee1 = 10;

    uint256 public minStake = (1000 * 10**18);

    uint256 public lastUpdateTime = block.timestamp;

    uint256 public tokensXseconds = 0;

    uint256 public ethDeposits = 0;

    function setStakingPaused(bool _state) public onlyOwner{     
        stakingPaused = _state;
    }

    function setRate1(uint256 _rate1) public onlyOwner{    
        rate1 = _rate1;    
    }

    function setRate2(uint256 _rate2) public onlyOwner{    
        rate2 = _rate2;    
    }

    function setRate3(uint256 _rate3) public onlyOwner{    
        rate3 = _rate3;    
    }

    function setRate4(uint256 _rate4) public onlyOwner{    
        rate4 = _rate4;    
    }

    function setStakeTime1(uint256 _stakeTime1) public onlyOwner{    
        stakeTime1 = _stakeTime1;    
    }

    function setTreasury(address _treasury) public onlyOwner{     
        treasury = _treasury;   
    }

    function setEarlyClaimFee1(uint256 _earlyClaimFee1) public onlyOwner {
        require(_earlyClaimFee1 <= 30, "fee to high try again, 30% max");     
        earlyClaimFee1 = _earlyClaimFee1;   
    }

    function setMinStake(uint256 _minStake) public onlyOwner{     
        minStake = _minStake;   
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    struct StakerVault {
        uint256 tokensStaked;
        uint256 shields;
        uint256 stakeDuration;
        uint256 tokensXseconds;
        uint256 rewardsRate;
        uint256 stakedSince;
        uint256 stakedTill;
        uint256 lastClaimTime;
        uint256 lastClaimNumber;
        uint256 ethClaimed;
        bool isStaked;
    }

    struct EthDeposit {
        uint256 timestamp;
        uint256 ethAmt;
        uint256 tokensXseconds;
    }

    mapping(address => StakerVault) public stakerVaults;
    mapping(uint256 => EthDeposit) public EthDeposits;

    //The following is going to be a function that will keep track of the tokensXseconds for the contract as a whole
    //This function will need to be called each time tokens come in or leave the contract such as stake / unstake

    function updateGlobalTokensXseconds() internal {
        uint256 addAmt = 0; 
        addAmt += (block.timestamp - lastUpdateTime) * tokensStaked;
        tokensXseconds += addAmt;
        lastUpdateTime = block.timestamp;
    }

    function updateUserTokensXseconds() internal {
        uint256 addAmt = 0;
        addAmt += (block.timestamp - stakerVaults[msg.sender].lastClaimTime) * stakerVaults[msg.sender].tokensStaked;
        stakerVaults[msg.sender].tokensXseconds += addAmt;
        stakerVaults[msg.sender].lastClaimTime = block.timestamp;
    }

    function calculateRewardsRate () internal {
        stakerVaults[msg.sender].shields = IERC721(nft).balanceOf(msg.sender);

        if (stakerVaults[msg.sender].shields == 0 && stakerVaults[msg.sender].stakeDuration == stakeTime1) { 
            stakerVaults[msg.sender].rewardsRate = rate1;
        }

        if (stakerVaults[msg.sender].shields == 1) { 
            stakerVaults[msg.sender].rewardsRate = rate2;
        }

        if (stakerVaults[msg.sender].shields == 2) { 
            stakerVaults[msg.sender].rewardsRate = rate3;
        }

        if (stakerVaults[msg.sender].shields >= 3) { 
            stakerVaults[msg.sender].rewardsRate = rate4;
        }
    }

    function stake(uint256 _amount) public {
        require(stakingPaused == false, "STAKING IS PAUSED");
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);

        require(userBalance >= _amount, "Insufficient Balance");
        require((_amount + stakerVaults[msg.sender].tokensStaked) >= minStake, "You Need More Tokens To Stake");
        
        updateGlobalTokensXseconds();
        uint256 claimableEth = viewClaimableEth(msg.sender); 
 
        if (claimableEth > 0) {   
            claimEth(); 
        }

        token.approve(address(this), _amount);
        token.approve(treasury, _amount);
        token.transferFrom(msg.sender, treasury, _amount);
        
        if (stakerVaults[msg.sender].isStaked == true) {
            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked += _amount;
            tokensStaked += _amount;
        }

        if (stakerVaults[msg.sender].isStaked == false) {
            uint256 nftBalance = IERC721(nft).balanceOf(msg.sender);
            stakerVaults[msg.sender].stakeDuration = stakeTime1;
            stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime1;
            stakerVaults[msg.sender].tokensStaked += _amount;
            stakerVaults[msg.sender].stakedSince = block.timestamp;
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].shields = nftBalance;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;

            calculateRewardsRate();
        
            tokensStaked += _amount;
            stakers += 1;    
        }
    }

    function unStake(uint256 _tokens) public {
        require(stakerVaults[msg.sender].tokensStaked >= _tokens, "You don't have that many tokens");
        require(token.balanceOf(treasury) >= _tokens, "Not Enough Funds In Treasury");
        require(!stakingPaused, "Staking is paused"); 
        require(stakerVaults[msg.sender].isStaked == true);

        uint256 claimableEth = viewClaimableEth(msg.sender); 
 
        if (claimableEth > 0) {   
            claimEth(); 
        }

        updateGlobalTokensXseconds();

        uint256 remainingStake = stakerVaults[msg.sender].tokensStaked - _tokens;
        uint256 unstakedTokens = 0;
        uint256 penalizedTokens = 0;
        uint256 claimedTokens = 0;

        if (remainingStake < minStake) {
            unstakedTokens = stakerVaults[msg.sender].tokensStaked;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp && stakerVaults[msg.sender].stakeDuration == stakeTime1) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transferFrom(treasury, msg.sender, claimedTokens), "Tokens could not be sent to Staker");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transferFrom(treasury, msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            stakerVaults[msg.sender].tokensStaked = 0;
            stakerVaults[msg.sender].shields = 0;
            stakerVaults[msg.sender].stakeDuration = 0;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].rewardsRate = 0;
            stakerVaults[msg.sender].stakedSince = 0;
            stakerVaults[msg.sender].stakedTill = 0;
            stakerVaults[msg.sender].lastClaimTime = 0;
            stakerVaults[msg.sender].lastClaimNumber = 0;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].isStaked = false;

            tokensStaked -= unstakedTokens;
            stakers --;
        }

        if (remainingStake >= minStake) {
            unstakedTokens = _tokens;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp && stakerVaults[msg.sender].stakeDuration == stakeTime1) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transferFrom(treasury, msg.sender, claimedTokens), "Tokens could not be sent to Staker");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transferFrom(treasury, msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked -= unstakedTokens;

            tokensStaked -= unstakedTokens;
        }
    }

    function claimEth() public { 
        require(stakerVaults[msg.sender].lastClaimNumber < ethDeposits);
        require(stakerVaults[msg.sender].isStaked == true);
        calculateRewardsRate();
            
        uint256 claimableEth = 0;

            for (uint256 i = stakerVaults[msg.sender].lastClaimNumber; i < ethDeposits; i++) {
                 if (stakerVaults[msg.sender].tokensXseconds == 0) {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;
                    uint256 stakerTokensXseconds = (time * stakerVaults[msg.sender].tokensStaked);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }
                
                if (stakerVaults[msg.sender].tokensXseconds > 0) {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;//this needs correcting
                    uint256 stakerTokensXseconds = ((time * stakerVaults[msg.sender].tokensStaked) + stakerVaults[msg.sender].tokensXseconds);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].tokensXseconds = 0;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }      
            }

        uint256 ethSentToStaker = (claimableEth * stakerVaults[msg.sender].rewardsRate) / 100;
        payable(msg.sender).transfer(ethSentToStaker); 
        uint256 ethToNftFund = claimableEth - ethSentToStaker;

        if (ethToNftFund > 0) {
            payable(treasury).transfer(ethToNftFund);
        }
        
        stakerVaults[msg.sender].ethClaimed += ethSentToStaker;
        totalEthPaid += ethSentToStaker;
        nftFund += ethToNftFund;
    }

    function viewRewardsRate (address user) public view returns (uint256) { 
       
        uint256 shield = IERC721(nft).balanceOf(user); 
        uint256 rate = 0;
 
        if (shield == 0 && stakerVaults[user].stakeDuration == stakeTime1) {  
            rate = rate1; 
        } 
 
        if (shield == 1) {  
            rate = rate2; 
        } 
 
        if (shield == 2) {  
            rate = rate3; 
        } 
 
        if (shield >= 3) {  
            rate = rate4; 
        } 
        return rate; 
    } 
 
    function viewClaimableEth(address user) public view returns(uint256 amount) {
        uint256 rate = viewRewardsRate(user);
        uint256 claimTime = stakerVaults[user].lastClaimTime;
        uint256 claimNumber = stakerVaults[user].lastClaimNumber;
        uint256 ethSentToStaker = 0;
        uint256 claimableEth = 0;
        uint256 stakerTokensXseconds = stakerVaults[user].tokensXseconds;

        for (uint256 i = claimNumber; i < ethDeposits; i++) { // Changed ethDeposits to ethDeposits.length
            if (stakerVaults[user].tokensXseconds == 0) {
                uint256 time = EthDeposits[i+1].timestamp - claimTime; // Changed stakerVaults[user].lastClaimTime to claimTime
                stakerTokensXseconds = time * stakerVaults[user].tokensStaked;
                uint256 claimablePercentage = (stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds;
                claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                ethSentToStaker = claimableEth * rate / 100;
                claimTime = EthDeposits[i+1].timestamp;
                claimNumber++;
            }

            if (stakerVaults[user].tokensXseconds > 0) {
                uint256 time = EthDeposits[i+1].timestamp - stakerVaults[user].lastClaimTime;
                uint256 claimableTokensXseconds = (time * stakerVaults[user].tokensStaked) + stakerTokensXseconds;
                uint256 claimablePercentage = (claimableTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds;
                claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                ethSentToStaker = claimableEth * rate / 100;
                stakerTokensXseconds = 0;
                claimTime = EthDeposits[i+1].timestamp;
                claimNumber++;
            }
        }

        return ethSentToStaker;
    }

    function DepositEth(uint256 _weiAmt) external payable onlyOwner { 
        require(_weiAmt > 0, "Amount sent must be greater than zero"); 
        updateGlobalTokensXseconds(); 
        payable(address(this)).transfer(_weiAmt); 
        uint256 index = (ethDeposits + 1); 
        EthDeposits[index] = EthDeposit(block.timestamp, _weiAmt, tokensXseconds); 
        tokensXseconds = 0; 
        lastUpdateTime = block.timestamp; 
        ethDeposits ++; 
    }

    receive() external payable {
    }
}