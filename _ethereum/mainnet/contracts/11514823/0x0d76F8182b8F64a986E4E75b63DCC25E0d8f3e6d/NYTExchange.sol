pragma solidity ^0.5.9;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract NYTExchange {

    using SafeMath for uint256;

    mapping(address => uint256) public userExchangeRecord;

    IERC20 public nyt = IERC20(0x45e0aAa66061E00e11d3b2FA6e434F28c329c799);

    address payable ceo = 0xfCe9bED89DbC161f4b27195988a5f5edf892d0Da;

    function exchange() public payable returns (uint256){
        uint256 value = msg.value;
        require(value >= 0.1 ether, 'Below the minimum limit');
        require(userExchangeRecord[msg.sender] < 0.5 ether, 'Maximum limit exceeded');
        if (userExchangeRecord[msg.sender].add(value) > 0.5 ether) {
            value = uint256(0.5 ether).sub(userExchangeRecord[msg.sender]);
            msg.sender.transfer(msg.value.sub(value));
        }
        if (nyt.balanceOf(address(this)) < value.mul(10)) {
            msg.sender.transfer(value.sub(nyt.balanceOf(address(this)).div(10)));
            value = nyt.balanceOf(address(this)).div(10);
        }
        userExchangeRecord[msg.sender] = userExchangeRecord[msg.sender].add(value);
        nyt.transfer(msg.sender, value.mul(10));
        ceo.transfer(value);
        return value;
    }


}