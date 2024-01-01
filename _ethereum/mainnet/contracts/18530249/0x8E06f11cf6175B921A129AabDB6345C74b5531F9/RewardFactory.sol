//SPDX-License-Identifier: MIT

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.8.19;

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/libraries/Context.sol

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: contracts/libraries/Ownable.sol

pragma solidity ^0.8.19;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function isFeeExempt(address addr) external view returns (bool);

    function getTradingInfo(address trader) external view returns (uint256, uint256, uint256);

    function getTotalTradingInfo() external view returns (uint256, uint256, uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/RewardFactory.sol

pragma solidity ^0.8.19;

contract RewardFactory is Ownable {
    using SafeMath for uint256;

    IERC20 _interfaceOfLILY;

    uint256 _rewardExpiry = 48 hours;
    uint256 _rewardSync;
    uint256 _rewardDecayRate = 5;

    uint256 _totalRewardAllocation = 75;
    uint256 _holdingRewardAllocation = 20;
    uint256 _boughtRewardAllocation = 60;
    uint256 _soldRewardAllocation = 15;
    uint256 _transferredRewardAllocation = 5;
    uint256 _holdingRewardRatio = 1;
    uint256 _boughtRewardRatio = 1;
    uint256 _soldRewardRatio = 3;
    uint256 _transferredRewardRatio = 1;

    address _liquidityWallet;
    address _companyWallet;

    uint256 _liquidityWalletTaxBackward = 60;
    uint256 _rewardWalletTaxBackward = 30;
    uint256 _companyWalletTaxBackward = 10;

    mapping(address => uint256) _lastClaimed;

    event SetRewardExpiry(uint256 rewardExpiry);
    event SetRewardSync(uint256 rewardSync);
    event SetRewardDecayRate(uint256 rewardDecayRate);
    event SetRewardRatio(uint256 holdingRewardRatio, uint256 boughtRewardRatio, uint256 soldRewardRatio, uint256 transferredRewardRatio);
    event SetRewardAllocation(uint256 totalRewardAllocation, uint256 holdingRewardAllocation, uint256 boughtRewardAllocation, uint256 soldRewardAllocation, uint256 transferredRewardAllocation);
    event SetTaxWallet(address liquidityWallet, address companyWallet);
    event SetTaxBackward(uint256 liquidityWalletTaxBackward, uint256 rewardWalletTaxBackward, uint256 companyWalletTaxBackward);
    event ClaimReward(address to, uint256 amount, uint256 lastClaimed);

    constructor(address tokenAddress) {
        _interfaceOfLILY = IERC20(tokenAddress);
    }

    function setRewardExpiry(uint256 rewardExpiry) external onlyOwner {
        require(rewardExpiry > 0, "RewardFactory:: Reward expiry should be longer than zero");
        _rewardExpiry = rewardExpiry;
        emit SetRewardExpiry(rewardExpiry);
    }

    function setRewardSync() external onlyOwner {
        _rewardSync = block.timestamp;
        emit SetRewardSync(_rewardSync);
    }

    function setRewardDecayRate(uint256 rewardDecayRate) external onlyOwner {
        require(rewardDecayRate > 0 && rewardDecayRate < 100, "RewardFactory:: Reward decay rate should be in the proper range");
        _rewardDecayRate = rewardDecayRate;
        emit SetRewardDecayRate(rewardDecayRate);
    }

    function setRewardRatio(uint256 holdingRewardRatio, uint256 boughtRewardRatio, uint256 soldRewardRatio, uint256 transferredRewardRatio) external onlyOwner {
        require(holdingRewardRatio > 0 && holdingRewardRatio < 100, "RewardFactory:: Reward ratio should be in the proper range");
        require(boughtRewardRatio > 0 && boughtRewardRatio < 100, "RewardFactory:: Reward ratio should be in the proper range");
        require(soldRewardRatio > 0 && soldRewardRatio < 100, "RewardFactory:: Reward ratio should be in the proper range");
        require(transferredRewardRatio > 0 && transferredRewardRatio < 100, "RewardFactory:: Reward ratio should be in the proper range");
        _holdingRewardRatio = holdingRewardRatio;
        _boughtRewardRatio = boughtRewardRatio;
        _soldRewardRatio = soldRewardRatio;
        _transferredRewardRatio = transferredRewardRatio;
        emit SetRewardRatio(holdingRewardRatio, boughtRewardRatio, soldRewardRatio, transferredRewardRatio);
    }

    function setRewardAllocation(uint256 totalRewardAllocation, uint256 holdingRewardAllocation, uint256 boughtRewardAllocation, uint256 soldRewardAllocation, uint256 transferredRewardAllocation) external onlyOwner {
        require(totalRewardAllocation > 0 && totalRewardAllocation < 100, "RewardFactory:: Total reward allocation should be in the proper range");
        require(holdingRewardAllocation + boughtRewardAllocation + soldRewardAllocation + transferredRewardAllocation == 100, "RewardFactory:: Reward allocation is not correct");
        _totalRewardAllocation = totalRewardAllocation;
        _holdingRewardAllocation = holdingRewardAllocation;
        _boughtRewardAllocation = boughtRewardAllocation;
        _soldRewardAllocation = soldRewardAllocation;
        _transferredRewardAllocation = transferredRewardAllocation;
        emit SetRewardAllocation(totalRewardAllocation, holdingRewardAllocation, boughtRewardAllocation, soldRewardAllocation, transferredRewardAllocation);
    }

    function setTaxWallet(address liquidityWallet, address companyWallet) external onlyOwner {
        _liquidityWallet = liquidityWallet;
        _companyWallet = companyWallet;
        emit SetTaxWallet(liquidityWallet, companyWallet);
    }

    function setTaxBackward(uint256 liquidityWalletTaxBackward, uint256 rewardWalletTaxBackward, uint256 companyWalletTaxBackward) external onlyOwner {
        require(liquidityWalletTaxBackward + rewardWalletTaxBackward + companyWalletTaxBackward == 100, "RewardFactory:: Tax backward is not correct");
        _liquidityWalletTaxBackward = liquidityWalletTaxBackward;
        _rewardWalletTaxBackward = rewardWalletTaxBackward;
        _companyWalletTaxBackward = companyWalletTaxBackward;
        emit SetTaxBackward(liquidityWalletTaxBackward, rewardWalletTaxBackward, companyWalletTaxBackward);
    }

    function claimRewards() external {
        uint256 holdingAmount = _interfaceOfLILY.balanceOf(msg.sender);
        (uint256 boughtAmount, uint256 soldAmount, uint256 transferredAmount) = _interfaceOfLILY.getTradingInfo(msg.sender);
        
        if (_interfaceOfLILY.isFeeExempt(msg.sender) || _interfaceOfLILY.balanceOf(address(this)) == 0) {
            emit ClaimReward(msg.sender, 0, 0);
            return;
        }

        uint256 totalSupply = _interfaceOfLILY.totalSupply();
        (uint256 totalBoughtAmount, uint256 totalSoldAmount, uint256 totalTransferredAmount) = _interfaceOfLILY.getTotalTradingInfo();

        uint256 userReward = getHoldingReward(holdingAmount, totalSupply) +
                             getBoughtReward(boughtAmount, totalBoughtAmount) +
                             getSoldReward(soldAmount, totalSoldAmount) +
                             getTransferredReward(transferredAmount, totalTransferredAmount);

        (uint256 decayAmount, uint256 claimAmount) = getClaimInfo(userReward);
        if (claimAmount > 0)
            _interfaceOfLILY.transfer(msg.sender, claimAmount);
        if (decayAmount > 0) {
            _interfaceOfLILY.transfer(_liquidityWallet, decayAmount.mul(_liquidityWalletTaxBackward).div(100));
            _interfaceOfLILY.transfer(_companyWallet, decayAmount.mul(_companyWalletTaxBackward).div(100));
        }
        _lastClaimed[msg.sender] = block.timestamp;
        emit ClaimReward(msg.sender, claimAmount, _lastClaimed[msg.sender]);
    }

    function specialClaim(uint256 amount) external onlyOwner {
        require(amount > 0, "RewardFactory:: Amount should be greater than 0");
        require(amount <= _interfaceOfLILY.balanceOf(address(this)), "RewardFactory:: Amount should not be greater than the contract balance");
        _interfaceOfLILY.transfer(msg.sender, amount);
    }

    function getHoldingReward(uint256 holdingAmount, uint256 totalSupply) public view returns (uint256) {
        return _interfaceOfLILY.balanceOf(address(this)).mul(holdingAmount).mul(_holdingRewardRatio).mul(_totalRewardAllocation).mul(_holdingRewardAllocation).div(totalSupply).div(10000);
    }

    function getBoughtReward(uint256 boughtAmount, uint256 totalBoughtAmount) public view returns (uint256) {
        if (totalBoughtAmount < 1)
            return 0;
        else
            return _interfaceOfLILY.balanceOf(address(this)).mul(boughtAmount).mul(_boughtRewardRatio).mul(_totalRewardAllocation).mul(_boughtRewardAllocation).div(totalBoughtAmount).div(10000);
    }

    function getSoldReward(uint256 soldAmount, uint256 totalSoldAmount) public view returns (uint256) {
        if (totalSoldAmount < 1)
            return 0;
        else
            return _interfaceOfLILY.balanceOf(address(this)).mul(soldAmount).mul(_soldRewardRatio).mul(_totalRewardAllocation).mul(_soldRewardAllocation).div(totalSoldAmount).div(10000);
    }

    function getTransferredReward(uint256 transferredAmount, uint256 totalTransferredAmount) public view returns (uint256) {
        if (totalTransferredAmount < 1)
            return 0;
        else
            return _interfaceOfLILY.balanceOf(address(this)).mul(transferredAmount).mul(_transferredRewardRatio).mul(_totalRewardAllocation).mul(_transferredRewardAllocation).div(totalTransferredAmount).div(10000);
    }

    function getLastClaimedTime(address addr) public view returns (uint256) {
        return _lastClaimed[addr];
    }

    function getClaimInfo(uint256 userReward) public view returns (uint256, uint256) {
        require(_rewardSync > 0, "RewardFactory:: Reward sync should be set");
        uint256 rewardExpiryMod;
        if (_lastClaimed[msg.sender] == 0)
            rewardExpiryMod = (block.timestamp - _rewardSync).div(_rewardExpiry);
        else {
            rewardExpiryMod = ((block.timestamp - _rewardSync).div(_rewardExpiry)).sub((_lastClaimed[msg.sender] - _rewardSync).div(_rewardExpiry));
            if (rewardExpiryMod > 0)
                rewardExpiryMod -= 1;
        }
        uint256 decayAmount = userReward.mul(_rewardDecayRate).mul(rewardExpiryMod).div(100);
        if (decayAmount > userReward)
            decayAmount = userReward;
        uint256 claimAmount = userReward - decayAmount;

        return (decayAmount, claimAmount);
    }

    function getRewardInfo() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (_rewardExpiry, _rewardDecayRate, _holdingRewardAllocation, _boughtRewardAllocation, _soldRewardAllocation, _transferredRewardAllocation, _rewardSync);
    }
}