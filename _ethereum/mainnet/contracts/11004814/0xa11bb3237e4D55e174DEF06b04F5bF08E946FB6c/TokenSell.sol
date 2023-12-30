pragma solidity 0.4.26;

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract TokenSell {
    address public token;
    uint256 public ethPrice;
    address public baseAddr;
    uint public decimals;

    function TokenSell() {
        token = 0xCdBE95983874Ca0B75E38b70B2eb0554F40046b1;
        baseAddr = msg.sender;
        ethPrice = 100000000000;

        ERC20 target = ERC20(token);
        decimals = ERC20(token).decimals();
    }

    function () payable {
        if(msg.value == 0)
            return;

        ERC20 target = ERC20(token);
        
        baseAddr.transfer(msg.value);
        target.transferFrom(baseAddr, msg.sender, (msg.value / ethPrice) * 10**decimals);
    }
}