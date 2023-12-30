pragma solidity ^0.5.7;


contract Hackers {

    address payable public developer_1;
    address payable public developer_2;
    address owner;
    
    function() external payable {}

    modifier onlyOwner{
        require(owner == msg.sender, "Only the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function sendEth() private {
        uint256 half = address(this).balance / 2;
        if (address(uint160(developer_1)).send(half)) {}
        if (address(uint160(developer_2)).send(address(this).balance)) {}
    }

    function withdrawEth() public {
        sendEth();
    }

    function withdrawTokens(address _t) public {
        require(Token(_t).balanceOf(address(this)) > 0, "The balance is less than 0");
        uint256 half = Token(_t).balanceOf(address(this)) / 2;
        Token(_t).transfer(developer_1, half);
        Token(_t).transfer(developer_2, Token(_t).balanceOf(address(this)));
    }

    function setAddrDev_1(address payable _addr) external onlyOwner {
        developer_1 = _addr;
    }

    function setAddrDev_2(address payable _addr) external onlyOwner {
        developer_2 = _addr;
    }

}

contract Token {
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}