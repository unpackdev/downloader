// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";

/// @author Jorge Gomes Durán (jorge@smartrights.io)
/// @title A vesting contract to lock tokens for iCommunity token Icom

contract CompanyVesting {

    enum WalletType {
        ICOHolders,
        Marketing,
        Team,
        Staking,
        Foundation,
        Treasury
    }

    // Wallets
    address immutable private icoHoldersWallet;
    address immutable private marketingWallet;
    address immutable private teamWallet;
    address immutable private stakingWallet;
    address immutable private foundationWallet;
    address immutable private treasuryWallet;
    
    address immutable private icomToken;
    address immutable private owner;

    uint32 private listingDate;
    uint256[6] internal withdrawnBalances;

    uint32 constant private MAX_LISTING_DATE = 1672441200;  // 2022/12/31 00:00:00
    uint256 constant private ICOHOLDERS_MAX = 18333608 * 10 ** 18;
    uint256 constant private STAKING_MAX_FIRST_YEAR = 2500000 * 10 ** 18;
    uint256 constant private STAKING_MAX_AFTER_FIRST_YEAR = 12500000 * 10 ** 18;
    uint256 constant private MARKETING_MAX = 9666392 * 10 ** 18;
    uint256 constant private TEAM_MAX = 15000000 * 10 ** 18;
    uint256 constant private FOUNDATION_MAX = 4000000 * 10 ** 18;
    uint256 constant private TREASURY_MAX = 30000000 * 10 ** 18;

    event onWithdrawToken(uint256 _type, uint256 _amount);

    constructor(address _token, address _icoHoldersWallet, address _marketingWallet, address _teamWallet, address _stakingWallet, address _foundationWallet, address _treasuryWallet) {
        icoHoldersWallet = _icoHoldersWallet;
        marketingWallet = _marketingWallet;
        teamWallet = _teamWallet;
        stakingWallet = _stakingWallet;
        foundationWallet = _foundationWallet;
        treasuryWallet = _treasuryWallet;
        icomToken = _token;
        owner = msg.sender;
    }

    function setListingDate(uint32 _listingDate) external {
        require(msg.sender == owner, "OnlyOwner");
        require(_listingDate < MAX_LISTING_DATE, "CantDelayMoreListing");
        require(block.timestamp < _listingDate, "CantListInPast");

        listingDate = _listingDate;
    }

    function withdrawICOHoldersTokens() external {
        require(block.timestamp >= listingDate + 150 days, "TooEarly");
        require(withdrawnBalances[uint256(WalletType.ICOHolders)] < ICOHOLDERS_MAX, "MaxBalance");

        withdrawnBalances[uint256(WalletType.ICOHolders)] += ICOHOLDERS_MAX;
        _sendTokens(uint256(WalletType.ICOHolders), ICOHOLDERS_MAX);
    }

    function withdrawStakingTokens() external {
        require(block.timestamp >= listingDate, "TooEarly");

        if (block.timestamp < listingDate + 365 days) {
            require(withdrawnBalances[uint256(WalletType.Staking)] < STAKING_MAX_FIRST_YEAR, "MaxBalance");

            withdrawnBalances[uint256(WalletType.Staking)] += STAKING_MAX_FIRST_YEAR;
            _sendTokens(uint256(WalletType.Staking), STAKING_MAX_FIRST_YEAR);
        } else {
            require(withdrawnBalances[uint256(WalletType.Staking)] < STAKING_MAX_FIRST_YEAR + STAKING_MAX_AFTER_FIRST_YEAR, "MaxBalance");

            uint256 pendingBalance = STAKING_MAX_AFTER_FIRST_YEAR + STAKING_MAX_FIRST_YEAR - withdrawnBalances[uint256(WalletType.Staking)];
            withdrawnBalances[uint256(WalletType.Staking)] += pendingBalance;
            _sendTokens(uint256(WalletType.Staking), pendingBalance);
        }
    }

    function withdrawMarketingTokens() external {
        require(block.timestamp >= listingDate + 150 days, "TooEarly");
        require(withdrawnBalances[uint256(WalletType.Marketing)] < MARKETING_MAX, "MaxBalance");

        withdrawnBalances[uint256(WalletType.Marketing)] += MARKETING_MAX;
        _sendTokens(uint256(WalletType.Marketing), MARKETING_MAX);
    }

    function withdrawTeamTokens() external {
        require(block.timestamp >= listingDate + 365 days, "TooEarly");
        require(withdrawnBalances[uint256(WalletType.Team)] < TEAM_MAX, "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 365 days);
        uint256 month = (timeDiff / 30 days) + 1;   // Month number after listing + 1 year
        require(month <= 36, "Only36Months");
        uint256 monthTranche = TEAM_MAX / 36;
        uint256 tranchesWithdrawed = withdrawnBalances[uint256(WalletType.Team)] / monthTranche;

        require(month > tranchesWithdrawed, "MaxForThisMonth");
        uint256 numTranches = month - tranchesWithdrawed;
        uint256 availableAmount = monthTranche * numTranches;

        withdrawnBalances[uint256(WalletType.Team)] += availableAmount;
        _sendTokens(uint256(WalletType.Team), availableAmount);
    }

    function withdrawFoundationTokens() external {
        require(block.timestamp >= listingDate + 365 days, "TooEarly");
        require(withdrawnBalances[uint256(WalletType.Foundation)] < FOUNDATION_MAX, "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 365 days);
        uint256 month = (timeDiff / 30 days) + 1;   // Month number after listing + 1 year
        uint256 monthTranche = TEAM_MAX / 36;
        uint256 tranchesWithdrawed = withdrawnBalances[uint256(WalletType.Foundation)] / monthTranche;

        if (month > tranchesWithdrawed) {
            uint256 numTranches = month - tranchesWithdrawed;
            uint256 availableAmount = monthTranche * numTranches;

            withdrawnBalances[uint256(WalletType.Foundation)] += availableAmount;
            _sendTokens(uint256(WalletType.Foundation), availableAmount);
        }
    }

    function withdrawTreasuryTokens(uint256 _amount) external {
        require(withdrawnBalances[uint256(WalletType.Treasury)] + _amount < TREASURY_MAX, "MaxBalance");

        withdrawnBalances[uint256(WalletType.Treasury)] += _amount;
        _sendTokens(uint256(WalletType.Treasury), _amount);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(icomToken).balanceOf(address(this));
    }

    function _sendTokens(uint256 _type, uint256 _amount) internal {
        if (_type == uint256(WalletType.ICOHolders)) IERC20(icomToken).transfer(icoHoldersWallet, _amount);
        else if (_type == uint256(WalletType.Marketing)) IERC20(icomToken).transfer(marketingWallet, _amount);
        else if (_type == uint256(WalletType.Team)) IERC20(icomToken).transfer(teamWallet, _amount);
        else if (_type == uint256(WalletType.Staking)) IERC20(icomToken).transfer(stakingWallet, _amount);
        else if (_type == uint256(WalletType.Foundation)) IERC20(icomToken).transfer(foundationWallet, _amount);
        else if (_type == uint256(WalletType.Treasury)) IERC20(icomToken).transfer(treasuryWallet, _amount);

        emit onWithdrawToken(_type, _amount);
    }
}
