
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// Openzeppelin imports
import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

/// Local imports
import "./PVTToken.sol";
import "./IStrategy.sol";


/**
 * @title Implementation of the SyncDao Manager
 */
contract Manager is AccessControl {

    using SafeERC20 for ERC20;
    using SafeERC20 for PVTToken;

    /// Public types

    struct Stake {
            uint256 pvtAmount;
            uint256 lastBlockNumber;
            uint256 lastTotalWork;
            uint256 rewardsTaken;
    }

    struct Affiliate {
            address affiliateAddress;
            uint256 percentage;
            uint256 ownerPercentage;
            bool valid;
    }

    /// Public variables
    uint256 public constant RATE_COEF = 100;

    mapping(address => Affiliate) public affiliateMapping;
    address public defaultAffiliate;
    uint256 public affiliatePercentage = 10;
    uint256 public ownerPercentage = 5;
    uint256 public tokenRateT = 1;
    uint256 public tokenRateB = 1;

    PVTToken public pvtToken;
    IStrategy public strategy;

    mapping(address => Stake) public stakesMapping;
    address[] stakersLookup;

    Stake public ownerStake;


    uint256 public totalStableTokenAmount = 0;
    uint256 public lastBlockNumber = 0;
    uint256 public lastTotalWork = 0;
    uint256 public rewardsTaken = 0;
    uint256 public totalPVTAmount = 0;

    /// Events
    event Minted(address indexed minter, uint256 pvtAmount);
    event Staked(address indexed staker, uint256 pvtAmount);
    event Unstaked(address indexed staker, uint256 pvtAmount);
    event RewardTaken(address indexed staker, uint256 amount);


    /// Constructor
    constructor(address pvtTokenAddress_, address initialStrategyAddress_) {

        lastBlockNumber = block.number;
        strategy = IStrategy(initialStrategyAddress_);
        require(address(0x0) != address(strategy), 'Strategy cannot be null');
        pvtToken = PVTToken(pvtTokenAddress_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        defaultAffiliate = _msgSender();
        changeTokenRate(RATE_COEF);
    }

    /// Public member functions

    function getTokenRate() view public returns (uint256) {

        uint256 pd = pvtToken.decimals();
        uint256 sd = ERC20(strategy.vaultTokenAddress()).decimals();
        if (pd >= sd) {
            return tokenRateT / (10 ** (pd - sd));
        } else {
            return tokenRateT;
        }
    }

    function changeTokenRate(uint256 rate_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(0 < rate_, 'Token rate cannot be 0');

        uint256 pd = pvtToken.decimals();
        uint256 sd = ERC20(strategy.vaultTokenAddress()).decimals();
        if (pd >= sd) {
            tokenRateT = rate_ * (10 ** (pd - sd));
            tokenRateB = RATE_COEF;
        } else {
            tokenRateT = rate_;
            tokenRateB = RATE_COEF * (10 ** (sd - pd));
        }
    }

    function changeAffiliatePercentage(uint256 percentage_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(0 <= percentage_ && percentage_ <= 100, 'Percentage must be from 0 to 100');
        affiliatePercentage = percentage_;
    }

    function changeOwnerPercentage(uint256 percentage_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(0 <= percentage_ && percentage_ <= 100, 'Percentage must be from 0 to 100');
        ownerPercentage = percentage_;
    }

    function changeDefaultAffiliate(address newDefaultAffiliateAddress_)
                public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(address(0x0) != newDefaultAffiliateAddress_, 'defaultAffiliate cannot be null');
        defaultAffiliate = newDefaultAffiliateAddress_;
    }

    function getStakers() public view returns(address[] memory) {

        return stakersLookup;
    }

    function changeStrategy(address newStrategyAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(address(0x0) != newStrategyAddress_, 'strategy cannot be null');
        strategy = IStrategy(newStrategyAddress_);
    }

    function mintPVTToken(uint256 amount_, address erc20Token_,
                          address affiliateAddress_, bool autoStake_) public {

        require(affiliateAddress_ != _msgSender(), 'User cannot be affiliate');
        uint256 stableTokenAmount = ERC20(erc20Token_).allowance(_msgSender(), address(this));
        if (0 != amount_) {
            require(amount_ <= stableTokenAmount, 'There is no allowance');
            stableTokenAmount = amount_;
        }
        require(0 != stableTokenAmount, 'There is no allowance');
        ERC20(erc20Token_).safeTransferFrom(_msgSender(), address(this), stableTokenAmount);
        (bool success, bytes memory result) = address(strategy).delegatecall(abi.encodeWithSignature(
                        'farm(address,uint256)', erc20Token_, stableTokenAmount));
        require(success, 'Delegate call failed');
        stableTokenAmount = abi.decode(result, (uint256));
        _mintPVTToken(stableTokenAmount, autoStake_);
        _setAffiliateIfNeeded(_msgSender(), affiliateAddress_);
    }

    function stake(uint256 amount_, address affiliateAddress_) public {

        require(affiliateAddress_ != _msgSender(), 'User cannot be affiliate');
        uint256 pvtAmount = pvtToken.allowance(_msgSender(), address(this));
        if (0 != amount_) {
            require(amount_ <= pvtAmount, 'There is no allowance');
            pvtAmount = amount_;
        }
        require(0 < pvtAmount, 'There is no allowance');
        pvtToken.safeTransferFrom(_msgSender(), address(this), pvtAmount);
        _stake(_msgSender(), pvtAmount);
        ownerStake.lastTotalWork += ownerStake.pvtAmount * (block.number - ownerStake.lastBlockNumber);
        ownerStake.lastBlockNumber = block.number;
        ownerStake.pvtAmount -= pvtAmount;
        _setAffiliateIfNeeded(_msgSender(), affiliateAddress_);
    }

    function unstake(uint256 amount_) public {

        require(0 < amount_, 'amount_ cannot be 0');
        Stake storage s = stakesMapping[_msgSender()];
        require(s.pvtAmount >= amount_, 'Not enough tokens');
        pvtToken.safeTransfer(_msgSender(), amount_);
        uint256 a = estimateReward(_msgSender());
        if (0 != a) {
            _takeReward(a);
        }
        s.lastTotalWork += (block.number - s.lastBlockNumber) * s.pvtAmount;
        s.pvtAmount -= amount_;
        s.lastBlockNumber = block.number;

        ownerStake.lastTotalWork += ownerStake.pvtAmount * (block.number - ownerStake.lastBlockNumber);
        ownerStake.lastBlockNumber = block.number;
        ownerStake.pvtAmount += amount_;

        emit Unstaked(_msgSender(), amount_);
    }

    function estimateReward(address userAddress) public view returns (uint256) {

        return _estimateStakeReward(stakesMapping[userAddress]);
    }

    function takeRewardWithExpectedTokens(
            address[] memory expectedTokens_,
            uint256[] memory percentages_,
            bool autoStake_) public {

        uint256 amount = estimateReward(_msgSender());
        require (0 < amount, 'There is no reward');
        _takeReward(amount, expectedTokens_, percentages_, autoStake_);
    }

    function takeReward() public {

        uint256 amount = estimateReward(_msgSender());
        require (0 < amount, 'There is no reward');
        _takeReward(amount);
    }

    function estimateOwnerReward() public view returns (uint256) {

        return _estimateStakeReward(ownerStake);
    }

    function takeOwnerReward(address recipientAddress_)
                    public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(address(0x0) != address(recipientAddress_), 'recipientAddress_ cannot be null');
        uint256 amount = estimateOwnerReward();
        require (0 < amount, 'There is no reward');
        _delegateTakeRewardIfNeeded(recipientAddress_, strategy.vaultTokenAddress(), amount);
        ownerStake.rewardsTaken += amount;
        rewardsTaken += amount;
    }

    function takeAllStableTokens(address newPVTTokenAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        (bool success,) =
            address(strategy).delegatecall(abi.encodeWithSignature('takeReward(address)', _msgSender()));
        require(success, 'Delegate call failed');
        if (address(0x0) != newPVTTokenAddress_) {
            pvtToken = PVTToken(newPVTTokenAddress_);
            _reset();
        }
    }

    /// Helper private functions

    function _mintPVTToken(uint256 stableTokenAmount_, bool autoStake_) private {

        uint256 pvtAmount = stableTokenAmount_ * tokenRateT / tokenRateB;
        lastTotalWork += totalPVTAmount * (block.number - lastBlockNumber);
        if (autoStake_) {
            pvtToken.mint(address(this), pvtAmount);
            _stake(_msgSender(), pvtAmount);
        } else {
            pvtToken.mint(_msgSender(), pvtAmount);
            ownerStake.lastTotalWork += ownerStake.pvtAmount * (block.number - ownerStake.lastBlockNumber);
            ownerStake.lastBlockNumber = block.number;
            ownerStake.pvtAmount += pvtAmount;
        }
        totalPVTAmount += pvtAmount;
        lastBlockNumber = block.number;
        totalStableTokenAmount += stableTokenAmount_;

        emit Minted(_msgSender(), pvtAmount);
    }

    function _estimateStakeReward(Stake memory stake_) private view returns (uint256) {

        uint256 e = strategy.estimateReward(address(this));
        if (e <= totalStableTokenAmount) {
            return 0;
        }
        uint256 work = stake_.lastTotalWork + stake_.pvtAmount * (block.number - stake_.lastBlockNumber);
        uint256 Work = lastTotalWork + totalPVTAmount * (block.number - lastBlockNumber);

        uint256 Amount = e + rewardsTaken - totalStableTokenAmount;
        uint256 amount = work * Amount / Work;
        if  (amount <= stake_.rewardsTaken) {
            return 0;
        }
        uint256 total = amount - stake_.rewardsTaken;
        return total > e - totalStableTokenAmount ? e - totalStableTokenAmount : total;
    }

    function _setAffiliateIfNeeded(address userAddress_, address affiliateAddress_) private {

        if (! affiliateMapping[userAddress_].valid) {
            if (address(0x0) != affiliateAddress_) {
                affiliateMapping[userAddress_].affiliateAddress = affiliateAddress_;
            }
            affiliateMapping[userAddress_].ownerPercentage = ownerPercentage;
            affiliateMapping[userAddress_].percentage = affiliatePercentage;
            affiliateMapping[userAddress_].valid = true;
        }
    }

    function _stake(address userAddress_, uint256 pvtAmount_) private {

        Stake storage s = stakesMapping[userAddress_];
        if (0 == s.lastBlockNumber) {
            stakersLookup.push(userAddress_);
        } else {
            s.lastTotalWork += (block.number - s.lastBlockNumber) * s.pvtAmount;
        }
        s.pvtAmount += pvtAmount_;
        s.lastBlockNumber = block.number;

        emit Staked(userAddress_, pvtAmount_);
    }

    function _takeReward(uint256 amount_) private {

        require(affiliateMapping[_msgSender()].valid); // TODO Is it need or not
        _distributeReward(amount_,
                            amount_ * affiliateMapping[_msgSender()].ownerPercentage / 100,
                            affiliateMapping[_msgSender()].affiliateAddress,
                            amount_ * affiliateMapping[_msgSender()].percentage / 100);
        stakesMapping[_msgSender()].rewardsTaken += amount_;
        rewardsTaken += amount_;

        emit RewardTaken(_msgSender(), amount_);
    }

    function _takeReward(uint256 amount_,
                            address[] memory expectedTokens_,
                            uint256[] memory percentages_,
                            bool autoStake_) private {

        require(affiliateMapping[_msgSender()].valid); // TODO Is it need or not
        require(0 != expectedTokens_.length, 'lenght of array cannot be 0');
        require(expectedTokens_.length == percentages_.length,
                            'expectedTokens and percentages lenght must be the same');
        uint256 ownerAmount = amount_ * affiliateMapping[_msgSender()].ownerPercentage / 100;
        uint256 affiliateAmount = amount_ * affiliateMapping[_msgSender()].percentage / 100;
        uint256 amount = amount_ - affiliateAmount - ownerAmount;
        uint256 sum = 0;
        uint256 pSum = 0;
        for (uint256 i = 0; i < expectedTokens_.length - 1; ++i) {
            require(address(0x0) != expectedTokens_[i], 'expected token cannot be null');
            require(0 != percentages_[i], 'percentage cannot be 0');
            uint256 am = amount * percentages_[i] / 100;
            if (expectedTokens_[i] == address(pvtToken)) {
                _mintPVTToken(am, autoStake_);
            } else {
                _delegateTakeRewardIfNeeded(_msgSender(), expectedTokens_[i], am);
            }
            sum += am;
            pSum += percentages_[i];
        }
        require(address(0x0) != expectedTokens_[expectedTokens_.length - 1], 'expected token cannot be null');
        require(0 != percentages_[percentages_.length - 1], 'percentage cannot be 0');
        require(100 == pSum + percentages_[percentages_.length - 1], 'sum of percentages must be 100');
        if (expectedTokens_[expectedTokens_.length - 1] == address(pvtToken)) {
            _mintPVTToken(amount - sum, autoStake_);
        } else {
            _delegateTakeRewardIfNeeded(_msgSender(), expectedTokens_[expectedTokens_.length - 1], amount - sum);
        }
        _distributeReward(ownerAmount + affiliateAmount, ownerAmount,
                            affiliateMapping[_msgSender()].affiliateAddress, affiliateAmount);
        stakesMapping[_msgSender()].rewardsTaken += amount_;
        rewardsTaken += amount_;

        emit RewardTaken(_msgSender(), amount_);
    }

    function _distributeReward(uint256 totalAmount_,
                               uint256 ownerAmount_,
                               address affiliateAddress_,
                               uint256 affiliateAmount_) private {

        _delegateTakeRewardIfNeeded(_msgSender(), strategy.vaultTokenAddress(),
                                   totalAmount_ - ownerAmount_ - affiliateAmount_);
        if (address(0x0) == affiliateAddress_) {
            _delegateTakeRewardIfNeeded(defaultAffiliate,
                                        strategy.vaultTokenAddress(),
                                        affiliateAmount_ + ownerAmount_);
        } else {
            _delegateTakeRewardIfNeeded(defaultAffiliate, strategy.vaultTokenAddress(), ownerAmount_);
            _delegateTakeRewardIfNeeded(affiliateAddress_, strategy.vaultTokenAddress(), affiliateAmount_);
        }
    }

    function _delegateTakeRewardIfNeeded(address address_, address expectedToken_, uint256 amount_) private {

        if (0 != amount_) {
            (bool success,) = address(strategy).delegatecall(
                                        abi.encodeWithSignature('takeReward(address,address,uint256)',
                                        address_, expectedToken_, amount_));
            require(success, 'Delegate call takeReward failed');
        }
    }

    function _reset() private {

        affiliatePercentage = 10;
        ownerPercentage = 5;
        changeTokenRate(RATE_COEF);
        for (uint256 i = 0; i < stakersLookup.length; ++i) {
            address s = stakersLookup[i];
            stakesMapping[s].lastBlockNumber = 0;
            stakesMapping[s].pvtAmount = 0;
            stakesMapping[s].lastTotalWork = 0;
            stakesMapping[s].rewardsTaken = 0;

            affiliateMapping[s].affiliateAddress = address(0x0);
            affiliateMapping[s].percentage = 0;
            affiliateMapping[s].ownerPercentage = 0;
            affiliateMapping[s].valid = false;
        }
        delete stakersLookup;
        ownerStake.pvtAmount = 0;
        ownerStake.lastBlockNumber = 0;
        ownerStake.lastTotalWork = 0;
        ownerStake.rewardsTaken = 0;
        totalStableTokenAmount = 0;
        lastBlockNumber = block.number;
        lastTotalWork = 0;
        rewardsTaken = 0;
        totalPVTAmount = 0;
        //defaultAffiliate;
        //strategy;
    }
}
