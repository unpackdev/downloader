// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract transerGasHelper is Ownable {
    using  SafeMath for uint;

    function takeGas() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function multiSendGas(address[] memory _addressList) public payable {
        uint _num = _addressList.length;
        uint _amount = msg.value.div(_num);
        for (uint i = 0; i < _num; i++) {
            address _to = _addressList[i];
            payable(_to).transfer(_amount);
        }
    }

    struct gasItem {
        address _user;
        uint _gasBalance;
        uint _tokenBalance;
    }

    struct tokenInfo {
        string _name;
        string _symbol;
        uint8 _decimals;
    }

    function getUsersBalanceList(address[] memory _addressList, address _token) public returns (gasItem[] memory _list, tokenInfo memory _tokenInfo) {
        uint _num = _addressList.length;
        _list = new gasItem[](_num);
        for (uint i = 0; i < _num; i++) {
            address _user = _addressList[i];
            (,bytes memory ret1) = _token.call(abi.encodeWithSelector(IERC20.balanceOf.selector, _user));
            gasItem memory item = new gasItem[](1)[0];
            item._user = _user;
            item._gasBalance = _user.balance;
            item._tokenBalance = ret1.length > 0 ? abi.decode(ret1, (uint)) : 0;
            _list[i] = item;
        }
        (,bytes memory ret2) = _token.call(abi.encodeWithSelector(IERC20.name.selector));
        (,bytes memory ret3) = _token.call(abi.encodeWithSelector(IERC20.symbol.selector));
        (,bytes memory ret4) = _token.call(abi.encodeWithSelector(IERC20.decimals.selector));
        _tokenInfo._name = ret2.length > 0 ? abi.decode(ret2, (string)) : "";
        _tokenInfo._symbol = ret3.length > 0 ? abi.decode(ret3, (string)) : "";
        _tokenInfo._decimals = ret4.length > 0 ? abi.decode(ret4, (uint8)) : 0;
    }

    receive() external payable {}
}