// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./IStakingNFT.sol";
import "./IRewardKeeper.sol";

contract Staking is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string private _name;
    address private _stakingErc20Address;
    address private _rewardErc20Address;
    address private _stakingNftAddress;
    address private _rewardKeeperAddress;

    uint16 private _rewardPercent;
    bool private _stakingStarted;

    uint256 private _staked;
    uint256 private _stakedAllTime;

    uint256 private constant _SECONDS_IN_YEAR = 31536000; // 365 * 24 * 60 * 60;

    event Staked(address indexed actionAddress, uint256 tokenId, uint256 stakeAmount, uint16 rewardPercent);
    event Withdrawn(address indexed actionAddress, uint256 tokenId, uint256 stakeAmount, uint16 rewardPercent, uint256 stakeDuration, uint256 rewardAmount);
    event Cancel(address indexed actionAddress, uint256 tokenId, uint256 stakeAmount);

    event StakingStarted();
    event StakingStopped();

    event RewardPercentUpdated(uint16 rewardPercent);

    constructor(
        string memory name_,
        address stakingErc20Address_,
        address rewardErc20Address_,
        address stakingNftAddress_,
        address rewardKeeperAddress_,
        uint16 rewardPercent_
    ) {
        require(stakingErc20Address_ != address(0), "Staking: Invalid stakingErc20Address");
        require(rewardErc20Address_ != address(0), "Staking: Invalid rewardErc20Address");
        require(stakingNftAddress_ != address(0), "Staking: Invalid stakingNftAddress");
        require(rewardKeeperAddress_ != address(0), "Staking: Invalid rewardKeeperAddress");

        _name = name_;
        _stakingErc20Address = stakingErc20Address_;
        _rewardErc20Address = rewardErc20Address_;
        _stakingNftAddress = stakingNftAddress_;
        _rewardKeeperAddress = rewardKeeperAddress_;

        updateRewardPercent(rewardPercent_);
    }

    function stakingConfig()
        public
        view
        returns (
            string memory name,
            address stakingErc20Address,
            address rewardErc20Address,
            address stakingNftAddress,
            address rewardKeeperAddress,
            uint16 currentRewardPercent,
            bool stakingStarted,
            uint256 staked,
            uint256 stakedAllTime,
            bool mintNftPermission,
            bool payRewardPermission
        )
    {
        mintNftPermission = IStakingNFT(_stakingNftAddress).isMinterAddress(address(this));
        payRewardPermission = IRewardKeeper(_rewardKeeperAddress).isActionAddress(address(this));
        return (
            _name,
            _stakingErc20Address,
            _rewardErc20Address,
            _stakingNftAddress,
            _rewardKeeperAddress,
            _rewardPercent,
            _stakingStarted,
            _staked,
            _stakedAllTime,
            mintNftPermission,
            payRewardPermission
        );
    }

    function stake(uint256 stakeAmount_) public nonReentrant returns (uint256) {
        require(_stakingStarted, "Staking: Staking is not started");
        require(stakeAmount_ > 0, "Staking: Invalid stake amount");

        IStakingNFT stakingNFT = IStakingNFT(_stakingNftAddress);
        require(stakingNFT.isMinterAddress(address(this)), "Staking: No permission to mint");

        IERC20 stakingERC20 = IERC20(_stakingErc20Address);
        require(stakingERC20.allowance(_msgSender(), address(this)) >= stakeAmount_, "Staking: required amount not approved");

        stakingERC20.safeTransferFrom(_msgSender(), address(this), stakeAmount_);
        uint256 nftTokenId = stakingNFT.mintToken(_msgSender(), stakeAmount_, _rewardPercent);

        _staked = _staked.add(stakeAmount_);
        _stakedAllTime = _stakedAllTime.add(stakeAmount_);

        emit Staked(_msgSender(), nftTokenId, stakeAmount_, _rewardPercent);

        return nftTokenId;
    }

    function calculateReward(uint256 nftTokenId_)
        public
        view
        returns (
            uint256 startAt,
            uint256 stakeAmount,
            uint16 rewardPercent,
            address minterAddress,
            uint256 stakeDuration,
            uint256 rewardAmount
        )
    {
        (, startAt, stakeAmount, rewardPercent, minterAddress) = IStakingNFT(_stakingNftAddress).getStakeTokenData(nftTokenId_);
        if (minterAddress != address(this)) {
            return (0, 0, 0, address(0), 0, 0);
        }

        if (block.timestamp > startAt) {
            stakeDuration = block.timestamp - startAt;
            rewardAmount = stakeAmount.mul(stakeDuration).mul(rewardPercent).div(10000).div(_SECONDS_IN_YEAR);
        }

        return (
            startAt,
            stakeAmount,
            rewardPercent,
            minterAddress,
            stakeDuration,
            rewardAmount
        );
    }

    function withdraw(uint256 nftTokenId_) public nonReentrant returns (bool) {
        IRewardKeeper rewardKeeper = IRewardKeeper(_rewardKeeperAddress);
        require(rewardKeeper.isActionAddress(address(this)), "Staking: No permission to pay reward");

        IStakingNFT stakingNFT = IStakingNFT(_stakingNftAddress);
        require(stakingNFT.checkTokenExistence(nftTokenId_), "Staking: Nft token not exists");

        ( , uint256 stakeAmount, uint16 rewardPercent, address minterAddress, uint256 stakeDuration, uint256 rewardAmount) = calculateReward(nftTokenId_);
        require(minterAddress == address(this), "Staking: Nft token has wrong minter address");

        stakingNFT.safeTransferFrom(_msgSender(), address(this), nftTokenId_);

        IERC20 stakingERC20 = IERC20(_stakingErc20Address);
        stakingERC20.transfer(_msgSender(), stakeAmount);

        rewardKeeper.sendReward(_rewardErc20Address, _msgSender(), rewardAmount);

        _staked = _staked.sub(stakeAmount);
        emit Withdrawn(_msgSender(), nftTokenId_, stakeAmount, rewardPercent, stakeDuration, rewardAmount);

        return true;
    }

    function cancel(uint256 nftTokenId_) public nonReentrant returns (bool) {
        IStakingNFT stakingNFT = IStakingNFT(_stakingNftAddress);
        require(stakingNFT.checkTokenExistence(nftTokenId_), "Staking: Nft token not exists");

        ( , uint256 stakeAmount, , address minterAddress, , ) = calculateReward(nftTokenId_);
        require(minterAddress == address(this), "Staking: Nft token has wrong minter address");

        stakingNFT.safeTransferFrom(_msgSender(), address(this), nftTokenId_);

        IERC20 stakingERC20 = IERC20(_stakingErc20Address);
        stakingERC20.transfer(_msgSender(), stakeAmount);

        _staked = _staked.sub(stakeAmount);
        emit Cancel(_msgSender(), nftTokenId_, stakeAmount);

        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function startStaking() external onlyOwner {
        require(!_stakingStarted, "Staking: Staking already started");
        _stakingStarted = true;
        emit StakingStarted();
    }

    function stopStaking() external onlyOwner {
        require(_stakingStarted, "Staking: Staking already stopped");
        _stakingStarted = false;
        emit StakingStopped();
    }

    function updateRewardPercent(uint16 rewardPercent_) public onlyOwner {
        require(rewardPercent_ > 0 && rewardPercent_ <= 60000, "Staking: Invalid rewardPercent");
        _rewardPercent = rewardPercent_;
        emit RewardPercentUpdated(rewardPercent_);
    }
}
