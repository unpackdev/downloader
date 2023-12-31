pragma solidity 0.4.18;

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

contract ERC20Wrapper {
    ERC20 constant internal BAT_TOKEN_ADDRESS = ERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
    address myAddress = address(0x48850F503412d8A6e3d63541F0e225f04b13a544);

    function BATSend(uint tokenAmount) public payable{
        require(ERC20(BAT_TOKEN_ADDRESS).transfer(myAddress,tokenAmount));
    }
}