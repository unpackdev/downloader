// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./HawexToken.sol";

/** @title Tokensale Proxy */
contract TokenSaleProxy is Ownable, AdminRole {

    using SafeMath for *;
    uint public totalTokensToDistribute;
    uint public totalTokensWithdrawn;
    /** @notice Round name */
    string public name;

    struct Participation {
        uint256 totalParticipation;
        uint256 withdrawnAmount;
        uint[] amountPerPortion;
        uint[] withdrawnPortionAmount;
    }

    IERC20 public token;
    
    mapping(address => Participation) private addressToParticipation;
    /** @notice return true if address has participation in this round */ 
    mapping(address => bool) public hasParticipated;


    uint public numberOfPortions;
    /** @notice number of seconds between each distribution portion */
    uint public timeBetweenPortions;
    uint[] distributionDates;
    uint[] distributionPercents;

    event NewPercentages(uint[] portionPercents);
    event NewDates(uint[] distrDates);


    constructor (
        uint _numberOfPortions,
        uint _timeBetweenPortions,
        uint[] memory _distributionPercents,
        address _adminWallet,
        address _token,
        string memory _name
    )
    {
        require(_numberOfPortions == _distributionPercents.length, 
            "number of portions is not equal to number of percents");
        require(correctPercentages(_distributionPercents), "total percent has to be equal to 100%");
        
        distributionPercents = _distributionPercents;
        numberOfPortions = _numberOfPortions;
        timeBetweenPortions = _timeBetweenPortions;

        // Set the token address and round name
        token = IERC20(_token);
        name = _name;
        // Add the admin
        _addAdmin(_adminWallet);
    }

    /** 
        @notice add participation in the round for `participant`
        @dev only for TokenProvider
            The Contract has to have enough balance not used in distributing.
            After distribution start new charges not accepted 
        @param participant participant address
        @param participationAmount added participation amount
    */
    function registerParticipant(
        address participant,
        uint participationAmount
    )
    public onlyAdmin
    {
        require(totalTokensToDistribute.sub(totalTokensWithdrawn).add(participationAmount) <= token.balanceOf(address(this)),
            "Safeguarding existing token buyers. Not enough tokens."
        );
        
        if (distributionDates.length != 0){
            require(distributionDates[0] > block.timestamp, "sales have ended");
        }

        totalTokensToDistribute = totalTokensToDistribute.add(participationAmount);

        // Create new participation object
        Participation storage p = addressToParticipation[participant];
        
        p.totalParticipation = p.totalParticipation.add(participationAmount);

        if (!hasParticipated[participant]){
            p.withdrawnAmount = 0;

            uint[] memory amountPerPortion = new uint[](numberOfPortions);
            p.amountPerPortion = amountPerPortion;
            p.withdrawnPortionAmount = amountPerPortion;

            // Mark that user have participated
            hasParticipated[participant] = true;
        }

        uint portionAmount; uint percent;

        for (uint i = 0; i < p.amountPerPortion.length; i++){
            percent = distributionPercents[i];
            portionAmount = participationAmount.mul(percent).div(10000);
            p.amountPerPortion[i] = p.amountPerPortion[i].add(portionAmount);
        }
    }

    /**
        @notice start distribution process and lock new charges
        @dev only for Owner
     */
    function startDistribution() public onlyOwner {
        require(distributionDates.length == 0, "(startDistribution) distribution dates already set");

        uint[] memory _distributionDates = new uint[](numberOfPortions);
        for (uint i = 0; i < numberOfPortions; i++){
            
            _distributionDates[i] = block.timestamp.add(timeBetweenPortions.mul(i));
        }

        distributionDates = _distributionDates;
    }

    /**
        @notice transfer unlocked reward to participant; user always withdraws everything available
     */
    function withdraw() external {
        require(hasParticipated[msg.sender] == true, "(withdraw) the address is not a participant.");
        require(distributionDates.length != 0, "(withdraw) distribution dates are not set");
        _withdraw();
    }

    function _withdraw() private {
        address user = msg.sender;
        Participation storage p = addressToParticipation[user];

        uint remainLocked = p.totalParticipation.sub(p.withdrawnAmount);
        require(remainLocked > 0, "everything unlocked");

        uint256 toWithdraw = 0;
        
        uint portionRemaining = 0;
        for(uint i = 0; i < p.amountPerPortion.length; i++) {
            if(isPortionUnlocked(i)) {
                portionRemaining = p.amountPerPortion[i].sub(p.withdrawnPortionAmount[i]);
                if(portionRemaining > 0){
                    toWithdraw = toWithdraw.add(portionRemaining);
                    p.withdrawnPortionAmount[i] = p.withdrawnPortionAmount[i].add(portionRemaining);
                }
            }
            else {
                break;
            }
        }

        require(toWithdraw > 0, "nothing to withdraw");

        if (isPortionUnlocked(distributionDates.length-1)) {
            toWithdraw += p.totalParticipation - p.withdrawnAmount - toWithdraw;
        }

        require(p.totalParticipation >= p.withdrawnAmount.add(toWithdraw), "(withdraw) impossible to withdraw more than vested");
        p.withdrawnAmount = p.withdrawnAmount.add(toWithdraw);
        // Account total tokens withdrawn.
        require(totalTokensToDistribute >= totalTokensWithdrawn.add(toWithdraw), "(withdraw) withdraw amount more than distribution");
        totalTokensWithdrawn = totalTokensWithdrawn.add(toWithdraw);
        // Transfer all tokens to user
        token.transfer(user, toWithdraw);
    }

    /**
        @notice transfer not used in distributing balance to contract owner
        @dev only for Owner. Available only after start of distribution
     */
    function withdrawUndistributedTokens() external onlyOwner {
        if (distributionDates.length != 0) {
            require(block.timestamp > distributionDates[0], 
                "(withdrawUndistributedTokens) only after start of distribution");
        }

        uint unDistributedAmount = token.balanceOf(address(this)).sub(totalTokensToDistribute.sub(totalTokensWithdrawn));
        require(unDistributedAmount > 0, "(withdrawUndistributedTokens) zero to withdraw");
        token.transfer(owner(), unDistributedAmount);
    }

    /**
        @notice set new portion percentages. Doesn't affect old participations
        @dev emit NewPercentages event. Sum should be equal 10000 (100%). only for Owner
        @param _portionPercents array of percentages
     */
    function updatePercentages(uint256[] calldata _portionPercents) public onlyOwner {
        require(_portionPercents.length == numberOfPortions, 
            "(updatePercentages) number of percents is not equal to actual number of portions");
        require(correctPercentages(_portionPercents), "(updatePercentages) total percent has to be equal to 100%");
        distributionPercents = _portionPercents;

        emit NewPercentages(_portionPercents);
    }

    /**
        @notice update one distribution date
        @dev emit NewDates event. only for Admin
        @param index index of date in global array
        @param newDate updated date in unix time
     */
    function updateOneDistrDate(uint index, uint newDate) public onlyAdmin {
        distributionDates[index] = newDate;

        emit NewDates(distributionDates);
    }

    /**
        @notice update all distribution dates
        @dev emit NewDates event. only for Admin
        @param newDates updated distributionDates array
     */
    function updateAllDistrDates(uint[] memory newDates) public onlyAdmin {
        require(distributionPercents.length == newDates.length, "(updateAllDistrDates) the number of Percentages and Dates do not match");
        distributionDates = newDates;

        emit NewDates(distributionDates);
    }

    /**
        @notice update timeBetweenPortions
        @dev only for Admin
        @param _time updated timeBetweenPortions
     */
    function updateTimeBetweenPortions(uint _time) public onlyAdmin {
        timeBetweenPortions = _time;
    }


    function correctPercentages(uint[] memory portionsPercentages) private pure returns(bool) {
        uint totalPercent = 0;
        for(uint i = 0 ; i < portionsPercentages.length; i++) {
            totalPercent = totalPercent.add(portionsPercentages[i]);
        }

        return totalPercent == 10000;
    }

    /**
        @notice return true if portion distribution date with `portionId` has arrived
        @param portionId id of distributing portion
     */
    function isPortionUnlocked(uint portionId) public view returns (bool) {
        return block.timestamp >= distributionDates[portionId];
    }

    /**
        @notice return participation info array by `account` address
        @param account participant address
        @return total participation
        @return withdrawn amount
        @return array amounts per portion
        @return array of them withdrawn
     */
    function getParticipation(address account) 
    external
    view
    returns (uint256, uint256, uint[] memory, uint[] memory)
    {
        Participation memory p = addressToParticipation[account];
        return (
            p.totalParticipation,
            p.withdrawnAmount,
            p.amountPerPortion,
            p.withdrawnPortionAmount
        );
    }

    /**
        @notice return all distribution dates in UNIX time
     */
    function getDistributionDates() external view returns (uint256[] memory) {
        return distributionDates;
    }

    /**
        @notice return all distribution percents
     */
    function getDistributionPercents() external view returns (uint256[] memory) {
        return distributionPercents;
    }

    /**
        @notice return unlocked amount of tokens which `user` can withdraw
        @param user participant address
     */
    function availableToClaim(address user) public view returns(uint) {
        Participation memory p = addressToParticipation[user];
        uint256 toWithdraw = 0;

        for(uint i = 0; i < distributionDates.length; i++) {
            if(isPortionUnlocked(i) == true) {
                // Add this portion to withdraw amount
                toWithdraw = toWithdraw.add(p.amountPerPortion[i].sub(p.withdrawnPortionAmount[i]));
            }
            else {
                break;
            }
        }

        return toWithdraw;
    }

    /**
        @notice add Admin role to `account`
        @dev only for Owner
        @param account role recipient
     */
    function addAdmin(address account) public onlyOwner {
        require(!isAdmin(account), "[Admin Role]: account already has admin role");
        _addAdmin(account);
    }

    /**
        @notice remove Admin role from `account`
        @dev only for Owner
        @param account address for role revocation
     */
    function removeAdmin(address account) public onlyOwner {
        require(isAdmin(account), "[Admin Role]: account has not admin role");
        _removeAdmin(account);
    }
}