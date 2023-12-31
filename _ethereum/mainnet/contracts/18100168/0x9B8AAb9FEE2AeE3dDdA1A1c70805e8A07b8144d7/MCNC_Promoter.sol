// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MCNC_Promoter {
    IERC20 public mainToken;
    address public mainTokenAddress = 0x3Aa9EBdCF5aff192F1759F35CFD6aFe0b898FB6F;
    address public rescueAddress = 0x718914A81855B7694275c5Fc452f39613CfA7990;

    uint256 public startTime;

    address public owner;
    address public coreTeam = 0xcb7e887083193cFcB8978FC6B4B029e772978cAb;
    address public coreTeam2 = 0x25B96CD237C419CAb347293f78bb230e6e4b1680;
    address public techTeam = 0x0bc059ac33c6Af176de9Dde3F93CEEb127E36cDd;
    address public insurance = 0x70E9737043f38F1c2fc7fF3c4E6c0F4c33A28dDe;
    address public marketing = 0xD408f2e14619A3A5adF803ef4d2ba480F0B9A294;
    address public marketingBackup = 0x86BE6bC393E884DB8f4c2187909B088E06Ec34BB;

    uint256 public lastCoreTeamRewardTime;
    uint256 public lastCoreTeam2RewardTime;
    uint256 public lastTechTeamRewardTime;
    uint256 public lastInsuranceRewardTime;
    uint256 public lastMarketingRewardTime;
    uint256 public lastMarketingBackupRewardTime;

    uint256 constant public ONE_MONTH = 30 days;

    constructor(IERC20 _mainToken) {
        require(address(_mainToken) == mainTokenAddress, "Provided token is not the expected token.");

        mainToken = _mainToken;
        owner = msg.sender;
        startTime = 1685984400; // Fixed UNIX timestamp

        lastCoreTeamRewardTime = startTime;
        lastCoreTeam2RewardTime = startTime;
        lastTechTeamRewardTime = startTime;
        lastInsuranceRewardTime = startTime;
        lastMarketingRewardTime = startTime;
        lastMarketingBackupRewardTime = startTime;
    }

    function release() public {
        uint256 currentTime = block.timestamp;
        uint256 periodsElapsed;
        
        // Core Team
        periodsElapsed = (currentTime - lastCoreTeamRewardTime) / (3 * ONE_MONTH);
        if (periodsElapsed > 0) {
            lastCoreTeamRewardTime += periodsElapsed * 3 * ONE_MONTH;
            releaseTokens(coreTeam, 250000 * 10**18 * periodsElapsed);
        }

        // Core Team 2
        periodsElapsed = (currentTime - lastCoreTeam2RewardTime) / (3 * ONE_MONTH);
        if (periodsElapsed > 0) {
            lastCoreTeam2RewardTime += periodsElapsed * 3 * ONE_MONTH;
            releaseTokens(coreTeam2, 250000 * 10**18 * periodsElapsed);
        }

        // Tech Team
        periodsElapsed = (currentTime - lastTechTeamRewardTime) / ONE_MONTH;
        if (periodsElapsed > 0) {
            lastTechTeamRewardTime += periodsElapsed * ONE_MONTH;
            releaseTokens(techTeam, 150000 * 10**18 * periodsElapsed);
        }

        // Insurance
        periodsElapsed = (currentTime - lastInsuranceRewardTime) / (60 * ONE_MONTH);
        if (periodsElapsed > 0) {
            lastInsuranceRewardTime += periodsElapsed * 60 * ONE_MONTH;
            releaseTokens(insurance, 1000000 * 10**18 * periodsElapsed);
        }

        // Marketing
        periodsElapsed = (currentTime - lastMarketingRewardTime) / (12 * ONE_MONTH);
        if (periodsElapsed > 0) {
            lastMarketingRewardTime += periodsElapsed * 12 * ONE_MONTH;
            releaseTokens(marketing, 4500000 * 10**18 * periodsElapsed);
        }

        // Marketing Backup
        periodsElapsed = (currentTime - lastMarketingBackupRewardTime) / (24 * ONE_MONTH);
        if (periodsElapsed > 0) {
            lastMarketingBackupRewardTime += periodsElapsed * 24 * ONE_MONTH;
            releaseTokens(marketingBackup, 1000000 * 10**18 * periodsElapsed);
        }
    }

    function releaseTokens(address recipient, uint256 amount) private {
        bool success = mainToken.transfer(recipient, amount);
        require(success, "MCNC transfer failed.");
    }

    function rescueTokens(IERC20 token) public {
        require(address(token) != mainTokenAddress, "Cannot rescue the main token.");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue.");
        bool success = token.transfer(rescueAddress, balance);
        require(success, "Token rescue failed.");
    }
}