pragma experimental ABIEncoderV2;
//Import OpenZepplin libs
import "./Ownable.sol";
import "./IERC20.sol";
//Import job interfaces and helper interfaces
import "./IKeep3rV1Mini.sol";
import "./ICoreFlashArb.sol";
//Import Uniswap interfaces
import "./IUniswapV2Pair.sol";


contract CoreFlashArbRelay3rOpt is Ownable{

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");
        _;
        RLR.worked(msg.sender);
    }

    IKeep3rV1Mini public RLR;
    ICoreFlashArb public CoreArb;
    IERC20 public CoreToken;

    //Init interfaces with addresses
    constructor (address token,address corearb,address coretoken) public {
        RLR = IKeep3rV1Mini(token);
        CoreArb = ICoreFlashArb(corearb);
        CoreToken = IERC20(coretoken);
    }

    //Helper functions for handling sending of reward token
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }

    //Required cause coreflasharb contract doesnt make this easily retrievable
    function getRewardToken(uint strat) public view returns (address) {
        ICoreFlashArb.Strategy memory stratx = CoreArb.strategyInfo(strat);//Get full strat data
        // Eg. Token 0 was out so profit token is token 1
        return stratx.token0Out[0] ? IUniswapV2Pair(stratx.pairs[0]).token1() : IUniswapV2Pair(stratx.pairs[0]).token0();
    }

    //Set new contract address incase core devs change the flash arb contract
    function setCoreArbAddress(address newContract) public onlyOwner {
        CoreArb = ICoreFlashArb(newContract);
    }

    function workable() public view returns (bool) {
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                return true;
        }
    }

    function profitableCount() public view returns (uint){
        uint count = 0;
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                count++;
        }
        return count;
    }

    //Return profitable strats array and reward tokens
    function profitableStratsWithTokens() public view returns (uint[] memory,address[] memory){
        uint profitableCount = profitableCount();
        uint index = 0;

        uint[] memory _profitable = new uint[](profitableCount);
        address[] memory _rewardToken = new address[](profitableCount);

        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0){
                _profitable[index] = i;
                _rewardToken[index] = getRewardToken(i);
                index++;
            }

        }
        return (_profitable,_rewardToken);
    }

    //Used to execute multiple profitable strategies
    function workBatch(uint[] memory profitable,address[] memory rewardTokens) public upkeep{
        require(workable(),"No profitable arb");
        for(uint i=0;i<profitable.length;i++){
            CoreArb.executeStrategy(profitable[i]);
            //Send strat reward to executor
            sendERC20(rewardTokens[i],msg.sender);
        }
    }

    //Added to recover erc20 tokens
    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

}