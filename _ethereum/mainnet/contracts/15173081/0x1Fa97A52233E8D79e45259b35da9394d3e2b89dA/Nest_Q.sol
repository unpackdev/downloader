// SPDX-License-Identifier: UNLISENCED
pragma solidity >=0.8.4;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";


contract Nest_Q is ReentrancyGuard, ERC1155Holder, Ownable {
    using SafeERC20 for IERC20;
    IERC20 private token;
    IERC1155 private nft;

    uint256 constant oneMonthInSeconds = 2629743;
    address public POOL = 0x075Eb3011f6aa1a605A1493c66448fb0C6022Ab2;
    uint256 public REWARD_FOOD = 1158;
    bool public stakingIsActive = false;

    struct StakingItem {
        address owner;
        uint256 tokenId;
        uint256 amount;
        uint256 stakingStartTimeStamp;
    }
    // owner => tokenID => item
    mapping(address => mapping(uint256 => StakingItem)) public stakedNFTs;
    mapping(address => uint256) private stakedAmount;
    uint256 private totalStakedAmount;

    event Staked(
        address indexed owner,
        uint256 tokenId,
        uint256 amount,
        uint256 time
    );

    event Unstaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed amount,
        uint256 time
    );

    constructor(IERC20 _tokenAddress, IERC1155 _nftAddress) {
        require(
            address(_tokenAddress) != address(0) &&
                address(_nftAddress) != address(0),
            "Contract addresses cannot be zero address."
        );
        token = _tokenAddress;
        nft = _nftAddress;
    }

    function calculateStakedTimeInSeconds(uint256 _timestamp)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - _timestamp);
    }

    function stakeNFT(uint256 _amount) external {
        require(stakingIsActive, "Staking is pause");
        uint256 _tokenId = 0;

        //Requirement
        require( nft.balanceOf(msg.sender, _tokenId) >= _amount, "you dont have enough balance" );
        require( nft.isApprovedForAll(msg.sender, address(this)) == true, "this contract is not approved by you to do transactions" );
        

        if ( stakedAmount[msg.sender] > 0 ) {
            //To get the staking block time
            uint256 timestamp = stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp;
            uint256 stakingPeriodTime = calculateStakedTimeInSeconds(timestamp);

            //Calculating Reward and send to holder
            uint256 reward = REWARD_FOOD * stakingPeriodTime * stakedAmount[msg.sender];

            //Transfer reward and reset reward
            token.transferFrom(POOL, msg.sender, reward);
            reward = 0;
        }

        //Sending NFT to contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        //Adding total amount of NFT
        stakedAmount[msg.sender] = stakedAmount[msg.sender] + _amount;
        totalStakedAmount = totalStakedAmount + _amount;

        //Reset the stacking block time
        uint256 currentTime = block.timestamp; // current block time stamp in seconds

        //create new nft item
        stakedNFTs[msg.sender][_tokenId] = StakingItem(
            msg.sender,
            _tokenId,
            stakedAmount[msg.sender],
            currentTime
        );

        //emit staked event
        emit Staked(msg.sender, _tokenId, _amount, currentTime);
    }

    function unStakeNFT(uint256 _amount) external {
        require(stakingIsActive, "Staking is pause");
        uint256 _tokenId = 0;

        //Requirement
        require( stakedNFTs[msg.sender][_tokenId].owner == msg.sender );
        require( stakedAmount[msg.sender] >= _amount, "you dont have enough staked NFTS" );
        require( nft.isApprovedForAll(msg.sender, address(this)) == true, "this contract is not approved by you to do transactions" );

        //To get the staking block time
        uint256 timestamp = stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp;
        uint256 stakingPeriodTime = calculateStakedTimeInSeconds(timestamp);

        //Calculating Reward and send to holder
        uint256 reward = REWARD_FOOD * stakingPeriodTime * stakedAmount[msg.sender];

        //Transfer reward and reset reward
        token.transferFrom(POOL, msg.sender, reward);
        reward = 0;

        //send nft back to the owner and deduct the amount
        nft.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        stakedAmount[msg.sender] = stakedAmount[msg.sender] - _amount;
        totalStakedAmount = totalStakedAmount - _amount;

        //Reset the stacking time
        uint256 currentTime = block.timestamp; // current block time stamp in seconds
        stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp = currentTime;

        //emit unstaked event
        emit Unstaked(msg.sender, _tokenId, _amount, stakingPeriodTime);
    }


    function claimFood() external {
        require(stakingIsActive, "Staking is pause");
        uint256 _tokenId = 0;
        uint256 _amount = stakedAmount[msg.sender];

        //Requirement
        require( stakedNFTs[msg.sender][_tokenId].owner == msg.sender );
        require( stakedAmount[msg.sender] >= _amount, "you dont have enough staked NFTS" );
        require( nft.isApprovedForAll(msg.sender, address(this)) == true, "this contract is not approved by you to do transactions" );

        //To get the staking block time
        uint256 timestamp = stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp;
        uint256 stakingPeriodTime = calculateStakedTimeInSeconds(timestamp);

        //Calculating Reward and send to holder
        uint256 reward = REWARD_FOOD * stakingPeriodTime * stakedAmount[msg.sender];

        //Transfer reward and reset reward
        token.transferFrom(POOL, msg.sender, reward);
        reward = 0;

        //Reset the stacking block time to current
        uint256 currentTime = block.timestamp; // current block time stamp in seconds
        stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp = currentTime;        
    }

    function balance() public view returns (uint256) {
        uint256 _tokenId = 0;

        //Requirement
        require(stakedNFTs[msg.sender][_tokenId].owner == msg.sender);

        //To get the staking block time
        uint256 timestamp = stakedNFTs[msg.sender][_tokenId].stakingStartTimeStamp;
        uint256 stakingPeriodTime = calculateStakedTimeInSeconds(timestamp);


        //Calculating Reward and send to holder
        uint256 reward = REWARD_FOOD * stakingPeriodTime * stakedAmount[msg.sender];

        return reward;
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

    function getUserStakedAmount() public view returns (uint256) {
        return stakedAmount[msg.sender];
    }

    // Update FOOD Reward
    function setFoodPrice(uint _newPrice) external onlyOwner {
        REWARD_FOOD = _newPrice;
    }

    // Update POOL Address
    function setPoolAdd(address _newAddress) external onlyOwner {
        POOL = _newAddress;
    }

    function Pause() public onlyOwner {
        stakingIsActive = !stakingIsActive;
    }

    function emerTrans(uint256 _amount, address receiver) external onlyOwner{
        require(!stakingIsActive, "Please pause the contract");
        uint256 _tokenId = 0;

        //Requirement
        require( totalStakedAmount >= _amount, "Not enough staked Queens" );

        //send nft back to the owner and deduct the amount
        nft.safeTransferFrom(address(this), receiver, _tokenId, _amount, "");
        totalStakedAmount = totalStakedAmount - _amount;
    }

}