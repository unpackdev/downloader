pragma solidity 0.5.11;

contract IMedianizer {

    function read()
        public
        view
        returns (bytes32);
}

contract MultiPurchaser {
    
    IMedianizer maker = IMedianizer(0x729D19f657BD0614b4985Cf1D82531c67569197B);
    
    constructor() public {
        
    }
    
    function price() public view returns (uint256) {
        return uint256(IMedianizer(maker).read());
    }
}