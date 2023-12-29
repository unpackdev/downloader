// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// import "./IERC721.sol";
// import "./IERC721Receiver.sol";

// import "./IERC20.sol";
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

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
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

contract StakeNFT {
    //State variabble
    uint private _stakingId = 0;
    uint private _totalStaked = 0;
    address private constant NFTToken = 0x0FCBD68251819928C8f6D182fC04bE733fA94170;
    address private constant REWARDToken = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;

    address private admin;
    uint private constant rate = 36_000_000e18; // per staking for 90 days
    
    uint private constant startTimestamp = 1694332800; // September 10th 2023, 00:00 PST
    uint private endTimestamp = startTimestamp + 90 days; // December 9th 2023, 00:00 PST (default of 90 days staking period)

    bool private _started;

    //constructor
    constructor() {
        admin = msg.sender;
    }

    //enumerator
    enum StakingStatus {
        InActive,
        Active,
        Cancelled
    }

    //structs
    struct Staking {
        address staker;
        address token;
        uint256 tokenId;
        uint256 stakeTime;
        uint256 releaseTime;
        uint256 claimedAmount;
        StakingStatus status;
        uint256 StakingId;
    }

    //mapping
    mapping(address => uint256) private stakedCount;
    mapping(uint256 => Staking) private _StakedItem;

    //event
    event tokenStaked(
        address indexed staker,
        address indexed token,
        uint256 token_id,
        StakingStatus status,
        uint256 StakingId
    );
    event tokenClaimStatus(
        address indexed token,
        uint256 indexed token_id,
        StakingStatus indexed status,
        uint256 StakingId
    );
    event tokenClaimComplete(
        address indexed token,
        uint256 indexed token_id,
        StakingStatus indexed status,
        uint256 StakingId
    );
    event tokenCancelComplete(
        address indexed token,
        uint256 indexed token_id,
        StakingStatus indexed status,
        uint256 StakingId
    );

    //function to call another function
    function callStakeToken(address token, uint256[] memory _tokenID) public {
        require(_started == true, "Staking is paused");

        require(block.timestamp >= startTimestamp, "Staking period not started");
        require(block.timestamp < endTimestamp, "Staking period is over");

        require(token == NFTToken, "incorrect NFT to stake"); // hardcode the NFT smart contract to allow only specific NFT into staking, assume 0xd2...d005 as NFT contract address
        
        require(_tokenID.length > 0, "You have to select tokens to be staked");

        require(
            stakedCount[msg.sender] + _tokenID.length <= 20,
            "you can stake up to 20 tokens"
        );

        stakeToken(_tokenID);
    }

    //function to transfer NFT from user to contract
    function stakeToken(uint256[] memory tokenId) private {
        uint256 releaseTime = block.timestamp;

        require(_totalStaked + tokenId.length <= 500, "max stake amount reached");

        for (uint256 i = 0; i < tokenId.length; i++) {
            IERC721(NFTToken).transferFrom(
                msg.sender,
                address(this),
                tokenId[i]
            ); // User must approve() this contract address via the NFT ERC721 contract before NFT can be transfered

            uint256 currentStakingId = _stakingId;

            Staking memory staking = Staking(
                msg.sender,
                NFTToken,
                tokenId[i],
                releaseTime,
                releaseTime,
                0,
                StakingStatus.Active,
                currentStakingId
            );

            _StakedItem[_stakingId] = staking;
            _stakingId++;
            _totalStaked++;

            emit tokenStaked(
                msg.sender,
                staking.token,
                staking.tokenId,
                staking.status,
                currentStakingId
            );
        }

        stakedCount[msg.sender] += tokenId.length;
    }

    //function to view staked NFT
    function viewStake(uint256 stakingId) public view returns (Staking memory) {
        return _StakedItem[stakingId];
    }

    // function to get list of staked tokens
    function viewMyStakedNfts(address user) external view returns (Staking[] memory) {
        Staking[] memory list = new Staking[](stakedCount[user]);
        uint256 cnt = 0;
        for (uint256 index = 0; index < _stakingId; index++){
            if(_StakedItem[index].staker == user && _StakedItem[index].status == StakingStatus.Active) {
                list[cnt++] = _StakedItem[index];
            }
        }
        return list;
    }

    //function to check NFT stake duration status
    function checkStake(
        uint256 stakingId,
        address staker
    ) public returns (Staking memory) {
        Staking storage staking = _StakedItem[stakingId];

        require(
            staker == msg.sender,
            "You cannot check this staking as it is not listed under this address"
        );
        require(
            staking.status == StakingStatus.Active,
            "Staking is not active or claimed"
        );

        emit tokenClaimStatus(
            staking.token,
            staking.tokenId,
            staking.status,
            staking.StakingId
        );
        return _StakedItem[stakingId];
    }

    //function to claim reward token if NFT stake duration is completed
    function claimReward(uint256 stakingId) public {
        uint256 amount;

        Staking storage staking = _StakedItem[stakingId];

        require(
            staking.staker == msg.sender,
            "You cannot cancel this staking as it is not listed under this address"
        );
        require(
            staking.status == StakingStatus.Active,
            "Your reward is either not claimable yet or has been claimed"
        );

        uint256 maxTimestamp = endTimestamp;
        uint256 curTimestamp = block.timestamp;

        uint256 releaseTime = curTimestamp < maxTimestamp
            ? curTimestamp
            : maxTimestamp;

        if (releaseTime <= staking.releaseTime) return;

        amount = (rate / 90 days) * (releaseTime - staking.releaseTime);

        uint256 balance = IERC20(REWARDToken).balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }

        staking.releaseTime = releaseTime;
        staking.claimedAmount += amount;

        emit tokenClaimComplete(
            staking.token,
            staking.tokenId,
            staking.status,
            staking.StakingId
        );

        if (amount != 0) {
            IERC20(REWARDToken).transfer(msg.sender, amount);
        }
    }

    //function to cancel NFT stake
    function unStake(uint256[] memory stakingId) public {
        require(
            stakingId.length > 0,
            "You have to select tokens to be unstaked"
        );

        for (uint256 i = 0; i < stakingId.length; i++) {
            Staking storage staking = _StakedItem[stakingId[i]];

            claimReward(stakingId[i]);

            staking.status = StakingStatus.Cancelled;
            IERC721(staking.token).transferFrom(
                address(this),
                msg.sender,
                staking.tokenId
            );
            _totalStaked--;
            
            emit tokenCancelComplete(
                staking.token,
                staking.tokenId,
                staking.status,
                staking.StakingId
            );
        }

        stakedCount[msg.sender] -= stakingId.length;
    }

    function withdraw(uint256 amount) public onlyAdmin {
        IERC20(REWARDToken).transfer(msg.sender, amount);
    }

    function toggleStake(bool newStat) public onlyAdmin {
        _started = newStat;
    }

    function setEnd(uint256 newEndTimestamp) public onlyAdmin {
        require(newEndTimestamp > block.timestamp, "Cannot set end in the past");
        require(newEndTimestamp > startTimestamp, "Cannot set end before start");
        require(newEndTimestamp < endTimestamp, "Cannot extend staking period");
        endTimestamp = newEndTimestamp;
    }

    function getRewardRate() external pure returns (uint256) {
        return rate;
    }

    function getNFTAddress() external pure returns (address) {
        return NFTToken;
    }

    function getRewardToken() external pure returns (address) {
        return REWARDToken;
    }

    function getStakingIndex() external view returns (uint256) {
        return _stakingId;
    }

    function getTotalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "OA");
        _;
    }

    function setNewAdmin(address newAdd) external onlyAdmin {
        admin = newAdd;
    }
}