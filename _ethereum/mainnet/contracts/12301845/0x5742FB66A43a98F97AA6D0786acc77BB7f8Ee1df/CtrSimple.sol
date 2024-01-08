contract CtrSimple {
    uint public myUint = 10;
    
    function setUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    function doubleUint() public {
        myUint = 2 * myUint;
    }
    
}