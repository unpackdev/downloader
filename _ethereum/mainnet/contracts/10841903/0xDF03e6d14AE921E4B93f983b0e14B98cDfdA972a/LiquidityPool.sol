pragma solidity 0.6.12;

interface Kye {
    function routerAddress() external view returns (address);
}

contract Routerable {
    
    address private constant _KYEADDRESS = 0xD5A4dc51229774223e288528E03192e2342bDA00;
    
    function kyeAddress() public pure returns (address) {
        return _KYEADDRESS;
    }
    
    function routerAddress() public view returns (address) {
        return Kye(kyeAddress()).routerAddress();
    }
    
    modifier onlyRouter() {
        require(msg.sender == routerAddress(), "Caller is not Router");
        _;
    }
}

contract LiquidityPool is Routerable{
    
    receive() external payable {}
    
    function give(uint amount, address payable to) public onlyRouter {
        to.transfer(amount);
    }
}