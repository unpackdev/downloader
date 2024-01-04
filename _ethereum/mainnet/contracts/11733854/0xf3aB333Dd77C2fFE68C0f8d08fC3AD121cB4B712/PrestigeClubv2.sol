pragma solidity 0.6.8;

import "./PrestigeClubCalculations.sol";
import "./SafeMath112.sol";
import "./IERC20.sol";
import "./Ownable.sol";

// SPDX-License-Identifier: MIT

//Restrictions:
//only 2^32 Users
//Maximum of (2^104 / 10^18 Ether) investment. Theoretically 20 Trl Ether, practically 100000000000 Ether compiles
contract PrestigeClub is Ownable() {

    using SafeMath112 for uint112;

    //User Object which stores all data associated with a specific address
    struct User {
        uint112 deposit; //amount a User has paid in. Note: Deposits can not removed, since withdrawals are only possible on payout
        uint112 payout; //Generated revenue
        uint32 position; //The position (a incrementing int value). Used for calculation of the streamline
        uint8 qualifiedPools;  //Number of Pools and DownlineBonuses, which the User has qualified for respectively
        uint8 downlineBonus;
        address referer;
        address[] referrals;

        uint112 directSum;   //Sum of deposits of all direct referrals
        uint40 lastPayout;  //Timestamp of the last calculated Payout

        uint40 lastPayedOut; //Point in time, when the last Payout was made

        uint112[5] downlineVolumes;  //Used for downline bonus calculation, correspondings to logical mapping  downlineBonusStage (+ 0) => sum of deposits of users directly or indirectly referred in given downlineBonusStage
    }
    
    event NewDeposit(address indexed addr, uint112 amount);
    event PoolReached(address indexed addr, uint8 pool);
    // event DownlineBonusStageReached(address indexed adr, uint8 stage);
    // event Referral(address indexed addr, address indexed referral);
    
    event Payout(address indexed addr, uint112 interest, uint112 direct, uint112 pool, uint112 downline, uint40 dayz); 
    
    event Withdraw(address indexed addr, uint112 amount);
    
    mapping (address => User) public users;
    //userList is basically a mapping position(int) => address
    address[] public userList;

    uint32 public lastPosition; //= 0
    
    uint128 public depositSum; //= 0 //Pos 4
    
    Pool[8] public pools;
    
    struct Pool {
        uint112 minOwnInvestment;
        uint8 minDirects;
        uint112 minSumDirects;
        uint8 payoutQuote; //ppm
        uint32 numUsers;
    }

    //Poolstates are importing for calculating the pool payout for every seperate day.
    //Since the number of Deposits and Users in every pool change every day, but payouts are only calculated if they need to be calculated, their history has to be stored
    PoolState[] public states;

    struct PoolState {
        uint128 totalDeposits;
        uint32 totalUsers;
        uint32[8] numUsers;
    }

    //Downline bonus is a bonus, which users get when they reach a certain pool. The Bonus is calculated based on the sum of the deposits of all Users delow them in the structure
    DownlineBonusStage[4] downlineBonuses;
    
    struct DownlineBonusStage {
        uint32 minPool;
        uint64 payoutQuote; //ppm
    }
    
    uint40 public pool_last_draw;

    IERC20 peth;
    
    constructor(address erc20Adr) public {
 
        uint40 timestamp = uint40(block.timestamp);
        pool_last_draw = timestamp - (timestamp % payout_interval) - (2 * payout_interval);

        peth = IERC20(erc20Adr);

        //Definition of the Pools and DownlineBonuses with their respective conditions and percentages. 
        //Note, values are not final, adapted for testing purposes

        //Prod values
        pools[0] = Pool(3 ether, 1, 3 ether, 130, 0);
        pools[1] = Pool(15 ether, 3, 5 ether, 130, 0);
        pools[2] = Pool(15 ether, 4, 44 ether, 130, 0);
        pools[3] = Pool(30 ether, 10, 105 ether, 130, 0);
        pools[4] = Pool(45 ether, 15, 280 ether, 130, 0);
        pools[5] = Pool(60 ether, 20, 530 ether, 130, 0);
        pools[6] = Pool(150 ether, 20, 1470 ether, 80, 0);
        pools[7] = Pool(300 ether, 20, 2950 ether, 80, 0);

        downlineBonuses[0] = DownlineBonusStage(3, 50);
        downlineBonuses[1] = DownlineBonusStage(4, 100);
        downlineBonuses[2] = DownlineBonusStage(5, 160);
        downlineBonuses[3] = DownlineBonusStage(6, 210);
        
        //Testing Pools
        // pools[0] = Pool(1000 wei, 1, 1000 wei, 130, 0); 
        // pools[1] = Pool(1000 wei, 1, 1000 wei, 130, 0);
        // pools[2] = Pool(1000 wei, 1, 10000 wei, 130, 0);
        // pools[3] = Pool(2 ether, 1, 10000 wei, 130, 0);
        // pools[4] = Pool(2 ether, 1, 10000 wei, 130, 0);
        // pools[5] = Pool(2 ether, 1, 10000 wei, 130, 0);
        // pools[6] = Pool(2 ether, 1, 10000 wei, 130, 0);
        // pools[7] = Pool(5 ether, 5, 10 ether, 80, 0);
        
        // //Test Values
        // downlineBonuses[0] = DownlineBonusStage(3, 100);
        // downlineBonuses[1] = DownlineBonusStage(4, 160);
        // downlineBonuses[2] = DownlineBonusStage(5, 210);
        // downlineBonuses[3] = DownlineBonusStage(6, 260);

        userList.push(address(0));
        
    }
    
    uint112 internal minDeposit = 0.2 ether; 
    
    // uint40 constant internal payout_interval = 1 days;
    uint40 constant internal payout_interval = 10 minutes;
    
    //Investment function for new deposits
    function recieve(uint112 amount) public {
        User storage user = users[msg.sender];
        require((user.deposit * 20 / 19) >= minDeposit || amount >= minDeposit, "Minimum deposit value not reached");
        
        address sender = msg.sender;

        uint112 value = amount.mul(19).div(20);

        //Transfer peth
        peth.transferFrom(sender, address(this), amount);

        bool userExists = user.position != 0;
        
        //Trigger calculation of next Pool State, if 1 day has passed
        triggerCalculation();

        // Create a position for new accounts
        if(!userExists){
            lastPosition++;
            user.position = lastPosition;
            user.lastPayout = (pool_last_draw + 1);
            userList.push(sender);
        }

        address referer = user.referer; //can put outside because referer is always set since setReferral() gets called before recieve() in recieve(address)

        if(referer != address(0)){
            updateUpline(sender, referer, value);
        }

        //Update Payouts
        if(userExists){
            updatePayout(sender);
        }

        user.deposit = user.deposit.add(value);
        
        //Transfer fee
        peth.transfer(owner(), (amount - value));
        
        emit NewDeposit(sender, value);
        
        updateUserPool(sender);
        updateDownlineBonusStage(sender);
        if(referer != address(0)){
            users[referer].directSum = users[referer].directSum.add(value);

            updateUserPool(referer);
            updateDownlineBonusStage(referer);
        }
        
        depositSum = depositSum + value; //Won´t do an overflow since value is uint112 and depositSum 128

    }
    
    
    //New deposits with referral address
    function recieve(uint112 amount, address referer) public {
        
        _setReferral(referer);
        recieve(amount);
        
    }

    //Updating the payouts and stats for the direct and every User which indirectly referred User reciever
    //adr = Address of the first referer , addition = new deposit value
    function updateUpline(address reciever, address adr, uint112 addition) private {
        
        address current = adr;
        uint8 bonusStage = users[reciever].downlineBonus;
        
        uint8 downlineLimitCounter = 30;
        
        while(current != address(0) && downlineLimitCounter > 0){

            updatePayout(current);

            users[current].downlineVolumes[bonusStage] = users[current].downlineVolumes[bonusStage].add(addition);
            uint8 currentBonus = users[current].downlineBonus;
            if(currentBonus > bonusStage){
                bonusStage = currentBonus;
            }

            current = users[current].referer;
            downlineLimitCounter--;
        }
        
    }
    
    //Updates the payout amount for given user
    function updatePayout(address adr) private {
        
        uint40 dayz = (uint40(block.timestamp) - users[adr].lastPayout) / (payout_interval);
        if(dayz >= 1){
            
            // Calculate Base Payouts

            // Interest Payout
            uint112 deposit = users[adr].deposit;
            uint8 quote;
            if(deposit >= 30 ether){
                quote = 15;
            }else{
                quote = 10;
            }
            
            uint112 interestPayout = deposit.mul(quote) / 10000;

            uint112 poolpayout = getPoolPayout(adr, dayz);

            uint112 directsPayout = getDirectsPayout(adr);

            uint112 downlineBonusAmount = getDownlinePayout(adr);
            
            uint112 sum = interestPayout.add(directsPayout).add(downlineBonusAmount); 
            sum = (sum.mul(dayz)).add(poolpayout);
            
            users[adr].payout = users[adr].payout.add(sum);
            users[adr].lastPayout += (payout_interval * dayz);
            
            emit Payout(adr, interestPayout, directsPayout, poolpayout, downlineBonusAmount, dayz);

        }
    }
    
    function getPoolPayout(address adr, uint40 dayz) public view returns (uint112){
        return PrestigeClubCalculations.getPoolPayout(users[adr], dayz, pools, states);
    }

    function getDownlinePayout(address adr) public view returns (uint112){
        return PrestigeClubCalculations.getDownlinePayout(users[adr], downlineBonuses);
    }

    function getDirectsPayout(address adr) public view returns (uint112) {
        
        // Calculate Directs Payouts
       return users[adr].directSum.mul(5) / 10000;
        
    }
    
    function triggerCalculation() public { 
        if(block.timestamp > pool_last_draw + payout_interval){
            pushPoolState();
        }
    }

    //Gets called every 24 hours to push new PoolState
    function pushPoolState() private {
        uint32[8] memory temp;
        for(uint8 i = 0 ; i < 8 ; i++){
            temp[i] = pools[i].numUsers;
        }
        states.push(PoolState(depositSum, lastPosition, temp));
        pool_last_draw += payout_interval;
    }

    //updateUserPool and updateDownlineBonusStage check if the requirements for the next pool or stage are reached, and if so, increment the counter in his User struct 
    function updateUserPool(address adr) private {
        
        if(users[adr].qualifiedPools < pools.length){
            
            uint8 poolnum = users[adr].qualifiedPools;
            
            uint112 sumDirects = users[adr].directSum;
            
            //Check if requirements for next pool are met
            if(users[adr].deposit >= pools[poolnum].minOwnInvestment && users[adr].referrals.length >= pools[poolnum].minDirects && sumDirects >= pools[poolnum].minSumDirects){
                users[adr].qualifiedPools = poolnum + 1;
                pools[poolnum].numUsers++;
                
                emit PoolReached(adr, poolnum + 1);
                
                updateUserPool(adr);
            }
            
        }
        
    }
    
    function updateDownlineBonusStage(address adr) private {

        User storage user = users[adr];
        uint8 bonusstage = user.downlineBonus;

        if(bonusstage < downlineBonuses.length){

            //Check if requirements for next stage are met
            if(user.qualifiedPools >= downlineBonuses[bonusstage].minPool){
                user.downlineBonus += 1;
                
                //Update data in upline
                uint112 value = user.deposit;  //Value without current stage, since that must not be subtracted

                for(uint8 i = 0 ; i <= bonusstage ; i++){
                    value = value.add(user.downlineVolumes[i]);
                }

                // uint8 previousBonusStage = bonusstage;
                uint8 currentBonusStage = bonusstage + 1;
                uint8 lastBonusStage = bonusstage;

                address current = user.referer;
                while(current != address(0)){

                    User storage currentUser = users[current];
                    currentUser.downlineVolumes[lastBonusStage] = currentUser.downlineVolumes[lastBonusStage].sub(value);
                    currentUser.downlineVolumes[currentBonusStage] = currentUser.downlineVolumes[currentBonusStage].add(value);

                    uint8 currentDB = currentUser.downlineBonus;
                    if(currentDB > currentBonusStage){
                        currentBonusStage = currentDB;
                    }
                    if(currentDB > lastBonusStage){
                        lastBonusStage = currentDB;
                    }

                    if(lastBonusStage == currentBonusStage){
                        break;
                    }

                    current = users[current].referer;
                }
                
                updateDownlineBonusStage(adr);
            }
        }
        
    }
    
    //Endpoint to withdraw payouts
    function withdraw(uint112 amount) public {

        User storage user = users[msg.sender];
        require(user.lastPayedOut + 12 hours < block.timestamp, "10");
        require(amount < user.deposit.mul(3), "11");

        triggerCalculation();
        updatePayout(msg.sender);

        require(user.payout >= amount, "Not enough payout available");
        
        uint112 transfer = amount * 19 / 20;
        
        user.payout -= amount;

        user.lastPayedOut = uint40(block.timestamp);

        //Mint if necessary
        if(peth.balanceOf(address(this)) < amount){
            peth.mint(uint256(amount));
        }
        
        peth.transfer(msg.sender, transfer);
        
        peth.transfer(owner(), (amount - transfer));
        
        emit Withdraw(msg.sender, amount);
        
    }

    function _setReferral(address referer) private {
        
        User storage user = users[msg.sender];
        if(user.referer == referer){
            return;
        }
        
        if(user.position != 0 && user.position < users[referer].position) {
            return;
        }
        
        require(user.referer == address(0), "Referer already set");
        require(users[referer].position > 0, "Referer doesnt exist");
        require(msg.sender != referer, "Referer is self");
        
        users[referer].referrals.push(msg.sender);
        user.referer = referer;

        if(user.deposit > 0){
            users[referer].directSum = users[referer].directSum.add(user.deposit);
        }
        
    }
    
    function setLimits(uint112 _minDeposit) public onlyOwner {
        minDeposit = _minDeposit;
    }

    //Data Import Logic
    function reCalculateImported(uint32 _lastPosition, uint112 _depositSum) public onlyOwner {
        // uint40 time = pool_last_draw;
        // for(uint64 i = from ; i < to + 1 ; i++){
            // address adr = userList[i];
            // users[adr].payout = 0;
            // users[adr].lastPayout = time;
            // updatePayout(adr);
        // }
        lastPosition = _lastPosition;
        depositSum = _depositSum;
    }
    
    function _import(address[] memory _sender, uint112[] memory deposit, address[] memory _referer, uint32 startposition, 
        uint8[] memory downlineBonus, uint112[5][] memory volumes) public onlyOwner {

        require(userList.length == startposition, "Positions wrong");

        uint40 time = pool_last_draw + (2 * payout_interval);

        for(uint32 i = 0 ; i < _sender.length ; i++){

            address sender = _sender[i];
            address referer = _referer[i];
            User storage user = users[sender];

            require(user.deposit == 0, "Account exists already");

            // Create a position for new accounts
            user.position = startposition + i;
            user.lastPayout = time;//pool_last_draw;
            userList.push(sender);

            if(referer != address(0)){

                users[referer].referrals.push(sender);
                user.referer = referer;
            }

            user.deposit = deposit[i];

            user.downlineBonus = downlineBonus[i];
            user.downlineVolumes = volumes[i];
            
            updateUserPool(sender);
            
            if(referer != address(0)){
                
                users[referer].directSum += deposit[i];
        
                updateUserPool(referer);
            }

        }
    }

    function setPeth(address erc20adr) external onlyOwner {
        peth = IERC20(erc20adr);
    }

    //0.44 KB
    function setPool(uint8 index, uint112 minOwnInvestment, uint8 minDirects, uint112 minSumDirects, uint8 payoutQuote) external onlyOwner {
        Pool storage pool = pools[index];
        pool.minDirects = minDirects;
        pool.minSumDirects = minSumDirects;
        pool.payoutQuote = payoutQuote;
        pool.minOwnInvestment = minOwnInvestment;
    }

    function getDetailedUserInfos(address adr) public view returns (address[] memory /*referrals */, uint112[5] memory /*volumes*/) {
        return (users[adr].referrals, users[adr].downlineVolumes);
    }

    function getDownline(address adr) public view returns (uint112, uint128){ 
        return PrestigeClubCalculations.getDownline(users, adr);
    }
    
    //DEBUGGING
    //Used for extraction of User data in case of something bad happening and fund reversal needed.
    function getUserList() public view returns (address[] memory){ 
        return userList;
    }

    function sellAccount(address from, address to) public { 

        require(msg.sender == owner() || msg.sender == _sellingContract, "Not authorized");

        User storage userFrom = users[from];

        require(userFrom.deposit > 0, "User does not exist");
        require(users[to].deposit == 0, "User already exists");

        userList[userFrom.position] = to;

        address referer = userFrom.referer;
        if(referer != address(0)){
            address[] storage arr = users[referer].referrals;
            for(uint16 i = 0 ; i < arr.length ; i++){
                if(arr[i] == from){
                    users[referer].referrals[i] = to;
                    break;
                }
            }
        }

        for(uint16 i = 0 ; i < users[from].referrals.length ; i++){
            users[userFrom.referrals[i]].referer = to;
        }

        users[to] = userFrom;
        delete users[from];

    }
}