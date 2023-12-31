// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IEGMC.sol";
import "./IEGMCShareholderDistributor.sol";

contract EGMCShareholderPool is Ownable, ERC1155Holder {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IERC20 public immutable lpToken;
    IERC1155 public nft;

    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;

    address public shareholderDistributor;
    uint public allTimeTokenRewards;
    uint public allTimeTokenRewardsClaimed;
    uint public allTimeLpRewards;
    uint public allTimeLpRewardsClaimed;
    uint public totalStaked;
    uint public currentTokenRewardFactor;
    uint public currentLpRewardFactor;
    bool public isDepositingEnabled;

    struct User {
        uint tokenRewardFactor;
        uint tokenHeldRewards;
        uint lpRewardFactor;
        uint lpHeldRewards;
        uint staked;
    }

    mapping(address => User) private _users;
    mapping(address => bool) private _whitelisted;

    event DepositingEnabled();
    event DepositingDisabled();
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claimed(address user, uint tokenRewards, uint lpRewards);
    event Distributed(uint tokenRewards, uint lpRewards, uint totalStaked);

    constructor (
        address _token,
        address _nft
    ) {
        token = IERC20(_token);
        lpToken = IERC20(IEGMC(_token).uniswapV2Pair());
        nft = IERC1155(_nft);

        _whitelisted[_msgSender()] = true;
    }

    /** VIEW FUNCTIONS */

    function getAmounts() external view returns (uint tokenAmount, uint lpAmount) {
        (lpAmount, , tokenAmount) = IEGMCShareholderDistributor(shareholderDistributor).getAmounts();
    }

    function getStake(address _user) external view returns (uint) {
        return _users[_user].staked;
    }

    function getReward(address _user) external view returns (uint tokenReward, uint lpReward) {
        tokenReward = _getTokenHeldRewards(_user) + _getTokenCalculatedRewards(_user);
        lpReward = _getLpHeldRewards(_user) + _getLpCalculatedRewards(_user);
    }

    function _getTokenHeldRewards(address _user) private view returns (uint) {
        return _users[_user].tokenHeldRewards;
    }

    function _getLpHeldRewards(address _user) private view returns (uint) {
        return _users[_user].lpHeldRewards;
    }

    function _getTokenCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].staked;
        return balance * (currentTokenRewardFactor - _users[_user].tokenRewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    function _getLpCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].staked;
        return balance * (currentLpRewardFactor - _users[_user].lpRewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    function _mergeRewards(address _account) private {
        _holdCalculatedRewards(_account);
        _users[_account].tokenRewardFactor = currentTokenRewardFactor;
        _users[_account].lpRewardFactor = currentLpRewardFactor;
    }

    function _holdCalculatedRewards(address _account) private {
        uint calculatedTokenReward = _getTokenCalculatedRewards(_account);
        if (calculatedTokenReward > 0) {
            _users[_account].tokenHeldRewards += calculatedTokenReward;
        }

        uint calculatedLpReward = _getLpCalculatedRewards(_account);
        if (calculatedLpReward > 0) {
            _users[_account].lpHeldRewards += calculatedLpReward;
        }
    }

    /** INTERNAL FUNCTIONS */

    function _distribute() internal {
        if (totalStaked > 0) {
            (uint lpAmount, uint tokenAmount) = IEGMCShareholderDistributor(shareholderDistributor).distribute();

            if (tokenAmount > 0) {
                allTimeTokenRewards += tokenAmount;
                currentTokenRewardFactor += REWARD_FACTOR_ACCURACY * tokenAmount / totalStaked;
            }

            if (lpAmount > 0) {
                allTimeLpRewards += lpAmount;
                currentLpRewardFactor += REWARD_FACTOR_ACCURACY * lpAmount / totalStaked;
            }

            emit Distributed(tokenAmount, lpAmount, totalStaked);
        }
    }

    function _deposit(address _user, uint _amount, bool _transfer) internal {
        require(isDepositingEnabled, "Depositing is not allowed at this time");

        _mergeRewards(_user);
        _users[_user].staked += _amount;
        totalStaked += _amount;
        
        if (_transfer) {
            nft.safeTransferFrom(_user, address(this), 1, _amount, "");
        }

        emit Deposit(_user, _amount);
    }

    /** EXTERNAL FUNCTIONS */

    function deposit(uint _amount) external {
        _deposit(_msgSender(), _amount, true);
    }

    function depositFor(address _user, uint _amount) external {
        require(_msgSender() == address(nft), "Only the NFT contract can call this function");
        _deposit(_user, _amount, false);
    }

    function withdraw(uint _amount) external {
        User storage user = _users[_msgSender()];
        require(_amount > 0, "Amount to withdraw must be greater than zero");
        require(_amount <= user.staked, "Amount exceeds staked");

        _mergeRewards(_msgSender());
        _users[_msgSender()].staked -= _amount;
        totalStaked -= _amount;
        nft.safeTransferFrom(address(this), _msgSender(), 1, _amount, "");

        emit Withdraw(_msgSender(), _amount);
    }

    function claim(uint action) external {
        require(action > 0 && action <= 3, "Invalid action parameter");
        _mergeRewards(_msgSender());

        uint tokenHeldRewards;
        if (action == 1 || action == 3) {
            tokenHeldRewards = _users[_msgSender()].tokenHeldRewards;
            if (tokenHeldRewards > 0) {
                _users[_msgSender()].tokenHeldRewards = 0;
                allTimeTokenRewardsClaimed += tokenHeldRewards;
                token.safeTransfer(_msgSender(), tokenHeldRewards);
            }
        }

        uint lpHeldRewards;
        if (action == 2 || action == 3) {
            lpHeldRewards = _users[_msgSender()].lpHeldRewards;
            if (lpHeldRewards > 0) {
                _users[_msgSender()].lpHeldRewards = 0;
                allTimeLpRewardsClaimed += lpHeldRewards;
                lpToken.safeTransfer(_msgSender(), lpHeldRewards);
            }
        }

        emit Claimed(_msgSender(), tokenHeldRewards, lpHeldRewards);
    }

    /** RESTRICTED FUNCTIONS */

    function distribute() external {
        require(_whitelisted[_msgSender()], "Caller is not whitelisted!");
        _distribute();
    }

    function enableDepositing() external onlyOwner {
        require(!isDepositingEnabled, "Depositing is already enabled");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    function disableDepositing() external onlyOwner {
        require(isDepositingEnabled, "Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    function setShareholderDistributor(address _distributor) external onlyOwner {
        shareholderDistributor = _distributor;
    }

    function setWhitelist(address _account, bool _enabled) external onlyOwner {
        _whitelisted[_account] = _enabled;
    }

    function recover(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}