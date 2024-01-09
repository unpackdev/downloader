// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.6.0 <0.8.9;
pragma experimental ABIEncoderV2;
import "./ERC721.sol";
import "./Ownable.sol";

interface ISimps {
    function ownerOf(uint id) external view returns (address);
    function isQueen(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata _data ) external;
}

interface ILLove {
    function mint(address account, uint amount) external;
}

interface IRandom {
    function updateRandomIndex() external;
    function getSomeRandomNumber(uint _seed, uint _limit) external view returns (uint16);
    
}

contract SimpsOffice is Ownable, IERC721Receiver {
    uint16 public version=21;
    bool private _paused = false;

    uint16 private _randomIndex = 0;
    uint private _randomCalls = 0;
    mapping(uint => address) private _randomSource;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint bouns;
    }

    
    uint public startExtraTimestamp;
    uint public endExtraTimeStamp;
    uint8 public extraPercentage;

    event TokenStaked(address owner, uint16 tokenId, uint value);
    event SimpClaimed(uint16 tokenId, uint earned, bool unstaked);
    event QueenClaimed(uint16 tokenId, uint earned, bool unstaked);

    ISimps public simpsCity;
    ILLove public love;
    IRandom public random;

    mapping(uint256 => uint256) public simpIndices;
    mapping(address => Stake[]) public simpStake;

    mapping(uint256 => uint256) public queenIndices;
    mapping(address => Stake[]) public queenStake;

    mapping(address => uint256) public mercyJackpot;
    mapping(address => uint256) public loveBoost;

    address[] public simpHolders;
    address[] public queenHolders;

    uint16[10] public mercyJackpotTokens;
    address[10] public mercyJackpotWinners;

    // Total staked tokens
    uint public totalSimpStaked =0 ;
    uint public totalQueenStaked = 0;
    uint public unaccountedRewards = 0;
    uint public mercyJackpotPool =0;
    uint public lastMercyJackpotPayout = 0;

    // Simp earn 10000 $LLOVE per day
    uint public constant DAILY_LLOVE_RATE = 10000 ether;
    uint public constant MINIMUM_TIME_TO_EXIT = 2 days;
    uint public constant TAX_PERCENTAGE = 15;
    uint public constant TAX_MERCYJACKPOT = 5;
    uint public MERCY_JACKPOT_PAY_PERIOD = 6 hours;
    uint16 public MERCY_JACKPOT_PAYER_COUNT = 10;
    uint public constant PAY_PERIOD = 1 days;
    
    uint public constant ALL_LOVE_IN_THE_UNIVERSE = 4320000000 ether;

    uint public totalLoveEarned;

    uint public lastClaimTimestamp;
    uint public queenReward = 0;


    constructor(){

    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setSimps(address _simpsCity) external onlyOwner {
        simpsCity = ISimps(_simpsCity);
    }

    function setLove(address _love) external onlyOwner {
        love = ILLove(_love);
    }

    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
    }

    function getAccountSimps(address user) external view returns (Stake[] memory) {
        return simpStake[user];
    }

    function getAccountQueens(address user) external view returns (Stake[] memory) {
        return queenStake[user];
    }

    function addTokensToStake(address account, uint16[] calldata tokenIds) external {
        require(account == msg.sender || msg.sender == address(simpsCity), "You do not have a permission to do that");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (msg.sender != address(simpsCity)) {
                // dont do this step if its a mint + stake
                require(simpsCity.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to msg.sender address");
                simpsCity.transferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (simpsCity.isQueen(tokenIds[i])) {
                _stakeQueens(account, tokenIds[i]);
            } else {
                _stakeSimps(account, tokenIds[i]);
            }
        }
    }

    function _stakeSimps(address account, uint16 tokenId) internal whenNotPaused _updateEarnings {
        totalSimpStaked += 1;

        // If account already has some simps no need to push it to the tracker
        if (simpStake[account].length == 0) {
            simpHolders.push(account);
        }

        simpIndices[tokenId] = simpStake[account].length;
        simpStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            bouns:0
        }));
        emit TokenStaked(account, tokenId, block.timestamp);
    }


    function _stakeQueens(address account, uint16 tokenId) internal {
        totalQueenStaked += 1;

        // If account already has some queens no need to push it to the tracker
        if (queenStake[account].length == 0) {
            queenHolders.push(account);
        }

        queenIndices[tokenId] = queenStake[account].length;
        queenStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(queenReward),
            bouns:0
            }));

        emit TokenStaked(account, tokenId, queenReward);
    }

    function addExtraPay(uint start,uint end,uint8 percentage) public onlyOwner{
        startExtraTimestamp = start;
        endExtraTimeStamp = end;
        extraPercentage = percentage;
    }

    function claimFromStake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!simpsCity.isQueen(tokenIds[i])) {
                owed += _claimFromSimp(tokenIds[i], unstake);
            } else {
                owed += _claimFromQueen(tokenIds[i], unstake);
            }
        }

        if(_checkMercyJackpotPayoutTime()){
            _mercyJackpotPayout2();
        }

        if (owed == 0) return;
        love.mint(msg.sender, owed);
    }

    function _claimFromSimp(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = simpStake[msg.sender][simpIndices[tokenId]];
        require(stake.owner == msg.sender, "This NTF does not belong to msg.sender address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait 2 days since last claim");

        //before tax
        if (totalLoveEarned < ALL_LOVE_IN_THE_UNIVERSE) {
            owed = ((block.timestamp - stake.value) * DAILY_LLOVE_RATE) / PAY_PERIOD;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $LLOVE production stopped already
        } else {
            owed = ((lastClaimTimestamp - stake.value) * DAILY_LLOVE_RATE) / PAY_PERIOD; // stop earning additional $LLOVE if it's all been earned
        }

        if(endExtraTimeStamp>0){
            // The extra pay is enable.
            //cal extra pay
            if(block.timestamp<= startExtraTimestamp){
                //nth
            }else if(stake.value<=startExtraTimestamp && block.timestamp<=endExtraTimeStamp){
                owed = owed+((block.timestamp-startExtraTimestamp)* DAILY_LLOVE_RATE)*extraPercentage/100 / PAY_PERIOD;
            }else if(stake.value>=startExtraTimestamp && block.timestamp<=endExtraTimeStamp){
                owed = owed+ ((block.timestamp - stake.value)* DAILY_LLOVE_RATE)*extraPercentage/100/ PAY_PERIOD;
            }else if(stake.value<=startExtraTimestamp && block.timestamp>=endExtraTimeStamp){
                owed = owed+ (endExtraTimeStamp-startExtraTimestamp)*extraPercentage/100/ PAY_PERIOD;
            }else if(stake.value>=startExtraTimestamp && block.timestamp>=endExtraTimeStamp){
                owed = owed+ (endExtraTimeStamp-stake.value)*extraPercentage/100/ PAY_PERIOD;
            }
        }

        owed = owed+stake.bouns;

        if (unstake) {
            if (random.getSomeRandomNumber(tokenId, 100) <= 50) {
                //lost all earnings
                _payQueenTax((owed * 95) / 100);
                _paymercyJackpotPool((owed * TAX_MERCYJACKPOT)/100);
                owed = 0;
            }
            random.updateRandomIndex();
            totalSimpStaked -= 1;

            //move the last staked token to the index of the token to be unstaked
            //then pop the last one
            Stake memory lastStake = simpStake[msg.sender][simpStake[msg.sender].length - 1];
            simpStake[msg.sender][simpIndices[tokenId]] = lastStake;
            simpIndices[lastStake.tokenId] = simpIndices[tokenId];
            simpStake[msg.sender].pop();
            delete simpIndices[tokenId];
            updateSimpOwnerAddressList(msg.sender);
            simpsCity.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            _payQueenTax((owed * TAX_PERCENTAGE) / 100);
            _paymercyJackpotPool((owed * TAX_MERCYJACKPOT)/100); // Pay some $LLOVE to queens!
            owed = (owed * (100 - (TAX_PERCENTAGE+TAX_MERCYJACKPOT))) / 100;
            owed = owed + simpStake[msg.sender][simpIndices[tokenId]].bouns; 
            uint80 timestamp = uint80(block.timestamp);

            simpStake[msg.sender][simpIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: timestamp,
                bouns:0
            }); // reset stake
        }

        emit SimpClaimed(tokenId, owed, unstake);
    }

    function _claimFromQueen(uint16 tokenId, bool unstake) internal returns (uint owed) {
        require(simpsCity.ownerOf(tokenId) == address(this), "This NTF does not belong to contract address");

        Stake memory stake = queenStake[msg.sender][queenIndices[tokenId]];

        require(stake.owner == msg.sender, "This NTF does not belong to msg sender address");
        owed = (queenReward - stake.value);
        owed = owed+stake.bouns;
        if (unstake) {
            totalQueenStaked -= 1; // Remove Alpha from total staked

            Stake memory lastStake = queenStake[msg.sender][queenStake[msg.sender].length - 1];
            queenStake[msg.sender][queenIndices[tokenId]] = lastStake;
            queenIndices[lastStake.tokenId] = queenIndices[tokenId];
            queenStake[msg.sender].pop();
            delete queenIndices[tokenId];
            updateQueenOwnerAddressList(msg.sender);

            simpsCity.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            queenStake[msg.sender][queenIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(queenReward),
                bouns:0
            }); // reset stake
        }
        emit QueenClaimed(tokenId, owed, unstake);
    }

    function startMercyJackpot() public onlyOwner{
        lastMercyJackpotPayout = block.timestamp; 
    }

    function setMercyJackpotPayPeriod(uint period) public onlyOwner{
        MERCY_JACKPOT_PAY_PERIOD = period; 
    }

    function setMercyJackpotPayerCount(uint16 count) public onlyOwner{
        MERCY_JACKPOT_PAYER_COUNT = count; 
    }

    function _checkMercyJackpotPayoutTime() internal returns (bool needPayOut){
        if(lastMercyJackpotPayout>0&&block.timestamp - lastMercyJackpotPayout > MERCY_JACKPOT_PAY_PERIOD){
            lastMercyJackpotPayout = lastMercyJackpotPayout + MERCY_JACKPOT_PAY_PERIOD*((block.timestamp - lastMercyJackpotPayout)/ MERCY_JACKPOT_PAY_PERIOD);
            return true;
        }else{
            return false;
        }
    }

    function checkMercyJackpotPayoutTime() public {
        _checkMercyJackpotPayoutTime();
    }

    // function _mercyJackpotPayout() internal returns (Stake[] memory stakedTokens){

    //     Stake[] memory tokens = new Stake[](totalSimpStaked);
        
    //     uint16  k=0;
    //     //get list of account which only contain simps
    //     for(uint16 i =0; i <simpHolders.length; i++ ){
    //         for(uint16 j =0; j<simpStake[simpHolders[i]].length; j++){
    //             tokens[k] = simpStake[simpHolders[i]][j];
    //             k++;
    //         }
    //     }

    //     if(totalSimpStaked <=MERCY_JACKPOT_PAYER_COUNT){
    //         uint payout = mercyJackpotPool/totalSimpStaked;
    //         mercyJackpotPool = 0;

            
    //         for(uint16 q =0 ; q<totalSimpStaked; q++){

    //             Stake memory luckySimp = tokens[q];
                
    //             //set the pay to bouns
    //             simpStake[luckySimp.owner][simpIndices[luckySimp.tokenId]].bouns=simpStake[luckySimp.owner][simpIndices[luckySimp.tokenId]].bouns+ payout;

    //             mercyJackpotTokens[q] = luckySimp.tokenId;
    //         }


    //     }else{
    //         uint payout = mercyJackpotPool/MERCY_JACKPOT_PAYER_COUNT;
    //         mercyJackpotPool = 0;

    //         for(uint16 q =0 ; q<MERCY_JACKPOT_PAYER_COUNT; q++){
    //             uint16 lucky = random.getSomeRandomNumber(q, tokens.length-1-q);
    //             Stake memory luckySimp = tokens[lucky];
    //             tokens[lucky] = tokens[tokens.length-1];
                

    //             //set the pay to bouns
    //             simpStake[luckySimp.owner][simpIndices[luckySimp.tokenId]].bouns=simpStake[luckySimp.owner][simpIndices[luckySimp.tokenId]].bouns+ payout;

    //             mercyJackpotTokens[q] = luckySimp.tokenId;
    //         }
            
    //     }

    //     return tokens;

    // }


    function _mercyJackpotPayout2() internal {


        if(simpHolders.length<=MERCY_JACKPOT_PAYER_COUNT){
            //share the pool
            uint payout = mercyJackpotPool/simpHolders.length;
            for(uint16 i =0; i <simpHolders.length; i++ ){
                mercyJackpotWinners[i] = simpHolders[i];
                love.mint(simpHolders[i], payout);
            }

        }else{
            uint payout = mercyJackpotPool/MERCY_JACKPOT_PAYER_COUNT;

            for(uint16 i =0; i<MERCY_JACKPOT_PAYER_COUNT; i++){
                mercyJackpotWinners[i] = simpHolders[random.getSomeRandomNumber(i,simpHolders.length-1)];
                love.mint(mercyJackpotWinners[i],payout);
            }

        }

        mercyJackpotPool = 0;

    }

    function mercyJackpotPayout() public{
         _mercyJackpotPayout2();
    }

    function getJackpotWinners() public view returns(address[] memory){
        address[] memory b = new address[](mercyJackpotWinners.length);
        for (uint i=0; i < mercyJackpotWinners.length; i++) {
            b[i] = mercyJackpotWinners[i];
        }
        return b;
    }

    function updateQueenOwnerAddressList(address account) internal {
        if (queenStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all queens
        address lastOwner = queenHolders[queenHolders.length - 1];
        uint indexOfHolder = 0;
        for (uint i = 0; i < queenHolders.length; i++) {
            if (queenHolders[i] == account) {
                indexOfHolder = i;
                break;
            }
        }
        queenHolders[indexOfHolder] = lastOwner;
        queenHolders.pop();
    }


    function updateSimpOwnerAddressList(address account) internal {
        if (simpStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all simps
        address lastOwner = simpHolders[simpHolders.length - 1];
        uint indexOfHolder = 0;
        for (uint i = 0; i < simpHolders.length; i++) {
            if (simpHolders[i] == account) {
                indexOfHolder = i;
                break;
            }
        }
        simpHolders[indexOfHolder] = lastOwner;
        simpHolders.pop();
    }


    function _payQueenTax(uint _amount) internal {
        if (totalQueenStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        queenReward += (_amount + unaccountedRewards) / totalQueenStaked;
        unaccountedRewards = 0;
    }

    function _paymercyJackpotPool(uint _amount) internal {
        mercyJackpotPool += _amount;
    }


    modifier _updateEarnings() {
        if (totalLoveEarned < ALL_LOVE_IN_THE_UNIVERSE) {
            totalLoveEarned += ((block.timestamp - lastClaimTimestamp) * totalSimpStaked * DAILY_LLOVE_RATE) / PAY_PERIOD;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }


    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }


    function randomQueenOwner() external returns (address) {
        if (totalQueenStaked == 0) return address(0x0);

        uint holderIndex = random.getSomeRandomNumber(totalQueenStaked, queenHolders.length);
        random.updateRandomIndex();

        return queenHolders[holderIndex];
    } 

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external  override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to this contact directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}