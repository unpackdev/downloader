// SPDX-License-Identifier: MIT

/*

    /$$   /$$     /$$ /$$   /$$  /$$$$$$  /$$$$$$$     /$$$$$$$$ /$$$$$$ /$$   /$$  /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$       /$$$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$   /$$$$$$  /$$       /$$$$$$$$        /$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$ /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$
  /$$$$$$|  $$   /$$/| $$  | $$ /$$__  $$| $$__  $$   | $$_____/|_  $$_/| $$$ | $$ /$$__  $$| $$$ | $$ /$$__  $$| $$_____/      | $$__  $$| $$__  $$| $$_____/ /$$__  $$ /$$__  $$| $$      | $$_____/       /$$__  $$ /$$__  $$| $$$ | $$|__  $$__/| $$__  $$ /$$__  $$ /$$__  $$|__  $$__/
 /$$__  $$\  $$ /$$/ | $$  | $$| $$  \ $$| $$  \ $$   | $$        | $$  | $$$$| $$| $$  \ $$| $$$$| $$| $$  \__/| $$            | $$  \ $$| $$  \ $$| $$      | $$  \__/| $$  \ $$| $$      | $$            | $$  \__/| $$  \ $$| $$$$| $$   | $$   | $$  \ $$| $$  \ $$| $$  \__/   | $$   
| $$  \__/ \  $$$$/  | $$$$$$$$| $$  | $$| $$$$$$$    | $$$$$     | $$  | $$ $$ $$| $$$$$$$$| $$ $$ $$| $$      | $$$$$         | $$$$$$$/| $$$$$$$/| $$$$$   |  $$$$$$ | $$$$$$$$| $$      | $$$$$         | $$      | $$  | $$| $$ $$ $$   | $$   | $$$$$$$/| $$$$$$$$| $$         | $$   
|  $$$$$$   \  $$/   | $$__  $$| $$  | $$| $$__  $$   | $$__/     | $$  | $$  $$$$| $$__  $$| $$  $$$$| $$      | $$__/         | $$____/ | $$__  $$| $$__/    \____  $$| $$__  $$| $$      | $$__/         | $$      | $$  | $$| $$  $$$$   | $$   | $$__  $$| $$__  $$| $$         | $$   
 \____  $$   | $$    | $$  | $$| $$  | $$| $$  \ $$   | $$        | $$  | $$\  $$$| $$  | $$| $$\  $$$| $$    $$| $$            | $$      | $$  \ $$| $$       /$$  \ $$| $$  | $$| $$      | $$            | $$    $$| $$  | $$| $$\  $$$   | $$   | $$  \ $$| $$  | $$| $$    $$   | $$   
 /$$  \ $$   | $$    | $$  | $$|  $$$$$$/| $$$$$$$//$$| $$       /$$$$$$| $$ \  $$| $$  | $$| $$ \  $$|  $$$$$$/| $$$$$$$$      | $$      | $$  | $$| $$$$$$$$|  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$$      |  $$$$$$/|  $$$$$$/| $$ \  $$   | $$   | $$  | $$| $$  | $$|  $$$$$$/   | $$   
|  $$$$$$/   |__/    |__/  |__/ \______/ |_______/|__/|__/      |______/|__/  \__/|__/  |__/|__/  \__/ \______/ |________/      |__/      |__/  |__/|________/ \______/ |__/  |__/|________/|________/       \______/  \______/ |__/  \__/   |__/   |__/  |__/|__/  |__/ \______/    |__/   
 \_  $$_/                                                                                                                                                                                                                                                                                   
   \__/                                                                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                            

*/
pragma solidity ^0.6.0;


library SafeCast {

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
    
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

contract PreSale {
    using SafeCast for int256;
    using SafeMath for uint256;
    using Address for address;
    
    
    uint256 public _presaleTimestamp;
    uint256 public _presaleEth;
    uint256 public _presaleRate;
    
    address public _owner;
    
    address public _tokenAddr = 0x20F85e3F809A6F90a0595552afd5Ad812D133ed3;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() public {
        
        _owner = msg.sender;
        _presaleEth = 135 ether;
        _presaleRate = 100;
        _presaleTimestamp = now + 14 days;
    }
    
    receive() external payable  {
        require(_presaleTimestamp > now,  "PreSale Ended");
        require(_presaleEth >= msg.value, "Sold out");
        require(msg.value > 0.1 ether,  "Min 0.1 ETH");
        require(msg.value < 2.01 ether,  "Max 2 ETH");
        
        address payable dev_wallet = address(uint160(viewOwner()));
        dev_wallet.transfer(msg.value);
        
        _presaleEth = _presaleEth.sub(msg.value);
        uint256 amountBought = msg.value.mul(_presaleRate);
        IERC20 _token = IERC20(_tokenAddr);
        
        _token.transfer( msg.sender, amountBought );
    }
    
    function getTokensBack() public onlyOwner() {
        IERC20 _token = IERC20(_tokenAddr);
        
        _token.transfer(address(uint160(viewOwner())), _token.balanceOf(address(this)) );
    }
    
    
    function viewOwner() public view returns(address) {
        return _owner;
    }
}