pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

abstract contract IDSProxy {
    function authority() public virtual returns (address);
}

abstract contract IDSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);
}

contract IMcdSubscribers {
    
     struct CdpHolder {
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        address owner;
        uint cdpId;
        bool boostEnabled;
        bool nextPriceEnabled;
    }
    
    function getSubscribers() public view virtual returns (CdpHolder[] memory) {}
}


contract AuthView is IMcdSubscribers {
    
    
    function hasAuth(address _proxy, address _authContract) public returns (bool) {
        address authAddr = IDSProxy(_proxy).authority();
        
        if (authAddr == address(0)) return false;
        
        return IDSGuard(authAddr).canCall(_authContract, _proxy, bytes4(keccak256("execute(address,bytes)")));
    }
    
    function checkMcdSubscribersAuth(address _subscriptionAddr, address _authContract) public returns (bool[] memory) {
        CdpHolder[] memory cdps = IMcdSubscribers(_subscriptionAddr).getSubscribers();
        
        bool[] memory approvals = new bool[](cdps.length);
        
        for(uint i = 0; i < cdps.length; ++i) {
            approvals[i] = hasAuth(cdps[i].owner, _authContract);
        }
        
        return approvals;
    }
    

}