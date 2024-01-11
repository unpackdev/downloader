// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IERC721Receiver.sol";
import "./IERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IRHNO{
    function mint(address account, uint256 amount) external;
}

contract MekaRhinosStake is Ownable, ReentrancyGuard {
    uint256 public constant DAY = 24 * 60 * 60; // 86400
    uint256 public constant THIRTY_DAYS = 30 * DAY; // 2592000
    uint256 public constant FIFTY_FIVE_DAYS = 55 * DAY; // 4752000

    uint256 public reward = 10 ether;

    address public RHNO = 0xc7054002185b5E79Aa8cF0EC05BE81E507DE39f6;
    address public MekaNFT = 0x14DB21F6D5BfbB0451C6aF1F9682CA3e190c9881;

    bool public emergencyUnstakePaused = true;

    IERC721AQueryable nft = IERC721AQueryable(MekaNFT);
    IRHNO token = IRHNO(RHNO);

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 lastClaimed;
        uint256 endingTimestamp;
        uint256 timeFrame;
        uint256 earned;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount, uint256 timeframe);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {}

    // MODIFIER
    modifier checkArgsLength(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    ) {
        require(
            tokenIds.length == timeframe.length,
            "Token IDs and timeframes must have the same length."
        );
        _;
    }

    modifier checkStakingTimeframe(uint256[] calldata timeframe) {
        for (uint256 i = 0; i < timeframe.length; i++) {
            uint256 period = timeframe[i];
            require(
                period == THIRTY_DAYS ||
                    period == FIFTY_FIVE_DAYS,
                "Invalid staking timeframes."
            );
        }
        _;
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You must own the NFT."
        );
        uint256 currentTimestamp = block.timestamp;

        uint256 endingTimestamp = currentTimestamp + _timeframe;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            currentTimestamp,
            currentTimestamp,
            endingTimestamp,
            _timeframe,
            0
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        nft.safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId, _timeframe);
    }

    function batchTotalEarned (uint256[] memory _tokenIds) public view returns (uint256){
        uint256 earned = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++){
            earned += totalEarned(_tokenIds[i]);
        }

        return earned;
    }

    function totalEarned (uint256 _tokenId) public view returns (uint256){
        uint256 claimable = 0;
        uint256 maxEarned = (reward * stakingRecords[_tokenId].timeFrame / DAY) - stakingRecords[_tokenId].earned;
        uint256 earned = reward * (block.timestamp - stakingRecords[_tokenId].lastClaimed) / DAY;

        if(earned > maxEarned) claimable = maxEarned;
        else claimable = earned;

        return claimable;
    }

    function batchClaim(uint256[] memory _tokenIds) external{
        for(uint256 i = 0; i < _tokenIds.length; i++){
            claim(_tokenIds[i]);
        }
    }

    function claim(uint256 _tokenId) internal{
        require(stakingRecords[_tokenId].tokenOwner == msg.sender, "Token does not belong to you.");
        require(stakingRecords[_tokenId].lastClaimed < stakingRecords[_tokenId].endingTimestamp, "Not eligible to claim.");

        uint256 claimable = totalEarned(_tokenId);

        require(claimable > 0, "Not enough balance.");

        stakingRecords[_tokenId].earned = claimable;
        stakingRecords[_tokenId].lastClaimed = block.timestamp;
        
        token.mint(msg.sender, claimable);
    }

    // RESTAKE
    function batchRestake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _restake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _restake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        uint256 currentTimestamp = block.timestamp;

        uint256 endingTimestamp = currentTimestamp + _timeframe;

        stakingRecords[_tokenId].endingTimestamp = endingTimestamp;
        stakingRecords[_tokenId].timeFrame = _timeframe;
        stakingRecords[_tokenId].earned = 0;
        stakingRecords[_tokenId].lastClaimed = currentTimestamp;
        stakingRecords[_tokenId].stakedAt = currentTimestamp;

        emit Staked(_user, _tokenId, _timeframe);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        nft.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstaked(_user, _tokenId);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i <= IERC721A(MekaNFT).totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].endingTimestamp;
                counter++;
            }
        }
        return (tokenIds, expiries);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // MIGRATION ONLY.
    function setMekaNFTContract (address _address) public onlyOwner {
        MekaNFT = _address;
    }

    function setTokenContract (address _address) public onlyOwner {
        RHNO = _address;
    }

    function setReward (uint256 _newReward) public onlyOwner {
        reward = _newReward;
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused) public onlyOwner {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        require(
            stakingRecords[tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );
        delete stakingRecords[tokenId];
        numOfTokenStaked[msg.sender]--;
        nft.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function emergencyUnstakeByOwner(uint256[] calldata tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address user = stakingRecords[tokenId].tokenOwner;
            require(user != address(0x0), "Need owner exists.");
            delete stakingRecords[tokenId];
            numOfTokenStaked[user]--;
            nft.safeTransferFrom(
                address(this),
                user,
                tokenId
            );
            emit EmergencyUnstake(user, tokenId);
        }
    }
}