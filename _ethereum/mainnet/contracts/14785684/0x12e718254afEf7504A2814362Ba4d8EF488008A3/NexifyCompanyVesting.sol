// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";

contract NexifyCompanyVesting {

    uint256 constant private TEAM_MAX = 200000000 * 10 ** 18;
    uint256 constant private COMPANY_MAX = 550000000 * 10 ** 18;

    address private companyWallet;
    address private nexifyToken;
    address private owner;

    uint256 private listingDate;

    mapping(address => uint256) teamAmount;
    mapping(address => uint256) teamWithdrawnAmounts;

    uint256 private companyWithdrawn;

    event onWithdrawTeamTokens(address _team, uint256 _amount);
    event onWithdrawCompanyTokens(address _company, uint256 _amount);
    event onEmergencyWidthdraw(address _acccount, uint256 _amount);

    constructor(address _nexifyToken, address _companyWallet) {
        nexifyToken = _nexifyToken;
        companyWallet = _companyWallet;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    modifier onlyTeam() {
        require(teamAmount[msg.sender] > 0 || msg.sender == owner, "OnlyTeam");
        _;
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listingDate = _listingDate;
    }

    function setTeamWallets(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner {
        require(_wallets.length == _amounts.length, "BadLength");

        uint256 amount = 0;
        for (uint256 i=0; i<_wallets.length; i++) {
            teamAmount[_wallets[i]] = _amounts[i];
            amount += _amounts[i];
        }

        require(amount <= TEAM_MAX, "TeamMaxLimit");
    }

    function withdrawTeamWallets(address _account) external onlyTeam {
        require(block.timestamp > listingDate + 540 days, "TokensVested");
        require(teamWithdrawnAmounts[_account] < teamAmount[_account], "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 540 days);
        uint256 month = (timeDiff / 30 days) + 1;
        uint256 totalAmount = teamAmount[_account];
        uint256 monthTranche = totalAmount / 12;
        uint256 tranchesWithdrawed = teamWithdrawnAmounts[_account] / monthTranche;

        require(month > tranchesWithdrawed, "MaxForThisMonth");
        uint256 numTranches = month - tranchesWithdrawed;
        uint256 availableAmount = monthTranche * numTranches;

        if (teamWithdrawnAmounts[_account] + availableAmount > teamAmount[_account])
            availableAmount = teamAmount[_account] - teamWithdrawnAmounts[_account];

        teamWithdrawnAmounts[_account] += availableAmount;
        IERC20(nexifyToken).transfer(_account, availableAmount);

        emit onWithdrawTeamTokens(_account, availableAmount);
    }

    function withdrawCompanyTokens(uint256 _amount) external onlyOwner {
        require(companyWithdrawn <= COMPANY_MAX, "CompanyMax");

        companyWithdrawn += _amount;
        IERC20(nexifyToken).transfer(companyWallet, _amount);

        emit onWithdrawCompanyTokens(msg.sender, _amount);
    }

    function emergencyWidthdraw(uint256 _amount) external onlyOwner {
        IERC20(nexifyToken).transfer(owner, _amount);

        emit onEmergencyWidthdraw(owner, _amount);
    }

    function changeCompanyWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "NoEmpty");
        
        companyWallet = _newWallet;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "NoEmpty");
        
        owner = _newOwner;
    }
}