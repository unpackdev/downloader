// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721Holder.sol";

contract StakingSystem is Ownable, ERC721Holder {
    IERC721 public nft;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 public breakStakingCost;
    address payable public feeAccount;
    /// @notice staker define
    struct Staker {
        uint256[] tokenIds;
        // stake begin time
        uint256 stakeTime;
        // stake end time
        uint256 expireTime;
        uint256 productId;
        uint256 balance;
    }

    /// @notice stake product
    struct StakeProduct {
        uint256 productId;
        uint256 minStakeNumber;
        uint256 maxStakeNumber;
        bool breakStaking;
        // stake time uint seconds
        uint256 stakeTime;
    }

    /// @notice token owner info
    struct OwnerInfo {
        address user;
        uint256 productId;
    }

    constructor(IERC721 _nft) {
        nft = _nft;
        feeAccount = payable(msg.sender);
    }

    /// @notice mapping of stake products
    mapping(uint256 => StakeProduct) public stakeProducts;
    /// @notice product ids
    uint256[] public productIds;
    /// @notice mapping productId of mapping of a staker to its wallet
    mapping(uint256 => mapping(address => Staker)) public stakers;

    /// @notice Mapping from token ID to owner address

    mapping(uint256 => OwnerInfo) public tokenOwner;
    bool initialised;

    /// @notice event emitted when a user has staked a nft
    event Staked(address user, uint256 tokenId);

    /// @notice event emitted when a product has been staked"
    event StakedBatch(address user, uint256 productId, uint256 amount);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address user, uint256 tokenId);

    /// @notice event emitted when a user token unstaked by system
    event UnStakedBatch(address user, uint256 productId, uint256 amount);

    /// @notice event emitted when a user unstaked by system with a productId
    event SystemUnstakedByProductId(address user, uint256 productId, uint256 amount);

    /// @notice event emitted when a product is breaking
    event BreakStakingCost(address user, uint256 productId, uint256 amount);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    /// @notice add stake product
    function addStakeProduct(uint256 _productId, uint256 _minStakeNumber, uint256 _maxStakeNumber, bool _breakStaking, uint256 _stakeTime)
        public onlyOwner {
        require(_productId > 0, "Stake productId must be greater than 0");
        require(_minStakeNumber > 0, "Stake _minStakeNumber must be greater than 0");
        require(_maxStakeNumber > 0, "Stake _maxStakeNumber must be greater than 0");
        require(_stakeTime > 0, "Stake _stakeTime must be greater than 0");
        if (stakeProducts[_productId].productId == 0) {
            productIds.push(_productId);
        }

        stakeProducts[_productId] = StakeProduct(
            _productId,
            _minStakeNumber,
            _maxStakeNumber,
            _breakStaking,
            _stakeTime
        );
    }

    function stakeBatch(uint256 _productId, uint256[] memory _tokenIds) public {
        require(initialised, "Staking System: the staking has not started");
        address _user = msg.sender;
        require(!_hasStakeProduct(_productId, _user), "Stake product has been staked");
        uint256 tokenNumber = _tokenIds.length;
        uint256 minSn = stakeProducts[_productId].minStakeNumber;
        uint256 maxSn = stakeProducts[_productId].maxStakeNumber;
        require(stakeProducts[_productId].productId > 0, "Stake product not exists");
        require(tokenNumber >= minSn && tokenNumber <= maxSn, "stake token aount invalid");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stake(_user, _productId, _tokenIds[i]);
        }

        emit StakedBatch(_user, _productId, tokenNumber);
    }

    function _stake(address _user, uint256 _productId, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );

        require(tokenOwner[_tokenId].user == address(0x0), "the token has been staked");

        Staker storage staker = stakers[_productId][_user];
        staker.stakeTime = block.timestamp;
        staker.expireTime = staker.stakeTime + stakeProducts[_productId].stakeTime;
        staker.tokenIds.push(_tokenId);
        staker.balance++;
        staker.productId = _productId;
        tokenOwner[_tokenId] = OwnerInfo(_user, _productId);
        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstakeBatch(uint256 _productId) public payable {
        address _user = msg.sender;
        require(stakeProducts[_productId].breakStaking, "Nft Staking System: product can not break staking");
        Staker storage staker = stakers[_productId][_user];
        require(staker.balance > 0, "Staker balance must be greater than zero");

        if (breakStakingCost > 0 && staker.expireTime > block.timestamp) {
            uint256 cost = breakStakingCost * staker.tokenIds.length;
            if (cost > 0) {
                require(msg.value >= cost, "break stake cost free not enough");
                if (feeAccount != msg.sender) {
                    feeAccount.transfer(cost);    
                    emit BreakStakingCost(msg.sender, _productId, staker.tokenIds.length);
                }
            }
        }

        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            _unstake(_user, staker.tokenIds[i]);
            staker.balance--;
        }

        emit UnStakedBatch(_user, _productId, staker.tokenIds.length);
        delete stakers[_productId][_user];
    }


    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId].user == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );

        delete tokenOwner[_tokenId];
        nft.safeTransferFrom(address(this), _user, _tokenId);
        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

    function _hasStakeProduct(uint256 _productId, address _user) private view returns (bool) {
        return stakers[_productId][_user].balance > 0;
    }

    function systemUnstakeByProductId(address _user, uint256 _productId) public onlyOwner {
        Staker storage staker = stakers[_productId][_user];
        require(staker.balance > 0, "Staker balance must be greater than zero");
        require(staker.expireTime > 0, "Staker expireTime must be greater than zero");
        require(staker.expireTime < block.timestamp, "Staker expireTime must be smaller than block.timestamp");

        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            _unstake(_user, staker.tokenIds[i]);
            staker.balance--;
        }

        emit SystemUnstakedByProductId(_user, _productId, staker.tokenIds.length);
        delete stakers[_productId][_user];
    }

    function getStakerTokenIdsByProduct(uint256 _productId, address _user) public view returns(uint256[] memory tokenIds) {
        Staker storage staker = stakers[_productId][_user];
        return staker.tokenIds;
    }

    function getProductIds() public view returns(uint256[] memory ids) {
        return productIds;
    }

    function setBreakStakingCost(uint256 _breakStakingCost) public onlyOwner {
        breakStakingCost = _breakStakingCost;
    }

    function setFeeAccount(address _account) public onlyOwner {
        feeAccount = payable(_account);
    }
}
