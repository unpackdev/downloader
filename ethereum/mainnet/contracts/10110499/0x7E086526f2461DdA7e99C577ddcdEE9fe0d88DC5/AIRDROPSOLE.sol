pragma solidity ^0.5.11;

library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract SOLEDAO {
    function getAddresses() public view returns(address  [] memory) { }
    function balanceOf(address _owner) public view returns (uint256 balance) { }
}

contract SOLE {
    function transfer(address _to, uint256 _value) public returns (bool) { }
    function balanceOf(address _owner) public view returns (uint256 balance) { }
}

contract AIRDROPSOLE {
    using SafeMath for uint256;
    
    SOLEDAO smb;
    SOLE sl;
    uint256 zero = 0;
    address _owner;
    address[] public userAddresses;


    event soleAirDrop(address indexed to, uint value);
    event test(uint256 date, uint256 balance);
    
    constructor(address solemb, address sole) public {
        smb = SOLEDAO(solemb);
        sl = SOLE(sole);
        _owner = msg.sender;
    }
    
    function airDrop(uint256 dropAmount)internal returns(bool) {
        require( msg.sender == _owner );
        uint256 contractBalance = sl.balanceOf(address(this));
        require(contractBalance >= dropAmount);
        
        userAddresses = smb.getAddresses();
        uint256 value;
        uint256 solembBalance;

        uint arrayLength = userAddresses.length;
        
        for (uint i=0; i< arrayLength; i++) {
            solembBalance = smb.balanceOf(userAddresses[i]);
            
            if ( solembBalance > zero){
                
                value = (dropAmount.mul(solembBalance)).div(200) ;
            
                sl.transfer( userAddresses[i] ,value);
                
                emit soleAirDrop(userAddresses[i], value);
            }
        }
        
        return true;
    }
    
    // 31 oct = 1604102400 
    function Drop()public {
        require( msg.sender == _owner );
        
        uint256 contractBalance = sl.balanceOf(address(this));
        uint256 unfreezeDate = 1604102400;
        uint256 dropAmount = 0;
        uint256 freezeAmount = 250000000000000;
        uint256 today = now;
        
        emit test(today, contractBalance.sub(freezeAmount));
        
        if (today < unfreezeDate) {
            dropAmount = contractBalance.sub(freezeAmount);
            
            if (dropAmount > 0 ){
                airDrop(dropAmount);
                
            }
            
        }else{
            airDrop(contractBalance);
        }
        
    }
    
    function transferownership(address _newaddress) public returns(bool){
        require(msg.sender== _owner);
        _owner=_newaddress;
        return true;
        
    }
    
}