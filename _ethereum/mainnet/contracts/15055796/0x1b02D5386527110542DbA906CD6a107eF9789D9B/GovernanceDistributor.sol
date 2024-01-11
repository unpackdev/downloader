// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

import "./GovernanceToken.sol";

contract GovernanceDistributor is AccessControl {
    using SafeMath for uint256;

    mapping(address => uint256) public userGovTokenShareMapping;

    GovernanceToken public govToken;
    address public owner;
    
    uint256 public amountLeftToDistribute;    
    uint256 public bustadToGovDistributionRatio;
    uint256 public distributionThreshold;
    uint256 public distributionThresholdCounter;

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant CROWDSALE_ROLE = keccak256("CROWDSALE_ROLE");

    event BuyerAdded(address indexed purchaser, uint256 amount, uint256 govTokenShare);
    event TokenClaimed(address indexed user, uint256 amount);
    event RatioLowered(uint256 newRatio, uint256 newDistributionThresholdCounter);

    constructor(GovernanceToken _govToken, uint256 initialDistributionRatio) {
        bustadToGovDistributionRatio = initialDistributionRatio;        
        govToken = _govToken;
        distributionThreshold = 25_000_000 * 1e18;
        distributionThresholdCounter = 0;

        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addBuyer(address userAddress, uint256 bustadAmountBought)
        external
        onlyRole(CROWDSALE_ROLE)
    {
        if (amountLeftToDistribute == 0) return;

        uint256 govTokenShare = getGovTokenShare(bustadAmountBought);

        amountLeftToDistribute -= govTokenShare;
        userGovTokenShareMapping[userAddress] += govTokenShare;

        distributionThresholdCounter += bustadAmountBought;

        if (distributionThresholdCounter >= distributionThreshold) {
            bustadToGovDistributionRatio /= 2;
            distributionThresholdCounter -= distributionThreshold;

            emit RatioLowered(bustadToGovDistributionRatio, distributionThresholdCounter);
        }
        emit BuyerAdded(userAddress, bustadAmountBought, govTokenShare);
    }

    function claim() external {
        address receiver = msg.sender;
        uint256 govTokenShare = userGovTokenShareMapping[receiver];

        require(
            govToken.balanceOf(address(this)) > 0,
            "No more tokens to withdraw"
        );
        require(
            govTokenShare <= govToken.balanceOf(address(this)),
            "govTokenShare surpasses balance"
        );
        require(
            userGovTokenShareMapping[receiver] > 0,
            "User has no funds to withdraw"
        );

        userGovTokenShareMapping[receiver] -= govTokenShare;

        govToken.transfer(receiver, govTokenShare);

        emit TokenClaimed(receiver, govTokenShare);
    }

    function getGovTokenShareForUser(address _userAddress)
        external
        view
        returns (uint256)
    {
        return userGovTokenShareMapping[_userAddress];
    }

    function setAmountLeftToDistribute(uint256 _amountLeftToDistribute)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        require(
            govToken.balanceOf(address(this)) == _amountLeftToDistribute,
            "Amount not equal to balance"
        );
        amountLeftToDistribute = _amountLeftToDistribute;
    }

    function setDistributionThreshold(uint256 _distributionThreshold)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        distributionThreshold = _distributionThreshold;
    }

    function setDistributionRatio(uint256 _ratio)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        bustadToGovDistributionRatio = _ratio;
    }

    function setOwner(address _owner)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        owner = _owner;
    }

    function getGovTokenShare(uint256 bustadAmountBought)
        private
        view
        returns (uint256)
    {
        return
            (bustadAmountBought.mul(bustadToGovDistributionRatio)).div(1 ether);
    }

    function withdrawFund(uint256 _amount)
        external
        onlyRole(MAINTAINER_ROLE)        
    {
        require(
            govToken.balanceOf(address(this)) >= _amount,
            "Not enough funds to withdraw"
        );
        govToken.transfer(owner, _amount);
    }
}
