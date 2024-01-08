// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./Ownable.sol";
import "./SafeMathUint8.sol";
import "./IterableMapping.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20Metadata.sol";
contract CREEMDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathUint8 for uint8;
    using IterableMapping for IterableMapping.Map;
    
    event ExcludeFromDividends(address indexed account);

    uint[] public minTiers = [100,500,1000,2000];
    uint[] public tiersRewards = [0.1 ether, 0.5 ether, 1 ether, 2 ether];
    IterableMapping.Map private tokenHoldersMap;
    // to be edited
    IUniswapV2Pair USDTPair = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Pair public CreemPair;
    mapping (address => bool) public excludedFromDividends;

    constructor() DividendPayingToken("CREEM Dividends", "CREEM_D") {
    }
    function setPair(address _pair) external onlyOwner {
        CreemPair = IUniswapV2Pair(_pair);
    }
    // make sure that values are in wei
    function setTierRewards(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        require(tier1>0 && tier2>tier1 && tier3>tier2 && tier4>tier3, "CREEM_D: tiers are not in order");
        tiersRewards[0] = tier1;
        tiersRewards[1] = tier2;
        tiersRewards[2] = tier3;
        tiersRewards[3] = tier4;
    }
    // make sure that values are natural numbers which represent the dollar value needed
    function setTierThreshold(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        require(tier1>0 && tier2>tier1 && tier3>tier2 && tier4>tier3, "CREEM_D: tiers are not in order");
        minTiers[0] = tier1;
        minTiers[1] = tier2;
        minTiers[2] = tier3;
        minTiers[3] = tier4;
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"CREEM_D: Address already excluded from dividends");
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	tokenHoldersMap.setTier(account, IterableMapping.Tier.DEFAULT);
    	emit ExcludeFromDividends(account);
    }
    function setBalance(address payable account, uint256 newBalance) public onlyOwner {
    	if(excludedFromDividends[account]) return;
    	
        if(newBalance > minimumForDividends(minTiers[0])) {
            
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    		
    		if(newBalance > minimumForDividends(minTiers[3])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER4);
    		}else if(newBalance > minimumForDividends(minTiers[2])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER3);
    		}else if(newBalance > minimumForDividends(minTiers[1])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER2);
    		}else{
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER1);
    		}
    	} else {
            _setBalance(account, 0);
            tokenHoldersMap.setTier(account,IterableMapping.Tier.DEFAULT);
    	    tokenHoldersMap.remove(account);
    	}
    }
    
    function shuffle() public onlyOwner{
        uint len = tokenHoldersMap.keys.length;
        require(len > 0,"CREEM_D: there must be a minimum of 1 dividneds holders");
        uint256 amount = getBalance();
        require(amount > 0, "CREEM_D: insufficient balance!");
        uint size = sizeCalc(amount,tiersRewards[0]);
        address[] memory addr = new address[](size);
        uint i = randomIndex(len);
        for(uint j = 0;j<size;j++){
            if(i==len) i = 0;
            (address account,,,) = getAccountAtIndex(i);
            uint reward = getTierReward(account);
            if(amount > reward){
                amount.sub(reward);
                addr[j] = account;
            }else{
                amount = 0;
                addr[j] = account;
                break;
            }
            i++;
        }
        address[] memory addrs = sort(addr);
        amount = getBalance();
        for(uint j = 0 ; j < addrs.length; j++){
            address account = addrs[j];
            uint reward = getTierReward(account);
            if(amount > reward){
                amount = amount.sub(reward);
                processAccount(payable(account),reward);
            }else{
                processAccount(payable(account),amount);
                break;
            }
        }
    }
    function processAccount(address payable account,uint amount) internal returns (bool) {
        uint256 _amount = _withdrawDividendOfUser(account,amount);
        return _amount > 0;
    }
    function getBalance() internal view returns(uint){
        return address(this).balance;
    }
    function getTierReward(address addr) internal view returns(uint){
        return tiersRewards[uint(tokenHoldersMap.getTier(addr)).sub(1)];
    }
    function _transfer(address, address, uint256) internal pure override {
        require(false, "CREEM_D: No transfers allowed");
    }
    function sort(address[] memory arr) internal view returns(address[] memory addr){
        uint size = arr.length;
        addr = new address[](size);
        uint i = 0;
        while(size > i){
            uint higher = greatest(arr);
            addr[i] = arr[higher];
            delete arr[higher];
            i++;
        }
    }
    function greatest(address[] memory arr) internal view returns(uint){
        uint num = 0;
        for(uint i=1;i<arr.length;i++){
            if(balanceOf(arr[i]) > balanceOf(arr[num])){
                num = i;
            }
        }
        return num;
    }
    function isExcludedFromDividends(address account) public view returns(bool) {
        return excludedFromDividends[account];
    }

    function getNumberOfTokenHolders() public view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            uint8 tier,
            uint256 totalDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);
        
        tier = uint8(tokenHoldersMap.getTier(_account));
        
        totalDividends = withdrawnDividendOf(account);
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            uint8,
            uint256) {
    	if(index >= tokenHoldersMap.size()) return (0x0000000000000000000000000000000000000000, -1, 0, 0);
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }
    function getReservesOnOrder(IUniswapV2Pair pairAddress) internal view returns(uint, uint){
        address addr1 = pairAddress.token1();
        (uint Res0, uint Res1,) = pairAddress.getReserves();
        return (addr1 == WETH) ? (Res0,Res1) : (Res1,Res0);
    }
    function getTokenPrice(IUniswapV2Pair pairAddress, uint amount, bool isEth) internal view returns(uint){
        // isEth check is the amount in is Eth or not
        (uint Res0, uint Res1) = getReservesOnOrder(pairAddress);
        return isEth ? ((amount*Res0)/Res1) : ((amount*Res1)/Res0);
    }
    function minimumForDividends(uint min) internal view returns(uint){
        address token1 = USDTPair.token0(); 
        uint ethAmount = getTokenPrice(USDTPair,min * 10** IERC20Metadata(token1).decimals(),false);
        return getTokenPrice(CreemPair,ethAmount,true);
    }
    function randomIndex(uint len) internal view returns (uint256) {
        return uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % len;
    }
    function minimumValueTier(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return minimumForDividends(minTiers[_tier.sub(1)]).mul(80).div(100 * 1 ether);
    }
    function minimumTier(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return minTiers[_tier-1];
    }
    function minimumRewards(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return tiersRewards[_tier-1];
    }
    function sizeCalc(uint256 amount, uint256 parameter) internal pure returns(uint){
      if(amount < parameter){
        return 1;
      }else{
        uint256 remainder = amount.mod(parameter) == 0 ? 0 : 1;
        return amount.div(parameter).add(remainder);
      }
    }
}