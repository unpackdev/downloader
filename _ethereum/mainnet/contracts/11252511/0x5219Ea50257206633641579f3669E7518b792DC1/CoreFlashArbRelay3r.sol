import "./Ownable.sol";
import "./IERC20.sol";

import "./IKeep3rV1Mini.sol";
import "./ICoreFlashArb.sol";

contract CoreFlashArbRelay3r is Ownable{

    modifier upkeep() {
        require(RL3R.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        RL3R.worked(msg.sender);
    }

    IKeep3rV1Mini public RL3R;
    ICoreFlashArb public CoreArb;
    IERC20 public CoreToken;
    //Init interfaces with addresses
    constructor (address token,address corearb,address coretoken) public {
        RL3R = IKeep3rV1Mini(token);
        CoreArb = ICoreFlashArb(corearb);
        CoreToken = IERC20(coretoken);
    }

    //Set new contract address incase core devs change the flash arb contract
    function setCoreArbAddress(address newContract) public onlyOwner {
        CoreArb = ICoreFlashArb(newContract);
    }

    function workable() public view returns (bool){
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                return true;
        }
    }

    function work() public upkeep {
        require(workable(),"No profitable arb strat");
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                CoreArb.executeStrategy(i);
        }
        //At the end send the core gotten to the relay3r executing the work func
        CoreToken.transfer(msg.sender,CoreToken.balanceOf(address(this)));
    }

}