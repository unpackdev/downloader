// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title Gomee reward contract for managing rewards for memes created
 * @author The Tech Alchemy Team
 * @notice You can use this contract for disburse leaderboard rewards and claim winnings
 * @dev All function calls are currently implemented without side effects
 */

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./RewardInterface.sol";

contract Reward is 
    RewardInterface,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     *  @dev Zero Address
     */
    address internal constant ZERO_ADDRESS = address(0);

    /**
     * @dev TOKN contract address
     */
    ERC20Upgradeable internal toknContract;

    /**
     * @dev Treasury contract address
     */
    address internal treasuryAddress;

    /**
     * @dev mapping to store disbursed leaderboard details
     */
    mapping(string => LeaderboardDetails) public registeredLeaderboardDetails;

    /**
     * @dev mapping to store if the winners claimed the meme reward
     */
    mapping(string => mapping(address => bool)) public isRewardClaimed;

    /**
     * @dev mapping to store if address is an admin
     */
    mapping(address => bool) public isAdmin;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize (
        address toknContractAddress,
        address treasuryWalletAddress
    ) public initializer {
        require(
            toknContractAddress != ZERO_ADDRESS,
            "Reward: TOKN address is the zero address"
        );
        require(
            treasuryWalletAddress != ZERO_ADDRESS,
            "Reward: Treasury address is the zero address"
        );
        toknContract = ERC20Upgradeable(toknContractAddress);
        isAdmin[msg.sender] = true;
        treasuryAddress = treasuryWalletAddress;
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice This function utilizes the verifyLeaderboardDetails function 
     * to authenticate the details of the leaderboard.
     * @dev Disburse leaderboard reward details.
     * @dev Only owner or admin can call this function.
     * @param leaderboardDetails Array of leaderboard rewards to be disbursed.
     */
    function disburseLeaderboardRewards(
        LeaderboardDetails[] calldata leaderboardDetails
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant { 
        (, , bool isLeaderboardDetailsValid) = verifyLeaderboardDetails(leaderboardDetails);
        require(    
            isLeaderboardDetailsValid,
            "Reward: Invalid leaderboard details"
        );
        string[] memory disbursedLeaderboardIds = new string[](leaderboardDetails.length);
        for (uint8 index = 0; index < leaderboardDetails.length; index++) {
            LeaderboardDetails calldata disbursedLeaderboardDetails = leaderboardDetails[index];
            registeredLeaderboardDetails[disbursedLeaderboardDetails.leaderboardId] = disbursedLeaderboardDetails;
            disbursedLeaderboardIds[index] = disbursedLeaderboardDetails.leaderboardId; 
        }
        emit LeaderboardRegistered(disbursedLeaderboardIds);
    }

    /**
     * @notice This function utilizes the verifyLeaderboardWinnerDetails function
     * to authenticate the claim leaderboard reward details.
     * @dev Enables a user to claim multiple rewards if they are leaderboard winners.
     * @param leaderboardWinnerDetails Array of leaderboard winners details.
     */
    function claimLeaderboardRewards(
        LeaderboardWinnerDetails[] calldata leaderboardWinnerDetails
    ) public override whenNotPaused nonReentrant {
        (, , bool isClaimRewardValid) = verifyLeaderboardWinnerDetails(leaderboardWinnerDetails);
        require(
            isClaimRewardValid,
            "Reward: Invalid leaderboard reward claim details"
        );
        string[] memory successClaimIds = new string[](leaderboardWinnerDetails.length); 
        uint256 totalTransferAmount = 0;
        for (uint8 index = 0; index < leaderboardWinnerDetails.length; index++) {
            LeaderboardWinnerDetails calldata claimRewardDetail = leaderboardWinnerDetails[index];
            totalTransferAmount += claimRewardDetail.winningAmount;
            isRewardClaimed[claimRewardDetail.leaderboardId][_msgSender()] = true;
            successClaimIds[index] = claimRewardDetail.leaderboardId; 
        }
        if (totalTransferAmount > 0) {
            uint256 balanceOfContract = toknContract.balanceOf(address(this));
            require(
                balanceOfContract > totalTransferAmount,
                "Reward: Contract does not have sufficient balance"
            );
            require(
                toknContract.transfer(_msgSender(), totalTransferAmount),
                "Reward: Transfer token error"
            );
            emit ClaimSuccessful(successClaimIds);
        }
    }

    /**
     * @dev Verify the disburse leaderboard reward details are valid or not.
     * @param leaderboardDetails An array of data which needs to be verified.
     */
    function verifyLeaderboardDetails(
        LeaderboardDetails[] calldata leaderboardDetails
    ) public pure returns (string memory errorMessage, string memory leaderboardId, bool isLeaderboardDetailsValid)
    {
        if (leaderboardDetails.length < 1)
            return ("LeaderboardDetails length is zero", '0', false);
        for (uint8 index = 0; index < leaderboardDetails.length; index++) {
            LeaderboardDetails calldata disburseLeaderboardDetails = leaderboardDetails[index]; 
            if (disburseLeaderboardDetails.leaderboardMerkleRoot == bytes32(0))
               return ("Invalid merkle root", disburseLeaderboardDetails.leaderboardId, false);
            if (!disburseLeaderboardDetails.isleaderboardActive)
                return ("Leaderboard id is not active", disburseLeaderboardDetails.leaderboardId, false);
            if (bytes(disburseLeaderboardDetails.leaderboardId).length == 0) 
                return ("Leaderboard id is zero", disburseLeaderboardDetails.leaderboardId, false);
        }
        return ("Valid leaderboard details", leaderboardDetails[0].leaderboardId, true);
    }

    /**
     * @dev Verify the claim reward data is valid or not.
     * @param leaderboardWinnerDetails The data which needs to be verified.
     */
    function verifyLeaderboardWinnerDetails(
        LeaderboardWinnerDetails[] calldata leaderboardWinnerDetails
    ) public view returns (string memory errorMessage, string memory leaderboardId, bool isLeaderboardWinnerDetailsValid)
    {
        if (leaderboardWinnerDetails.length < 1)
            return ("LeaderboardWinnerDetails length is zero", '0', false); 
        for (uint8 index = 0; index < leaderboardWinnerDetails.length; index++) {
            LeaderboardWinnerDetails calldata leaderboardWinnerDetail = leaderboardWinnerDetails[index];
            if (isRewardClaimed[leaderboardWinnerDetail.leaderboardId][msg.sender])
                return ("Reward is already claimed for this leaderboard id",leaderboardWinnerDetail.leaderboardId,false);
            if (bytes(leaderboardWinnerDetail.leaderboardId).length == 0)
                return ("Leaderboard id is zero", leaderboardWinnerDetail.leaderboardId, false);
            if (leaderboardWinnerDetail.winningAmount < 1)
                return ("Leaderboard winningAmount is zero", leaderboardWinnerDetail.leaderboardId, false);
            bytes32 encodedLeaf = keccak256(
                abi.encode(msg.sender, leaderboardWinnerDetail.winningAmount)
            ); 
            bool isValid = MerkleProofUpgradeable.verify(
                leaderboardWinnerDetail.winnerMerkleProof,
                registeredLeaderboardDetails[leaderboardWinnerDetail.leaderboardId].leaderboardMerkleRoot,
                encodedLeaf
            ); 
            if (!isValid)
                return ("Invalid merkle proof",leaderboardWinnerDetail.leaderboardId,false);  
        }
        return ("Valid leaderboard reward claim details", leaderboardWinnerDetails[0].leaderboardId, true);
    }

    /**
     * @dev Adds a new admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The new admin address for the contract.
     */
    function addAdmin(
        address addressOfAdmin
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(!isAdmin[addressOfAdmin], "Reward: Address already admin");
        require(
            addressOfAdmin != ZERO_ADDRESS,
            "Reward: Admin address is the zero address"
        );
        isAdmin[addressOfAdmin] = true;
        emit AdminAdded(addressOfAdmin);
    }

    /**
     * @dev Remove the admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The admin address to be removed from the contract.
     */
    function removeAdmin(
        address addressOfAdmin
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(isAdmin[addressOfAdmin], "Reward: Address not admin");
        isAdmin[addressOfAdmin] = false;
        emit AdminRemoved(addressOfAdmin);
    }

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateTOKNContract(
        address toknContractAddress
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        require(
            toknContractAddress != ZERO_ADDRESS,
            "Reward: TOKN address is the zero address"
        );
        require(
            toknContractAddress != address(toknContract),
            "Reward: Same as pervious address"
        );
        toknContract = ERC20Upgradeable(toknContractAddress);
        emit TOKNContractUpdated(address(toknContract));
    }

    /**
     * @dev Updates the treasury address of the contract.
     * @dev Only owner can call this function.
     * @param treasuryWalletAddress Address of the treasury for handling funds.
     */
    function updateTreasuryAddress(
        address treasuryWalletAddress
    ) 
    external override onlyOwner whenNotPaused nonReentrant { 
        require(
            treasuryWalletAddress != ZERO_ADDRESS,
            "Reward: Treasury address is the zero address"
        );
        require(
            treasuryWalletAddress != treasuryAddress,
            "Reward: Same as pervious address"
        );
        treasuryAddress = treasuryWalletAddress;
        emit TreasuryAddressUpdated(treasuryAddress);
    }

    /**
     * @notice This function will withdraw to treasury address of the contract. 
     * @dev Withdraw the TOKN from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending TOKN amount.
     */
    function TOKNWithdraw(
        uint256 amount
    ) external override onlyOwner whenNotPaused nonReentrant { 
        uint256 balanceOfContract = toknContract.balanceOf(address(this)); 
        require(
            amount > 0,
            "Reward: Amount is zero"
        );
        require(
            balanceOfContract > (amount - 1),
            "Reward: Contract does not have sufficient balance"
        );
        require(
            toknContract.transfer(treasuryAddress, amount),
            "Reward: Transfer token error"
        );
        emit TOKNWithdrawSuccessful(treasuryAddress);
    }

    /**
     * @dev Retrieves the address of the TOKN contract.
     * @return toknContract The address of the TOKN contract.
     */
    function getTOKNAddress() external view override returns (address) {
        return address(toknContract);
    } 

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice onlyAdminOrOwner modifer allows only admin address to execute the funtions.
     */
  modifier onlyAdminOrOwner() {
        require(
            (_msgSender() == owner() || isAdmin[_msgSender()]),
            "Reward: Caller not admin or owner"
        );
        _;
    }

}