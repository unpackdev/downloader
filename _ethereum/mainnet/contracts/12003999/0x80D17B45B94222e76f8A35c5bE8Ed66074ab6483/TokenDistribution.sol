pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBurnable.sol";
import "./ObortechToken.sol";


contract TokenDistribution is Ownable {
    using SafeMath for uint256;

    address private networkAdminFeeAddress;
    address private marketingPoolAddress;
    address private userGrowthPoolAddress;
    address private nonProfitActivitiesAddress;

    uint256 private networkAdminFeeAmount;
    uint256 private marketingPoolAmount;
    uint256 private userGrowthPoolAmount;
    uint256 private nonProfitActivitiesAmount;

    IERC20 private token;

    function distributeTokens(uint256 amount) external {
        token.transferFrom(_msgSender(), address(this), amount);
        uint256 _amount = amount;
        networkAdminFeeAmount = networkAdminFeeAmount.add(_amount.mul(7).div(10)); // 70%
        marketingPoolAmount = marketingPoolAmount.add(_amount.div(10)); // 10%
        userGrowthPoolAmount = userGrowthPoolAmount.add(_amount.div(10)); // 10%
        nonProfitActivitiesAmount = nonProfitActivitiesAmount.add(_amount.div(20)); // 5%
        IBurnable(address(token)).burn(amount.div(20)); // burn 5%  
    }

    function takeNetworkAdminFeeTokens() external {
        require(_msgSender() == networkAdminFeeAddress,'invalid address');
        uint256 _networkAdminFeeAmount = networkAdminFeeAmount;
        networkAdminFeeAmount = 0;
        token.transfer(networkAdminFeeAddress, _networkAdminFeeAmount);
    }

    function takeMarketingPoolTokens() external {
        require(_msgSender() == marketingPoolAddress,'invalid address');
        uint256 _marketingPoolAmount = marketingPoolAmount;
        marketingPoolAmount = 0;
        token.transfer(marketingPoolAddress, _marketingPoolAmount);
    }

      function takeUserGrowthPoolTokens() external {
        require(_msgSender() == userGrowthPoolAddress,'invalid address');
        uint256 _userGrowthPoolAmount = userGrowthPoolAmount;
        userGrowthPoolAmount = 0;
        token.transfer(userGrowthPoolAddress, _userGrowthPoolAmount);
    }

      function takeNonProfitActivitiesTokens() external {
        require(_msgSender() == nonProfitActivitiesAddress,'invalid address');
        uint256 _nonProfitActivitiesAmount = nonProfitActivitiesAmount;
        nonProfitActivitiesAmount = 0;
        token.transfer(nonProfitActivitiesAddress, _nonProfitActivitiesAmount);
    }


    // Get amounts functions
    function getNetworkAdminFeeTokens() external view returns(uint256) {
        return networkAdminFeeAmount;
    }

    function getMarketingPoolTokens() external view returns(uint256) {
        return marketingPoolAmount;
    }

    function getUserGrowthPoolTokens() external view returns(uint256) {
        return userGrowthPoolAmount;
    }

    function getNonProfitActivitiesTokens() external view returns(uint256) {
        return nonProfitActivitiesAmount;
    }


    // Get addresses functions
    function getNetworkAdminFeeAddress() external view returns(address) {
        return networkAdminFeeAddress;
    }

    function getMarketingPoolAddress() external view returns(address) {
       return marketingPoolAddress;
    }

    function getUserGrowthPoolAddress() external view returns(address) {
        return userGrowthPoolAddress;
    }

     function getNonProfitActivitiesAddress() external view returns(address) {
        return nonProfitActivitiesAddress;
    }


    function configure (
        address _token,
        address _networkAdminFeeAddress,
        address _marketingPoolAddress,
        address _userGrowthPoolAddress,
        address _nonProfitActivitiesAddress
    ) onlyOwner external {
        token = IERC20(_token);
        networkAdminFeeAddress = _networkAdminFeeAddress;
        marketingPoolAddress = _marketingPoolAddress;
        userGrowthPoolAddress = _userGrowthPoolAddress;
        nonProfitActivitiesAddress = _nonProfitActivitiesAddress;
    }

    // Set addresses functions
    function setNetworkAdminFeeAddress(address addr) external onlyOwner {
        require(addr != address(0), 'incorrect address');
        networkAdminFeeAddress = addr;
    }

    function setMarketingPoolAddress(address addr) external onlyOwner {
        require(addr != address(0), 'incorrect address');
        marketingPoolAddress = addr;
    }

    function setUserGrowthPoolAddress(address addr) external onlyOwner {
        require(addr != address(0), 'incorrect address');
        userGrowthPoolAddress = addr;
    }

    function setNonProfitActivitiesAddress(address addr) external onlyOwner {
        require(addr != address(0), 'incorrect address');
        nonProfitActivitiesAddress = addr;
    }

}
