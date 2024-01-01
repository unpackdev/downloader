// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function approve(address spender, uint value) external;
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface proxy {
   function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
}

contract swapHelper is Ownable {
    using SafeMath for uint;
    IERC20 public bCHAX = IERC20(0xccC9fEe3011d4437e93184a9347eaAa838304c79);
    address public proxyAddress = 0xe4E724BE93d713135840386489eD50594094f1eF;
    uint public minAmount = 0;

    function setMinAmount(uint _minAmount) external onlyOwner  {
       minAmount = _minAmount;
       bCHAX.approve(proxyAddress,10**18*10**18);
    }


    function takeErc20Token(IERC20 _token) external onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function doSwap() external onlyOwner {
        uint left = bCHAX.balanceOf(proxyAddress);
        require(left>=minAmount,"e001");
        uint myBalance = bCHAX.balanceOf(address(this));
        if (myBalance<left) {
           proxy(proxyAddress).swap(myBalance,0,msg.sender);
        } else {
           proxy(proxyAddress).swap(left,0,msg.sender); 
        }
    }

    receive() payable external {}
}