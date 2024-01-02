// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
abstract contract Memberships {
    
    // Periods
    struct Period {
        uint256 start;
        uint256 end;
        uint256 rewardPerSecond;
    }
    
    struct Member{
        uint256 toClaim;
        uint256 totalClaimed;
        }
    
    struct Membership{
        address member; //current owner
        uint256 calculatedPeriod;
        uint256 calculatedTime; //Stores block.number
        bool active;
    }
    mapping(uint256 => Period) private periods;
    mapping (uint256 => Membership) private membership;
    mapping (address => Member) private members;
    uint256 private currentPeriod;
    uint256 private currentTotalReward;
    uint256 private totalCertificates;
    bool private isActive; //is Rewards are active
    uint256[100] private __gap;

    // Events
    event newRewardPerSecond(uint256 indexed period, uint256 start, uint256 rewardsPerSecond);
    event newPeriod(uint256 indexed period, uint256 start, uint256 end, uint256 rewardsPerSecond);
    event stopRewards(uint256 indexed period, uint256 end);
    event log(uint256);
    function _calculateRewards(uint256 _membershipId) internal{
        uint256 rewardToClaim = 0;
        Membership memory _membership = membership[_membershipId];
        uint256 _currentPeriod = currentPeriod;
        // previous periods
            
        for (uint256 i = _membership.calculatedPeriod; i < _currentPeriod; i++){
            Period storage _period = periods[i];
            if(_period.start > _membership.calculatedTime){
                //Calculate middle periods
                rewardToClaim = rewardToClaim + _period.rewardPerSecond * (_period.end - _period.start);
            }else{
                // Calculate first period
                rewardToClaim = rewardToClaim + _period.rewardPerSecond * (_period.end - _membership.calculatedTime);

            }
        }
        // Calculate current period
        Period storage _periodc = periods[_currentPeriod];
        if(isActive){

            if(_periodc.start < _membership.calculatedTime){
                rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (block.number - _membership.calculatedTime);
            }else{
                rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (block.number - _periodc.start); 
            }
        }else{
            rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (_periodc.end - _periodc.start);
        }
        //Update claimable amount
        membership[_membershipId].calculatedTime = block.number;
        membership[_membershipId].calculatedPeriod = _currentPeriod;
        members[_membership.member].toClaim = members[_membership.member].toClaim + rewardToClaim;
        return;
    }
    function _viewRewards(uint256 _membershipId) internal view returns(uint256, uint256){
               uint256 rewardToClaim = 0;
        Membership memory _membership = membership[_membershipId];
        uint256 _currentPeriod = currentPeriod;
        // previous periods
            
        for (uint256 i = _membership.calculatedPeriod; i < _currentPeriod; i++){
            Period storage _period = periods[i];
            if(_period.start > _membership.calculatedTime){
                //Calculate middle periods
                rewardToClaim = rewardToClaim + _period.rewardPerSecond * (_period.end - _period.start);
            }else{
                // Calculate first period
                rewardToClaim = rewardToClaim + _period.rewardPerSecond * (_period.end - _membership.calculatedTime);

            }
        }
        // Calculate current period
        Period storage _periodc = periods[_currentPeriod];
        if(isActive){

            if(_periodc.start < _membership.calculatedTime){
                rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (block.number - _membership.calculatedTime);
            }else{
                rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (block.number - _periodc.start); 
            }
        }else{
            rewardToClaim = rewardToClaim + _periodc.rewardPerSecond * (_periodc.end - _periodc.start);
        }
        return (rewardToClaim, members[_membership.member].totalClaimed);
    }
    function calculateNewReward() internal returns(uint256){
        uint256 newReward = currentTotalReward / totalCertificates;
        require (newReward > 0, "New reward is 0");
        emit newRewardPerSecond(currentPeriod, block.number, newReward);
        return newReward;
    }
    function getMember(address _member) public view returns(uint256, uint256){
        return (members[_member].toClaim, members[_member].totalClaimed);
    }
    //Used for constructor only
    function _initPeriod() internal {
        periods[0].start = block.number; 
        periods[0].end = block.number;
        isActive = false;
    }

    function _activeRewards(uint256 _totalReward, uint256 _totalCertificates) internal {
        if(!isActive){
            isActive = true;
        }
        currentTotalReward = _totalReward;
        totalCertificates = _totalCertificates;
        ++currentPeriod;
        periods[currentPeriod] = Period(block.number, 0, calculateNewReward());
        emit newPeriod(currentPeriod, block.number, 0, periods[currentPeriod].rewardPerSecond);
        return;
    }
    
    function _stopRewards() internal {
        require (isActive, "Rewards are not active");
        periods[currentPeriod].end = block.number;
        isActive = false;
        emit stopRewards(currentPeriod, block.number);
        return;
    }
    function _claim(address _member) internal returns(uint256){
        uint256 toSend = members[_member].toClaim;
        members[_member].totalClaimed = members[_member].totalClaimed + members[_member].toClaim;
        members[_member].toClaim = 0;
        return toSend;
    }

    function _updatePeriod(address to, uint256 tokenId, address from) internal {

        //IF transfer
        if(from != address(0) && to != address(0)){
            _calculateRewards(tokenId);
            return;
        }
        //IF mint
        if(from == address(0)){
            ++totalCertificates;
            membership[tokenId] = Membership(to, currentPeriod + 1, block.number, true);
        }
        //IF burn
        if(to == address(0)){
            totalCertificates = totalCertificates - 1;
            _calculateRewards(tokenId);
            membership[tokenId].active = false;
        }

        if(isActive){
            periods[currentPeriod].end = block.number;
            ++currentPeriod;
            periods[currentPeriod] = Period(block.number, 0, calculateNewReward());
            emit newPeriod(currentPeriod, block.number, 0, periods[currentPeriod].rewardPerSecond);
        }
    }

    function getCurrentPeriod() public view returns(uint256){
        return currentPeriod;
    }
    function getPeriodDetails(uint256 _period) public view returns(uint256, uint256, uint256){
        return (periods[_period].start, periods[_period].end, periods[_period].rewardPerSecond);
    }
    function getMembershipDetails(uint256 _membershipId) public view returns(address, uint256, uint256, bool){
        return (membership[_membershipId].member, membership[_membershipId].calculatedPeriod, membership[_membershipId].calculatedTime, membership[_membershipId].active);
    }
}