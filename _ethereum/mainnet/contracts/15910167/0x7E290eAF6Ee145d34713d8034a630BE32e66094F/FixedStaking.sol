// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./Fixed.sol";
import "./Token.sol";

/// @title vvrrbb staking functionality to earn vvddrr.
/// @author Osman Ali.
/// @notice Use this contract to stake your ERC721 vvrrbb mining rig token and earn vvddrr.
contract FixedStaking is IERC721Receiver, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    /// @notice The contract address of the ERC721 mining token.
    address public miningTokenAddress;

    /// @notice The contract address of the vvddrr ERC20 token.
    address public vvddrrTokenAddress;

    /// @notice A boolean used to allow only one setting of the mining token.
    bool miningTokenSet;

    /// @notice A boolean value used to allow only one setting of the mining token address.
    bool miningTokenAddressSet;

    /// @notice A boolean used to allow only one setting of the vvddrr token.
    bool vvddrrTokenSet;

    /// @notice A boolean value used to allow only one setting of the vvddrr token address.
    bool vvddrrTokenAddressSet;

    /// @notice Interface contract reference for the ERC721 token that is being staked.
    /// @dev This is given a generalized name and can be any ERC721 collection.
    IERC721 public miningToken;

    /// @notice Interface contract reference for the ERC20 token that is being used a staking reward.
    /// @dev This can be any ERC20 token but will be vvddrr in this case.
    IERC20 public vvddrrToken;

    /// @notice The amount of ERC20 tokens received as a reward for every block an ERC721 token is staked.
    /// @dev Expressed in Wei.
    // Reference: https://ethereum.org/en/developers/docs/blocks/
    // Reference for merge: https://blog.ethereum.org/2021/11/29/how-the-merge-impacts-app-layer/
    uint256 public tokensPerBlock = 3805175038100;

    /// @notice A general constant for use in percentage basis point conversion and calculation.
    uint256 public constant BASIS = 10_000;

    /// @notice The tokensPerBlock value used a constant for initial burn capitalization.
    /// @dev Required so that an empty value is not used for a user's initial burn.
    uint256 public constant INITIAL_BURN_CAPITALIZATION = 3805175038100;

    /// @notice A Stake struct represents how a staked token is stored.
    struct Stake {
        address user;
        uint256 tokenId;
        uint256 stakedFromBlock;
    }

    /// @notice A Stakeholder struct stores an address and its active Stakes.
    struct Stakeholder {
        address user;
        Stake[] addressStakes;
    }

     /// @notice A StakingSummary struct stores an array of Stake structs.
     struct StakingSummary {
         Stake[] stakes;
     }

     /// @notice An address is used as a key to the array of Stakes.
     mapping(address => Stake[]) private addressStakes;

    /// @notice An tokenId is mapped to a burn capitalization value expressed in Wei.
    mapping(uint256 => uint256) public burnCapitalization;

    /// @notice An integer is used as key to the value of a Stake in order to provide a receipt.
    mapping(uint256 => Stake) public receipt;

    /// @notice An address is used as a key to an index value in the stakes that occur.
    mapping(address => uint256) private stakes;

    /// @notice All current stakeholders.
    Stakeholder[] private stakeholders;

    /// @notice Emitted when a token is unstaked in an emergency.
    event EmergencyUnstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

     /// @notice Emitted when a token is staked.
    event Staked(address indexed user, uint256 indexed tokenId, uint256 staredFromBlock, uint256 index);

    /// @notice Emitted when a reward is paid out to an address.
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);

    /// @notice Emitted when a token is unstaked.
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

    /// @notice Requirements related to token ownership.
    /// @param tokenId The current tokenId being staked.
    modifier onlyStaker(uint256 tokenId) {
        // Require that this contract has the token.
        require(miningToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this token.");

        // Require that this token is staked.
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // Require that msg.sender is the owner of this tokenId.
        require(receipt[tokenId].user == msg.sender, "onlyStaker: Caller is not token stake owner");

        _;
    }

    /// @notice A requirement to have at least one block pass before staking, unstaking or harvesting.
    /// @param tokenId The tokenId being staked or unstaked.
    modifier requireTimeElapsed(uint256 tokenId) {
        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Cannot stake/unstake/harvest in the same block"
        );
        _;
    }

    /// @notice Create the ERC721 staking contract.
    /// @dev Push needed to avoid index 0 causing bug of index-1.
    constructor() {
        stakeholders.push();
    }

    /// @notice Accepts a tokenId to perform emergency unstaking.
    /// @param tokenId The tokenId to be emergency unstaked.
    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        _emergencyUnstake(tokenId);
    }

    /// @notice Accepts a tokenId to perform staking.
    /// @param tokenId The tokenId to be staked.
    function stakeMiningToken(uint256 tokenId) external nonReentrant {
        _stakeMiningToken(tokenId);
    }

    /// @notice Accepts a tokenId to perform unstaking.
    /// @param tokenId The tokenId to be unstaked.
    function unstakeMiningToken(uint256 tokenId) external nonReentrant {
        _unstakeMiningToken(tokenId);
    }

    /// @dev Required implementation to support safeTransfers from ERC721 asset contracts.
    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "No sending tokens directly to staking contract");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Harvesting the ERC20 rewards earned by a staked ERC721 token.
    /// @param tokenId The tokenId of the staked token for which rewards are withdrawn.
    function harvest(uint256 tokenId)
        public
        nonReentrant
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
    {
        _payoutStake(tokenId);
        receipt[tokenId].stakedFromBlock = block.number;
    }

    /// @notice Sets the ERC721 contract this staking contract is for.
    /// @param _miningToken The ERC721 contract address to have its tokenIds staked.
    function setMiningToken(IERC721 _miningToken) public onlyOwner {
        require(miningTokenSet == false);
        miningToken = _miningToken;
        miningTokenSet = true;
    }

    /// @notice Set the mining token address for the instance of the ERC721 contract used.
    /// @param _miningTokenAddress The vvrrbb mining rig token address.
    function setMiningTokenAddress(address _miningTokenAddress) public onlyOwner {
        require(miningTokenAddressSet == false);
        miningTokenAddress = _miningTokenAddress;
        miningTokenAddressSet = true;
    }

    /// @notice Sets the ERC20 token used as staking rewards.
    /// @param _vvddrrToken The ERC20 token contract that will provide reward tokens.
    function setVvddrrToken(IERC20 _vvddrrToken) public onlyOwner {
        require(vvddrrTokenSet == false);
        vvddrrToken = _vvddrrToken;
        vvddrrTokenSet = true;
    }

    /// @notice Set the reward token address for the instance of the ERC20 contract used.
    /// @param _vvddrrTokenAddress The vvddrr token address.
    function setVvddrrTokenAddress(address _vvddrrTokenAddress) public onlyOwner {
        require(vvddrrTokenAddressSet == false);
        vvddrrTokenAddress = _vvddrrTokenAddress;
        vvddrrTokenAddressSet = true;
    }

    /// @notice Determine the amount of rewards earned by a staked token.
    /// @param tokenId The tokenId of the staked token.
    /// @return The value in Wei of the rewards currently earned by the tokenId.
    function getCurrentStakeEarned(uint256 tokenId) public view returns (uint256) {
        return _getTimeStaked(tokenId).mul(tokensPerBlock);
    }

    /// @notice Retrive the vvrrbb mining percentage for a given tokenId.
    /// @param tokenId The tokenId for which a mining percentage is to be retreived.
    /// @return A tokenId's mining percentage returned in percentage basis points.
    function getMiningPercentage(uint256 tokenId) public view returns (uint256) {
        Fixed fixedMiningToken = Fixed(miningTokenAddress);
        uint256 miningPercentage = fixedMiningToken.getMiningPercentageValue(tokenId);
        return miningPercentage;
    }

    /// @notice Receive a summary of current stakes by a given address.
    /// @param _user The address to receive a summary for.
    /// @return A staking summary for a given address.
    function getStakingSummary(address _user) public view returns (StakingSummary memory) {
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_user]].addressStakes);
        return summary;
    }

    /// @notice Adds a staker to the stakeholders array.
    /// @param staker An address that is staking an ERC721 token.
    /// @return The index of the address within the array of stakeholders.
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the array to make space the new stakeholder.
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1.
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index.
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders.
        stakes[staker] = userIndex;
        return userIndex;
    }

    /// @notice Emergency unstakes the given ERC721 tokenId and does not claim ERC20 rewards.
    /// @param tokenId The tokenId to be emergency unstaked.
    /// @return A boolean indicating whether the emergency unstaking was completed.
    function _emergencyUnstake(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        returns (bool)
    {

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        miningToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit EmergencyUnstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Calculates and transfers earned rewards for a given tokenId.
    /// @param tokenId The tokenId for which rewards are to be calculated and paid out.
    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // Double check that the receipt exists and that staking is beginning from block 0.
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: No staking from block 0");

        // Remove the transaction block of withdrawal from time staked.
        uint256 timeStaked = _getTimeStaked(tokenId).sub(1); // don't pay for the tx block of withdrawl

        uint256 percentage = getMiningPercentage(tokenId);

        uint256 payout = timeStaked.mul(tokensPerBlock);

        uint256 percentagePayout = Math.mulDiv(payout, percentage, BASIS);

        uint256 burnAmount = randomBurn(tokenId);

        uint256 totalRequired = percentagePayout + burnAmount;

        Token vvddrr = Token(vvddrrTokenAddress);

        uint256 total = vvddrr.getCurrentCreated() + totalRequired;

        uint256 maximum = vvddrr.getMaximumCreated();

        // If the staking contract does not have any ERC20 rewards left, return the ERC721 token without payment.
        // This prevents any type of ERC721 locking.
        if (total > maximum) {
            emit StakePayout(msg.sender, tokenId, 0, receipt[tokenId].stakedFromBlock, block.number);
            return;
        }

        // Payout the earned rewards.
        vvddrr.mintController(receipt[tokenId].user, percentagePayout);

        burnCapitalization[tokenId] = percentagePayout;

        vvddrr.mintController(receipt[tokenId].user, burnAmount);

        vvddrr.burnController(receipt[tokenId].user, burnAmount);

        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    /// @notice Stakes the given ERC721 tokenId to provide ERC20 rewards.
    /// @param tokenId The tokenId to be staked.
    /// @return A boolean indicating whether the staking was completed.
    function _stakeMiningToken(uint256 tokenId) internal returns (bool) {
        // Check for sending address of the tokenId in the current stakes.
        uint256 index = stakes[msg.sender];
        // Fulfil condition based on whether staker already has a staked index or not.
        if (index == 0) {
            // The stakeholder is taking for the first time and needs to mapped into the index of stakers.
            // The index returned will be the index of the stakeholder in the stakeholders array.
            index = _addStakeholder(msg.sender);
        }

        // set the initial burn capitalization here
        if (burnCapitalization[tokenId] == 0) {
          burnCapitalization[tokenId] = INITIAL_BURN_CAPITALIZATION;
        }

        // Use the index value of the staker to add a new stake.
        stakeholders[index].addressStakes.push(Stake(msg.sender, tokenId, block.number));

        // Require that the tokenId is not already staked.
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");

        // Required that the tokenId is not already owned by this contract as a result of staking.
        require(miningToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // Transer the ERC721 token to this contract for staking.
        miningToken.transferFrom(_msgSender(), address(this), tokenId);

        // Check that this contract is the owner.
        require(miningToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of token");

        // Start the staking from this block.
        receipt[tokenId].user = msg.sender;
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;

        emit Staked(msg.sender, tokenId, block.number, index);

        return true;
    }

    /// @notice Unstakes the given ERC721 tokenId and claims ERC20 rewards.
    /// @param tokenId The tokenId to be unstaked.
    /// @return A boolean indicating whether the unstaking was completed.
    function _unstakeMiningToken(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
        returns (bool)
    {
        // Payout the rewards collected as a result of staking.
        _payoutStake(tokenId);

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        miningToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit Unstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Determine the number of blocks for which a given tokenId has been staked.
    /// @param tokenId The staked tokenId.
    /// @return The integer value indicating the difference the current block and the initial staking block.
    function _getTimeStaked(uint256 tokenId) internal view returns (uint256) {
        if (receipt[tokenId].stakedFromBlock == 0) {
            return 0;
        }
        return block.number.sub(receipt[tokenId].stakedFromBlock);
    }

    /// @notice Returns an integer value as a string.
    /// @param value The integer value to have a type change.
    /// @return A string of the inputted integer value.
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @notice Create a random burn amount between 0 and the tokenId's current burn capitalization.
    /// @param tokenId The tokenId for which to calculate a random burn.
    /// @return A random value expressed in Wei.
    function randomBurn(uint256 tokenId) private view returns (uint256) {
      uint256 v = uint(keccak256(abi.encodePacked("9c1807fb-4ceb-4ed8-aded-ee50350b3c2a", _msgSender(), block.timestamp, toString(tokenId)))) % burnCapitalization[tokenId];
      return v;
    }

    /// @notice A general random function to be used to shuffle and generate values.
    /// @param input Any string value to be randomized.
    /// @return The output of a random hash using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

}
