// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

interface IODINNFT {
    function checkAccountLevels(address _account) external view returns (uint256[] memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function getTokensOfOwner(address owner) external view returns (uint256[] memory);
    function transferFrom(address from, address to, uint256 _id) external;
}

interface IODINToken {
    function transfer(address _from, address _to, uint256 amount) external returns(bool);
    function totalSupply() external view returns(uint256);
}

interface IMarket {
    function getTokenPrice(uint256 _tokenId) external view returns (uint256);
    function getTokenPaymentType(uint256 _tokenId) external view returns (string memory);
}

struct Staker {
    uint256[] tokenIds;
    uint256 lastStartTime;
    uint256 readyTime;
    uint256 period;
    uint256 rewardPercentage;
    uint256 bonusPercentage;
    bool isStaking;
}

contract OdinNFTStaking is Context, Ownable {
    using SafeMath for uint256;

    IODINNFT public iODINNFT;
    IODINToken public iODINToken;
    IMarket public iMarket;

    uint256 nonce;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    address public rewardTokenAddress;
    address public NFTTokenAddress;
    address public MarketAddress;
    address public adminRecoveryAddress;
    uint256[] public rewardPercentage = [5, 10, 15, 20, 25, 30, 35, 40, 50];

    mapping (address => Staker) public stakers;
    mapping (address => mapping(uint256 => bool)) public levelOfOwner;
    mapping (address => uint256) public levelCountOfOwner;

    constructor(address nftAddress_, address rewardAddress_, address adminRecoveryAddress_) {
        rewardTokenAddress = address(rewardAddress_);
        NFTTokenAddress = address(nftAddress_);
        adminRecoveryAddress = adminRecoveryAddress_;
        MarketAddress = address(0);

        iODINNFT = IODINNFT(nftAddress_);
        iODINToken = IODINToken(rewardAddress_);
    }

    receive() external payable {}

    function stake(uint256 _period) external {
        require(isStakable(msg.sender), "Must have at least 2 different NFTs");

        uint256[] memory _tokens = getTokensOfOwner(msg.sender);
        for(uint256 i = 0; i < _tokens.length; i++) {
            iODINNFT.transferFrom(msg.sender, address(this), _tokens[i]);
        }

        stakers[msg.sender].tokenIds = getTokensOfOwner(msg.sender);
        stakers[msg.sender].lastStartTime = _getNow();
        stakers[msg.sender].readyTime = _getNow() + SECONDS_PER_DAY.mul(_period);
        stakers[msg.sender].period = _period;
        stakers[msg.sender].rewardPercentage = setRewardPercentage(msg.sender, _period);
        stakers[msg.sender].bonusPercentage = setStakeLevel(msg.sender);
        stakers[msg.sender].isStaking = true;
    }

    function isStakable (address owner) public returns(bool) {
        require(getTokenCount(owner) > 1, "Must have at least 2 NFTs");
        bool _isStakable = false;
        uint256[] memory levels = iODINNFT.checkAccountLevels(owner);
        
        uint256 levelCount = checkLevels(owner, levels);
        if(levelCount > 1) {
            _isStakable = true;
        }

        return _isStakable;
    }

    function checkLevels(address _owner, uint256[] memory levels) internal returns(uint256) {
        require(levels.length > 0, "nothing levels");
        uint256 levelCount = 0;
        for(uint256 i = 0; i < levels.length; i++) {
            if(!levelOfOwner[_owner][levels[i]]) {
                levelOfOwner[_owner][levels[i]] = true;
                levelCount++;
            }
        }
        levelCountOfOwner[_owner] = levelCount;

        return levelCount;
    }

    function getAccountLevelsInfo(address _owner) public view returns(uint256[] memory) {
        return iODINNFT.checkAccountLevels(_owner);
    }

    function getTokenCount(address _owner) public view returns(uint256) {
        return iODINNFT.balanceOf(_owner);
    }

    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        return iODINNFT.getTokensOfOwner(_owner);
    }

    function getLevelCount(address _owner) public view returns(uint256) {
        return levelCountOfOwner[_owner];
    }

    function random(uint maxNumber) internal returns (uint) {
        uint _random = uint(
            keccak256(
                abi.encodePacked(block.difficulty+uint(keccak256(abi.encodePacked(block.gaslimit))), uint(keccak256(abi.encodePacked(block.timestamp+nonce))), uint(keccak256(abi.encodePacked(msg.sender))))
            )
        ) % maxNumber;
        nonce += _random;
        return _random;
    }

    function getIsStaking(address _owner) public view returns(bool) {
        return stakers[_owner].isStaking;
    }

    function setStakeLevel(address _owner) internal view returns (uint256) {
        uint256 _stakeReward = 0;
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3]) {
            _stakeReward = 5;
        }
        if(levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 10;
        }
        if(levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 15;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3]) {
            _stakeReward = 20;
        }
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 25;
        }
        if(levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 30;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 35;
        }
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 40;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 50;
        }

        return _stakeReward;
    }

    function getRestTime(address _owner) external view returns(uint256) {
        require(stakers[_owner].isStaking, "Must be staked.");
        uint256 _now = _getNow();
        return stakers[_owner].readyTime.sub(_now);
    }

    function _getNow() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getNFTTokenAddress() public view returns(address) {
        return NFTTokenAddress;
    }

    function getRewardTokenAddress() public view returns(address) {
        return rewardTokenAddress;
    }

    function getMarketAddress() public view returns (address) {
        return MarketAddress;
    }

    function setNFTTokenAddress(address _new) external onlyOwner {
        NFTTokenAddress = _new;
    }

    function setRewardTokenAddress(address _new) external onlyOwner {
        rewardTokenAddress = _new;
    }

    function setMarketAddress(address _new) public onlyOwner {
        MarketAddress = _new;
    }

    function setRewardContract() public onlyOwner {
        iODINToken = IODINToken(rewardTokenAddress);
    }

    function setNFTContract() public onlyOwner {
        iODINNFT = IODINNFT(NFTTokenAddress);
    }

    function setMarketContract() public onlyOwner {
        iMarket = IMarket(MarketAddress);
    }

    function isClaimable(address owner) public view returns(bool) {
        require(stakers[owner].isStaking, "Must be staked.");
        uint256 _now = _getNow();

        return _now >= stakers[owner].readyTime;
    }

    function claimReward() external returns(bool) {
        bool isClaimed = isClaimable(msg.sender);
        require(isClaimed, "not ready time");

        uint256 totalToken = IERC20(rewardTokenAddress).balanceOf(address(this));
        bool result = iODINToken.transfer(address(this), msg.sender, totalToken.mul(stakers[msg.sender].rewardPercentage.add(stakers[msg.sender].bonusPercentage)).div(100));

        uint256[] memory _tokens = stakers[msg.sender].tokenIds;
        for(uint256 i = 0; i < _tokens.length; i++) {
            iODINNFT.transferFrom(address(this), msg.sender, _tokens[i]);
        }
        stakers[msg.sender].isStaking = false;

        return result;
    }

    function setRewardPercentage(address _owner, uint256 _period) public view returns (uint256) {
        require(MarketAddress != address(0), "Not started marketplace");

        uint256 _tPrice = 0;
        uint256[] memory _tokens = getTokensOfOwner(_owner);
        for(uint256 i = 0; i < _tokens.length; i++) {
            string memory _paymentType = iMarket.getTokenPaymentType(_tokens[i]);
            if(keccak256(abi.encodePacked((_paymentType))) == keccak256(abi.encodePacked(("BNB")))) {
                uint256 _price = iMarket.getTokenPrice(_tokens[i]);
                _tPrice = _tPrice.add(_price);
            }
        }

        uint256 _adminRecoveryBalance = IERC20(rewardTokenAddress).balanceOf(adminRecoveryAddress);
        uint256 _rewardProfit = (_tPrice.mul(_period)).div((_adminRecoveryBalance.mul(10)));

        return _rewardProfit;
    }

    function getRewardPercentage(address _owner) public view returns(uint256) {
        require(stakers[_owner].isStaking, "Must be staked.");
        return stakers[_owner].rewardPercentage;
    }

    function getStakedTokens(address _owner) public view returns(uint256[] memory) {
        return stakers[_owner].tokenIds;
    } 
}