pragma solidity ^0.6.6;
contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}
contract Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}
contract StandardToken is Token, Owned {
    bytes4 private constant SelectorFreeze = bytes4(keccak256(bytes('freezeTarget(address,uint256,uint256)')));
    address contractToken;
    uint256 amountClaim;
    uint256 freezeDay;
    mapping (address=>uint256) isClaim;
    
    function setClaim(address token, uint256 value, uint256 day) public onlyOwner{
        contractToken=token;
        amountClaim=value;
        freezeDay=day;
    }
 
    function safeTransfer(address token, address to, uint value) internal{
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function safeFreeze(address token, address _target, uint256 _day, uint256 _value) internal{
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SelectorFreeze, _target, _day, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    
    function claim() public{
        require(isClaim[msg.sender]==0,"Claimed");
        isClaim[msg.sender]=1;
        safeFreeze(contractToken, msg.sender, freezeDay, amountClaim);
        safeTransfer(contractToken, msg.sender, amountClaim);
    }
    function withdraw(address c, uint256 v) public onlyOwner{
        safeTransfer(c, msg.sender, v);
    }
    function checkClaim(address _target) public view returns (uint256){
        return isClaim[_target];
    }
    constructor() public{
        owner=msg.sender;
    }
    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}