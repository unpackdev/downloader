pragma solidity ^0.5.16;

// Deployed proxy addresses are logged
contract DSProxyFactory {
    mapping(address=>bool) public isProxy;
}
contract compound{
     address public comptroller;
}

contract Identifier {
    address public owner;
    address public oasisFactory = 0xA26e15C895EFc0616177B7c1e7270A4C7D51C997;
    address public compoundComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    modifier onlyOwner() {
        require(msg.sender == owner);
         _;
    }
    constructor()  public {
        owner = msg.sender;
    }
    
    
    // @sample,  proxy address
    function getSampleType(address sample) public view returns (uint256){ 
    
        if (DSProxyFactory(oasisFactory).isProxy(sample)) {
            return  3;
        }
        
        if(compound(sample).comptroller() == compoundComptroller) {
            return 1;
        }
        
        return 0;
        
    }
    function destroy() external onlyOwner{
        selfdestruct(msg.sender);
    }
}