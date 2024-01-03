// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";
import "./IERC1155.sol";
import "./TheCannabisCommunity.sol";


contract NFTStaking is ReentrancyGuard, Ownable, ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amountETH, uint256 tokenID);
    event Withdrawn(address indexed to, uint256 amountETH, uint256 tokenID);
    event Claimed(address indexed to, uint256 amount);
    event RoundReset();

    TheCannabisCommunity public token;
    uint256 public nftokenID;
    IERC1155 public nftoken;

    struct AccountInfo {
        // Staked LP token balance
        //all their NFTs
        uint256 balance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
        EnumerableSet.UintSet nftokens;        
    }
    mapping(address => AccountInfo) private accountInfos;

    // Staked NFT Total ValueLP token total supply
    uint256 private _totalValue = 0;

    uint256 public constant ROUND_DURATION = 365 days;
    uint256 public rewardAllocation = 9998 * 1e18;
    uint256 public resetTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    // Thu, 03 Dec 2020 12PM EST
    uint256 public farmingStartTimestamp = 1607014800;
    bool public farmingStarted = false;

    constructor(uint256 _id, address _nft) public {
        nftokenID = _id;
        nftoken = IERC1155(_nft);
        // Calc reward rate
        rewardRate = rewardAllocation.div(ROUND_DURATION);
    }

    function setMintable(address _token) external onlyOwner {
        require(address(token) == address(0), "Only Once");
        token = TheCannabisCommunity(_token);
    }

    function stake() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();
        require(accountInfos[msg.sender].balance == 0, "You can only stake one TCC");
        require(!address(msg.sender).isContract(), 'Please use your individual account');
        nftoken.safeTransferFrom(msg.sender, address(this), nftokenID, 1, "");

        uint256 _amount = 1 ether;
        _totalValue = _totalValue.add(_amount);
        // Add NFT
        accountInfos[msg.sender].nftokens.add(nftokenID);
        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(_amount);

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, _amount, nftokenID);
    }

    function withdraw() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();

        require(accountInfos[msg.sender].balance > 0, 'Cannot withdraw 0');
        require(accountInfos[msg.sender].nftokens.contains(nftokenID), 'NFT Not Found');
        //Get the NFT Value
        uint256 _amount = 1 ether;
        //Remove the NFT from accountInfo
        accountInfos[msg.sender].nftokens.remove(nftokenID);

        // Reduce totalValue
        _totalValue = _totalValue.sub(_amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(_amount);
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        
        nftoken.safeTransferFrom(address(this), msg.sender, nftokenID, 1, "");
        emit Withdrawn(msg.sender, _amount, nftokenID);
    }

    function claim() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();

        uint256 reward = accountInfos[msg.sender].reward;
        require(reward > 0, 'There is no reward to claim');

        if (reward > 0) {
            // Reduce first
            accountInfos[msg.sender].reward = 0;

            // Send reward
            token.mint(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }
     
    function totalValue() external view returns (uint256) {
        return _totalValue;
    }

    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    function nftBalanceOf(address account) external view returns (uint256) {
        return accountInfos[account].nftokens.length();
    }

    function tokenOfOwnerByIndex(address account) external view returns(uint256) {
        return accountInfos[account].nftokens.at(nftokenID);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalValue == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(rewardRate) //rate per second
            .mul(1e18)
            .div(_totalValue)
        );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, resetTimestamp);
    }

    function rewardEarned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTimestamp = lastRewardTimestamp();
        if (account != address(0)) {
            accountInfos[account].reward = rewardEarned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    // Announce Round Reset
    function _reset() internal {
        if (block.timestamp >= resetTimestamp) {
            rewardAllocation = 0;
            _updateReward(msg.sender);
            emit RoundReset();
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(farmingStartTimestamp <= block.timestamp, 'Please wait until farming started');
        if (!farmingStarted) {
            farmingStarted = true;
            resetTimestamp = block.timestamp.add(ROUND_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }
}