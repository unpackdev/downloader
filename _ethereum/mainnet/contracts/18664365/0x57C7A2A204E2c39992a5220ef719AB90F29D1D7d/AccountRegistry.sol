// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRegistry.sol";
import "./MinimalProxyStore.sol";
import "./Account.sol";

/**
 * @title A registry for token bound accounts
 * @dev Determines the address for each token bound account and performs deployment of accounts
 * @author Jayden Windle (jaydenwindle)
 */

contract AccountRegistry is IRegistry, Ownable {
    /**
     * @dev Address of the account implementation
     */
    address public immutable implementation;

    /**
     * @dev User wallet Information struct having NFT tokenIds and NFT wallet address
     */
    struct userWalletInfo {
        uint256 tokenId;
        address walletAddress;
    }

    /**
     * @dev Cycle information details: Start time and End time of the cycle
     */
    struct cycleDetails {
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @dev Account info mapping maps user addres to userWalletInfo struct array
     */
    mapping(address => userWalletInfo[]) public accountInfo;

    /**
     * @dev Number of wallets created by registry
     */
    mapping(address => uint256) public numOfWalletCreated;

    /**
     * @dev this mapping maps cycle number to cycle details
     */
    mapping(uint256 => cycleDetails) public cycleNumToCycleDetails;

    /**
     * @dev GODL rewards entitled for the cycle
     */
    mapping(uint256 => uint256) public GODLRewardsForCycle;

    /**
     * @dev Total Value staked for that cycle
     */
    mapping(uint256 => uint256) public TVSforCycle;

    /**
     * @dev Vgold token address
     */
    address public vgoldToken;

    /**
     * @dev totalVGold stake for all the cycles
     */
    uint256 public totalVgoldStake;

    uint256 public immutable minimumLockup = 180;

    Account accountContract;

    uint256 public cycleCount;

    address public GODLToken;

    mapping(address => bool) public isNFTWalletAccount;

    uint256 public cyclePeriod = 180;

    /**
     * @dev Emitted whenever new Address Created
     */
    event AddressCreated(address indexed newAddress);

    event VgoldStaked(address NFTWalletAddress, uint256 stakeAmount, uint256 cycleNum);

    event VGoldUnstaked(address NFTWalletAddress, uint256 totalUnstake, uint256 userRewards, uint256 eligibleStakes, uint256 cycleNum);
    
    event RewardsClaimed(address NFTWalletAddress, uint256 userRewards, uint256 eligibleStakes, uint256 cycleNum);

    modifier onlyWalletOwner(address payable _NFTWalletAccount) {
        address walletOwner = Account(_NFTWalletAccount).owner();
        require(
            msg.sender == walletOwner,
            "Can only be called by wallet owner"
        );
        _;
    }

    /**
     * @dev Constructor for Account Registry contract.
     * @param _implementation is the Account template address
     * @param _GODLToken address of GODL Token
     * @param _vgoldToken address of VGold Token
     */
    constructor(
        address _implementation,
        address _GODLToken,
        address _vgoldToken
    ) {
        implementation = _implementation;
        GODLToken = _GODLToken;
        vgoldToken = _vgoldToken;
    }

    // /**
    //     To get NFT wallet addresses owned by a user
    //     */
    // function getAccountInfo(address userAdd) public view returns(address[] memory){
    //     address[] memory walletAddresses
    //     while(accountInfo)
    // }
    /**
     * @dev Creates the account for an ERC721 token. Will revert if account has already been deployed
     *
     * @param chainId the chainid of the network the ERC721 token exists on
     * @param tokenCollection the contract address of the ERC721 token which will control the deployed account
     * @param tokenId the token ID of the ERC721 token which will control the deployed account
     * @return The address of the deployed ccount
     */
    function createAccount(
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId
    ) external returns (address) {
        return _createAccount(chainId, tokenCollection, tokenId);
    }

    /**
     * @dev Deploys the account for an ERC721 token. Will revert if account has already been deployed
     *
     * @param tokenCollection the contract address of the ERC721 token which will control the deployed account
     * @param tokenId the token ID of the ERC721 token which will control the deployed account
     * @return The address of the deployed account
     */
    function createAccount(
        address tokenCollection,
        uint256 tokenId
    ) external returns (address) {
        return _createAccount(block.chainid, tokenCollection, tokenId);
    }

    /**
     * @dev Gets the address of the account for an ERC721 token. If account is
     * not yet deployed, returns the address it will be deployed to
     *
     * @param chainId the chainid of the network the ERC721 token exists on
     * @param tokenCollection the address of the ERC721 token contract
     * @param tokenId the tokenId of the ERC721 token that controls the account
     * @return The account address
     */
    function account(
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId
    ) external view returns (address) {
        return _account(chainId, tokenCollection, tokenId);
    }

    /**
     * @dev Gets the address of the account for an ERC721 token. If account is
     * not yet deployed, returns the address it will be deployed to
     *
     * @param tokenCollection the address of the ERC721 token contract
     * @param tokenId the tokenId of the ERC721 token that controls the account
     * @return The account address
     */
    function account(
        address tokenCollection,
        uint256 tokenId
    ) external view returns (address) {
        return _account(block.chainid, tokenCollection, tokenId);
    }

    function _createAccount(
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId
    ) internal returns (address) {
        require(
            IERC721(tokenCollection).ownerOf(tokenId) == msg.sender,
            "You are not the owner of NFT"
        );
        bytes memory encodedTokenData = abi.encode(
            chainId,
            tokenCollection,
            tokenId
        );
        bytes32 salt = keccak256(encodedTokenData);
        address accountProxy = MinimalProxyStore.cloneDeterministic(
            implementation,
            encodedTokenData,
            salt
        );

        userWalletInfo memory userInfo = userWalletInfo(tokenId, accountProxy);
        accountInfo[msg.sender].push(userInfo);
        numOfWalletCreated[msg.sender]++;
        isNFTWalletAccount[accountProxy] = true;
        //setting the Registry contract setter funciton which can only be called once
        accountContract = Account(payable(accountProxy));
        accountContract.setRegistry(address(this));
        accountContract.setMinLockup(minimumLockup);
        emit AccountCreated(accountProxy, tokenCollection, tokenId);

        return accountProxy;
    }

    function _account(
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId
    ) internal view returns (address) {
        bytes memory encodedTokenData = abi.encode(
            chainId,
            tokenCollection,
            tokenId
        );
        bytes32 salt = keccak256(encodedTokenData);

        address accountProxy = MinimalProxyStore.predictDeterministicAddress(
            implementation,
            encodedTokenData,
            salt
        );

        return accountProxy;
    }

    function getMinimumLockuop() external pure returns (uint256) {
        return minimumLockup;
    }

    function getCycleCount() external view returns (uint256) {
        return cycleCount;
    }

    function getVgoldToken() external view returns (address) {
        return vgoldToken;
    }

    function getCycleNumToCycleEndTime(
        uint256 _cycleNum
    ) public view returns (uint256) {
        return cycleNumToCycleDetails[_cycleNum].endTime;
    }

    function setVgoldToken(address _vgold) public onlyOwner {
        vgoldToken = _vgold;
    }

    function setCycle(uint256 _startTime, uint256 _freq) public onlyOwner {
        require(_startTime >= block.timestamp, "You can't creat cycle in past");
        for (uint256 i = 1; i <= _freq; i++) {
            if (i == 1) {
                cycleCount++;
                cycleNumToCycleDetails[cycleCount] = cycleDetails(
                    _startTime,
                    _startTime + cyclePeriod
                );
            } else {
                cycleCount++;
                _startTime = cycleNumToCycleDetails[cycleCount - 1].endTime;
                cycleNumToCycleDetails[cycleCount] = cycleDetails(
                    _startTime,
                    _startTime + cyclePeriod
                );
            }
        }
    }

    function getCurrentCycle() public view returns (uint256) {
        uint256 cycleNumber;
        for (uint256 i = 1; i <= cycleCount; i++) {
            if (
                cycleNumToCycleDetails[i].startTime <= block.timestamp &&
                cycleNumToCycleDetails[i].endTime > block.timestamp
            ) {
                cycleNumber = i;
                break;
            }
        }
        return cycleNumber;
    }

    function fundGODL(
        uint256 _cycleNum,
        uint256 _rewardAmount
    ) public onlyOwner {
        require(_rewardAmount > 0, "Amount should be greater than zero");
        require(_cycleNum <= cycleCount, "Invalid cycle");
        require(
            IERC20(GODLToken).transferFrom(
                msg.sender,
                address(this),
                _rewardAmount
            ),
            "GODL TransferFailed"
        );
        GODLRewardsForCycle[_cycleNum] += _rewardAmount;
    }

    function fundGODLForMultipleCycles(
        uint256[] memory _cycles,
        uint256[] memory _rewardAmounts
    ) public onlyOwner {
        require(
            _cycles.length == _rewardAmounts.length,
            "Cycles and reward counts are not matching"
        );
        for (uint256 i = 0; i < _cycles.length; i++) {
            require(
                _rewardAmounts[i] > 0,
                "Amount should be greater than zero"
            );
            require(_cycles[i] <= cycleCount, "Invalid cycle");
            require(
                IERC20(GODLToken).transferFrom(
                    msg.sender,
                    address(this),
                    _rewardAmounts[i]
                ),
                "GODL TransferFailed"
            );
            GODLRewardsForCycle[_cycles[i]] += _rewardAmounts[i];
        }
    }

    function withdrawGODLforCycle(
        uint256 _cycleNum,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "Amount should be greater than zero");
        require(
            IERC20(GODLToken).transfer(msg.sender, _amount),
            "GODL Token transferFailed"
        );
        GODLRewardsForCycle[_cycleNum] -= _amount;
    }

    function withdrawAllGODL() public onlyOwner {
        uint256 balanceOfContract = IERC20(GODLToken).balanceOf(address(this));
        require(balanceOfContract > 0, "Zero GODL in contract");
        require(
            IERC20(GODLToken).transfer(msg.sender, balanceOfContract),
            "GODL Token transferFailed"
        );
        for (uint256 i = 1; i <= cycleCount; i++) {
            GODLRewardsForCycle[i] = 0;
        }
    }

    function withdrawAnyTokenorETH(
        address _token,
        bool _ifETH,
        uint256 _amount
    ) public onlyOwner {
        if (!_ifETH) {
            require(_amount > 0, "Amount should be greater than zero");
            require(
                IERC20(_token).transfer(msg.sender, _amount),
                "Token transfer failed"
            );
        } else {
            require(_amount > 0, "Amount should be greater than zero");
            payable(msg.sender).transfer(_amount);
        }
    }

    function stakeVgold(
        address payable _NFTWalletAccount,
        uint256 _stakeAmount
    ) public onlyWalletOwner(_NFTWalletAccount) {
        uint256 cycleNum = getCurrentCycle();
        require(
            isNFTWalletAccount[_NFTWalletAccount],
            "Invalid NFT wallet acoount"
        );
        require(cycleNum!=0, "Cycle not set");
        require(cycleNum <= cycleCount, "Invalid cycle");
        require(_stakeAmount > 0, "Amount should be greater than 0");
        // require(block.timestamp < getCycleNumToCycleEndTime(cycleNum), "You can't stake in old cycle, Please check the cycle Number");
        // require(block.timestamp >= cycleNumToCycleDetails[cycleNum].startTime, "You can't stake in upcoming cycle, Please check the cycle Number");
        require(
            IERC20(vgoldToken).transferFrom(
                msg.sender,
                _NFTWalletAccount,
                _stakeAmount
            ),
            "Token Transfer Failed"
        );
        accountContract = Account(_NFTWalletAccount);
        accountContract.stake(_stakeAmount, cycleNum);
        TVSforCycle[cycleNum] += _stakeAmount;
        totalVgoldStake += _stakeAmount;
        emit VgoldStaked(_NFTWalletAccount, _stakeAmount, cycleNum);
    }

    function claimVgold(
        address payable _NFTWalletAccount,
        uint256 _cycleNum
    ) public onlyWalletOwner(_NFTWalletAccount) {
        uint256 userRewards;
        require(
            isNFTWalletAccount[_NFTWalletAccount],
            "Invalid NFT wallet acoount"
        );
        require(_cycleNum <= cycleCount, "Invalid cycle");
        accountContract = Account(_NFTWalletAccount);
        uint256 eligibleStake = accountContract.calculateEligibleStake(
            _cycleNum
        );
        if(eligibleStake != 0 && TVSforCycle[_cycleNum] == 0){
            userRewards = 0;
        }
        else{
            userRewards = (eligibleStake * GODLRewardsForCycle[_cycleNum]) /
            TVSforCycle[_cycleNum];
        }
        require(userRewards > 0, "Unable to claim: Zero Rewards");
        require(
            IERC20(GODLToken).balanceOf(address(this)) >= userRewards,
            "Not enough rewards in the contract"
        );
        require(
            IERC20(GODLToken).transfer(msg.sender, userRewards),
            "GODL Reward Transfer Failed"
        );
        accountContract.postClaim(block.timestamp, _cycleNum);
        GODLRewardsForCycle[_cycleNum] -= userRewards;
        emit RewardsClaimed(_NFTWalletAccount, userRewards, eligibleStake, _cycleNum);
    }

    function calculateRewards(
        address payable _NFTWalletAccount,
        uint256 _cycleNum
    ) public view returns(uint256){
        uint256 userRewards;
        require(
            isNFTWalletAccount[_NFTWalletAccount],
            "Invalid NFT wallet acoount"
        );
        require(_cycleNum <= cycleCount, "Invalid cycle");
        Account accountContractInstance = Account(_NFTWalletAccount);
        uint256 eligibleStake = accountContractInstance.calculateEligibleStake(
            _cycleNum
        );
        if(eligibleStake != 0 && TVSforCycle[_cycleNum] == 0){
            userRewards = 0;    
        }
        else{
            userRewards = (eligibleStake * GODLRewardsForCycle[_cycleNum]) /
            TVSforCycle[_cycleNum];
        }
        return userRewards;
    }


    function unstakeVgoldForStake(
        address payable _NFTWalletAccount,
        uint256[] memory arrayIndexes,
        uint256 _cycleNum
    ) public onlyWalletOwner(_NFTWalletAccount) {
        // TO check if its a registry generated NFT account
        require(
            isNFTWalletAccount[_NFTWalletAccount],
            "Invalid NFT wallet acoount"
        );
        // To check the valid cycle number
        require(_cycleNum <= cycleCount, "Invalid cycle");
        accountContract = Account(_NFTWalletAccount);
        // Calculate eligible stake to claim GODL reward
        uint256 eligibleStake = accountContract.calculateEligibleStakeArray(
            arrayIndexes,
            _cycleNum
        );
        uint256 userRewards;
        // if user has eligible stakes then calculate user rewards
        if (eligibleStake != 0 && TVSforCycle[_cycleNum] != 0) {
            userRewards =
                (eligibleStake * GODLRewardsForCycle[_cycleNum]) /
                TVSforCycle[_cycleNum];
        } else {
            userRewards = 0;
        }
        // if user has some rewards then transfer the GODL rewards to user.
        if (userRewards != 0) {
            require(
                IERC20(GODLToken).balanceOf(address(this)) >= userRewards,
                "Not enough rewards in the contract"
            );
            require(
                IERC20(GODLToken).transfer(msg.sender, userRewards),
                "GODL Reward Transfer Failed"
            );
            GODLRewardsForCycle[_cycleNum] -= userRewards;
        }
        // Call account contract post unstake for array function to make the stakes and time stamps 0 for the array indexes.
        uint256 totalUnstake = accountContract.postUnstakeForArray(
            arrayIndexes,
            _cycleNum
        );
        totalVgoldStake -= totalUnstake;
        TVSforCycle[_cycleNum] -= totalUnstake;
        emit VGoldUnstaked(_NFTWalletAccount, totalUnstake, userRewards, eligibleStake, _cycleNum);

    }

    function unstakeVgoldForCycle(
        address payable _NFTWalletAccount,
        uint256 _cycleNum
    ) public onlyWalletOwner(_NFTWalletAccount) {
        require(
            isNFTWalletAccount[_NFTWalletAccount],
            "Invalid NFT wallet acoount"
        );
        require(_cycleNum <= cycleCount, "Invalid cycle");
        accountContract = Account(_NFTWalletAccount);
        uint256 eligibleStake = accountContract.calculateEligibleStake(
            _cycleNum
        );
        uint256 userRewards;
        if (eligibleStake != 0 && TVSforCycle[_cycleNum] != 0) {
            userRewards =
                (eligibleStake * GODLRewardsForCycle[_cycleNum]) /
                TVSforCycle[_cycleNum];
        } else {
            userRewards = 0;
        }
        if (userRewards != 0) {
            require(
                IERC20(GODLToken).balanceOf(address(this)) >= userRewards,
                "Not enough rewards in the contract"
            );
            require(
                IERC20(GODLToken).transfer(msg.sender, userRewards),
                "GODL Reward Transfer Failed"
            );
            GODLRewardsForCycle[_cycleNum] -= userRewards;
        }
        uint256 totalUnstake = accountContract.getTotalVgoldStakeForCycle(
            _cycleNum
        );
        TVSforCycle[_cycleNum] -= totalUnstake; 
        totalVgoldStake -= totalUnstake;
        require(
            accountContract.postUnstakeForCycle(_cycleNum),
            "PostUnstake for cycle failed"
        );
        emit VGoldUnstaked(_NFTWalletAccount, totalUnstake, userRewards, eligibleStake, _cycleNum);
    }
}
