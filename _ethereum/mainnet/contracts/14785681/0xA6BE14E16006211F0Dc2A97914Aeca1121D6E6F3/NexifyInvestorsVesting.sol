// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";

contract NexifyInvestorsVesting {

    uint256 constant private PRESEED_MAX = 100000000 * 10 ** 18;
    uint256 constant private PRIVATE_ROUND_1_MAX = 50000000 * 10 ** 18;
    uint256 constant private PRIVATE_ROUND_2_MAX = 100000000 * 10 ** 18;

    address immutable private nexifyToken;
    address private owner;

    uint256 private listingDate;

    mapping(address => uint256) preSeedAmounts;
    mapping(address => uint256) privateRound1Amounts;
    mapping(address => uint256) privateRound2Amounts;

    mapping(address => uint256) preSeedWithdrawnAmounts;
    mapping(address => uint256) privateRound1WithdrawnAmounts;
    mapping(address => uint256) privateRound2WithdrawnAmounts;

    event onWithdrawPreSeedTokens(address _investor, uint256 _amount);
    event onWithdrawPrivateRound1Tokens(address _investor, uint256 _amount);
    event onWithdrawPrivateRound2Tokens(address _investor, uint256 _amount);
    event onEmergencyWidthdraw(address _account, uint256 _amount);

    constructor(address _nexifyToken) {
        nexifyToken = _nexifyToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    modifier onlyPreeSeedWallet() {
        require(preSeedAmounts[msg.sender] > 0 || msg.sender == owner, "OnlyPreeSeed");
        _;
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listingDate = _listingDate;
    }

    function setPreSeedInvestments(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner {
        require(_wallets.length == _amounts.length, "BadLength");

        uint256 amount = 0;
        for (uint256 i=0; i<_wallets.length; i++) {
            preSeedAmounts[_wallets[i]] = _amounts[i];
            amount += _amounts[i];
        }

        require(amount <= PRESEED_MAX, "PreSeedMaxLimit");
    }

    function setPrivateRound1Investments(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner {
        require(_wallets.length == _amounts.length, "BadLength");

        uint256 amount = 0;
        for (uint256 i=0; i<_wallets.length; i++) {
            privateRound1Amounts[_wallets[i]] = _amounts[i];
            amount += _amounts[i];
        }

        require(amount <= PRIVATE_ROUND_1_MAX, "PreSeedMaxLimit");
    }

    function setPrivateRound2Investments(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner {
        require(_wallets.length == _amounts.length, "BadLength");

        uint256 amount = 0;
        for (uint256 i=0; i<_wallets.length; i++) {
            privateRound2Amounts[_wallets[i]] = _amounts[i];
            amount += _amounts[i];
        }

        require(amount <= PRIVATE_ROUND_2_MAX, "PreSeedMaxLimit");
    }

    function withdrawPreSeedWallets(address _account) external onlyPreeSeedWallet {
        require(block.timestamp > listingDate + 360 days, "TokensVested");
        require(preSeedWithdrawnAmounts[_account] < preSeedAmounts[_account], "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 360 days);
        uint256 month = (timeDiff / 30 days) + 1;
        uint256 totalAmount = preSeedAmounts[_account];
        uint256 monthTranche = totalAmount / 12;
        uint256 tranchesWithdrawed = preSeedWithdrawnAmounts[_account] / monthTranche;

        require(month > tranchesWithdrawed, "MaxForThisMonth");
        uint256 numTranches = month - tranchesWithdrawed;
        uint256 availableAmount = monthTranche * numTranches;

        if (preSeedWithdrawnAmounts[_account] + availableAmount > preSeedAmounts[_account])
            availableAmount = preSeedAmounts[_account] - preSeedWithdrawnAmounts[_account];

        preSeedWithdrawnAmounts[_account] += availableAmount;
        IERC20(nexifyToken).transfer(_account, availableAmount);

        emit onWithdrawPreSeedTokens(_account, availableAmount);
    }

    function withdrawPrivateRound1Wallets(address _account) external onlyPreeSeedWallet {
        require(block.timestamp > listingDate + 300 days, "TokensVested");
        require(privateRound1WithdrawnAmounts[_account] < privateRound1Amounts[_account], "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 300 days);
        uint256 month = (timeDiff / 30 days) + 1;
        uint256 totalAmount = privateRound1Amounts[_account];
        uint256 monthTranche = totalAmount / 12;
        uint256 tranchesWithdrawed = privateRound1WithdrawnAmounts[_account] / monthTranche;

        require(month > tranchesWithdrawed, "MaxForThisMonth");
        uint256 numTranches = month - tranchesWithdrawed;
        uint256 availableAmount = monthTranche * numTranches;

        if (privateRound1WithdrawnAmounts[_account] + availableAmount > privateRound1Amounts[_account])
            availableAmount = privateRound1Amounts[_account] - privateRound1WithdrawnAmounts[_account];

        privateRound1WithdrawnAmounts[_account] += availableAmount;
        IERC20(nexifyToken).transfer(_account, availableAmount);

        emit onWithdrawPrivateRound1Tokens(_account, availableAmount);
    }

    function withdrawPrivateRound2Wallets(address _account) external onlyPreeSeedWallet {
        require(block.timestamp > listingDate + 240 days, "TokensVested");
        require(privateRound1WithdrawnAmounts[_account] < privateRound1Amounts[_account], "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 240 days);
        uint256 month = (timeDiff / 30 days) + 1;
        uint256 totalAmount = privateRound2Amounts[_account];
        uint256 monthTranche = totalAmount / 12;
        uint256 tranchesWithdrawed = privateRound2WithdrawnAmounts[_account] / monthTranche;

        require(month > tranchesWithdrawed, "MaxForThisMonth");
        uint256 numTranches = month - tranchesWithdrawed;
        uint256 availableAmount = monthTranche * numTranches;

        if (privateRound2WithdrawnAmounts[_account] + availableAmount > privateRound2Amounts[_account])
            availableAmount = privateRound2Amounts[_account] - privateRound2WithdrawnAmounts[_account];

        privateRound2WithdrawnAmounts[_account] += availableAmount;
        IERC20(nexifyToken).transfer(_account, availableAmount);

        emit onWithdrawPrivateRound2Tokens(_account, availableAmount);
    }

    function emergencyWidthdraw(address _account, uint256 _amount) external onlyOwner {
        IERC20(nexifyToken).transfer(_account, _amount);

        emit onEmergencyWidthdraw(_account, _amount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "NoEmpty");
        
        owner = _newOwner;
    }
}