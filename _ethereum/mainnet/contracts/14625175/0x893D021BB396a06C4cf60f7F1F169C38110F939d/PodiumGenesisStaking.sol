//  ____   ___  ____ ___ _   _ __  __ 
// |  _ \ / _ \|  _ \_ _| | | |  \/  |
// | |_) | | | | | | | || | | | |\/| |
// |  __/| |_| | |_| | || |_| | |  | |
// |_|    \___/|____/___|\___/|_|  |_|
//        
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* ----------------------------------------------------------------------------
* Staking for the Podium Genesis NFT
* Note this allows for staking and calculation. No withdrawal exists yet.
* This will be in another contract. Allow people to start earning ASAP.
* Daily staking rate set to 100 as round number. Rate will be multiplied/devided
* With ERC20 implementation
*
/ -------------------------------------------------------------------------- */

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract PodiumGenesisStaking is ERC721Holder, ReentrancyGuard, Ownable, Pausable {

    // Declerations
    // ------------------------------------------------------------------------

    IERC721 public PodiumGenesis; // Podium Genesis NFT to be staked
    uint256 public rewardRate = 66; // Daily reward rate. See above.
    mapping(address => bool) public teamMember; 
    address withdrawContract;

    uint256 public totalStaked;
    mapping(address => uint256) public balanceOfStaked; // Count of staked by Address
    mapping(uint256 => address) public stakedAssetsByToken; // Staked assets and owner
    mapping(address => uint256[]) public stakedAssetsByAddr; // Staked assets and owner
    mapping(address => uint256) public earnedRewards; // Earned so far
    mapping(address => uint256) public dataLastUpdated; // when was address data updated
    mapping(bytes4 => bool) public functionLocked;

    constructor(address _PodiumGenesis) 
    {
        PodiumGenesis = IERC721(_PodiumGenesis);
        teamMember[msg.sender] = true;
    }

    event Staked(
        address indexed addressSender, 
        uint256 quantity, 
        uint256[] tokenIds
    );
    event UnStaked(
        address indexed addressSender, 
        uint256 quantity, 
        uint256[] tokenIds
    );

    // Staking functions and helpers
    // ------------------------------------------------------------------------

    /*
     * @notice Stake 1 or more NFTs
     * @param `tokenIds` a list of NFTs to be staked
    */
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateRewardData {
        require(tokenIds.length > 0, "Need to provide tokenIds");

        uint256 quantity; // Do not use length as safeTransfer check not performed
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            
            PodiumGenesis.safeTransferFrom(msg.sender, address(this), tokenIds[i]);


            stakedAssetsByToken[tokenIds[i]] = msg.sender;
            stakedAssetsByAddr[msg.sender].push(tokenIds[i]);
            quantity++;
        }

        totalStaked += quantity;
        balanceOfStaked[msg.sender] += quantity;
        emit Staked(msg.sender, quantity, tokenIds); 
    }

    /*
     * @notice Withdraw 1 or more NFTs
     * @param `tokenIds` a list of NFTs to be unstaked
     */
    function unstake(uint256[] memory tokenIds) public nonReentrant whenNotPaused updateRewardData {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 quantity;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            // Confirm ownership
            require(
                stakedAssetsByToken[tokenIds[i]] == msg.sender,
                "Staking: Not the staker of the token"
            );
            
            // Replace the unstake with the last in the list
            
            uint256 popped = stakedAssetsByAddr[msg.sender][balanceOfStaked[msg.sender] - 1];
            stakedAssetsByAddr[msg.sender].pop();

            if (popped != tokenIds[i]) {
                uint256 tokenStakeIndex = 0;
                while (stakedAssetsByAddr[msg.sender][tokenStakeIndex] != tokenIds[i]) {
                    tokenStakeIndex++;
                }
                stakedAssetsByAddr[msg.sender][tokenStakeIndex] = popped;
            }

            stakedAssetsByToken[tokenIds[i]] = address(0);
            quantity++;

            // Send back the NFT
            PodiumGenesis.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            balanceOfStaked[msg.sender]--;
            
        }
        totalStaked -= quantity;

        emit UnStaked(msg.sender, quantity, tokenIds);
    }


    /*
     * @notice Modifier called to updateRewards when needed (by stake and unstake, write them)
    */
    modifier updateRewardData() {
        earnedRewards[msg.sender] += _getPending(msg.sender);
        dataLastUpdated[msg.sender] = block.timestamp;
        _;
    }


    /*
     * @notice Update rewards rate for tokens
     * @param `_newReward` new reward value
    */
    function updateRewardRate(uint256 _newReward) public onlyTeamMember {
        rewardRate = _newReward;
    }

    /*
     * @notice How many pending tokens are earned
     * Note this is used internally and added to earned set later
     * @param `account` The address of the staker account
     * @return The amount of pending tokens
    */
    function _getPending(address account) internal view returns (uint256) {
        return
            (   
                (balanceOfStaked[account] * rewardRate) * 
                ((block.timestamp - dataLastUpdated[account]) / 1 days)
            );
    }

    /*
     * @notice Withdraw funds from the child contract
     * @param account for which withdrawal will be done
     * returns amount to be withdrawn
    */
    function withdraw(address account) external onlyWithdrawContract updateRewardData nonReentrant returns(uint256) {
        uint256 withdrawAmount = getEarnedAmount(account);
        earnedRewards[account] = 0;
        return withdrawAmount;
    }


    /*
     * @notice Total ammount earned
     * @param `account` The address of the staker account
     * @return The total ammount earned
    */
    function getEarnedAmount(address account) public view returns (uint256) {
        return earnedRewards[account] + _getPending(account);
    }


    /*
     * @notice Pause used to pause staking if needed
    */
    function pause() external onlyTeamMember {
        _pause();
    }

    /*
     * @notice Unpause used to unpause staking if needed
    */
    function unpause() external onlyTeamMember {
        _unpause();
    }


    /**
     * @dev Throws if called by any account other than team members
     */
    modifier onlyTeamMember() {
        require(teamMember[msg.sender], "Caller is not an owner");
        _;
    }

    /**
     * Add new team meber role with admin permissions
     */
    function addTeamMemberAdmin(address newMember) external onlyTeamMember {
        teamMember[newMember] = true;
    }

    /**
     * Remove team meber role from admin permissions
     */
    function removeTeamMemberAdmin(address newMember) external onlyTeamMember {
        teamMember[newMember] = false;
    }

    /**
     * Returns true if address is team member
     */
    function isTeamMemberAdmin(address checkAddress) public view onlyTeamMember returns (bool) {
        return teamMember[checkAddress];
    }


    /**
     * @dev Throws if called by any account other than team members
     */
    modifier onlyWithdrawContract() {
        require(withdrawContract == msg.sender, "Caller is not withdraw contract");
        _;
    }


    /**
     * Updates contract that can withdraw
     */
    function updateWithdrawContract(address _newWithdrawContract) external lockable onlyTeamMember {
        withdrawContract = _newWithdrawContract;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        require(!functionLocked[msg.sig], "Function has been locked");
        _;
    }


    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyTeamMember {
        functionLocked[id] = true;
    }

     /**
     * Recover tokens accidentally sent to contract without explicit owner
     */
    function strandedRecovery(address to, uint256 tokenId) external onlyTeamMember {
        require(stakedAssetsByToken[tokenId] == address(0), "Token is not in limbo"); 

        PodiumGenesis.safeTransferFrom(address(this), to, tokenId);
    }


}

