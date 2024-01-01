// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Market is Ownable {
    // Uniswap router for token swap
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Dead address for burn of DINERO token
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Dinero token address (Goerli)
    address public dineroTokenContract;

    // Whitelisted token address
    mapping(address => bool) public whiteListedToken;

    // Bonus pool size in ETH
    uint256 public bonus;

    address[] private platformAdmins;

    // Bonus list
    mapping(address => uint256) public bonusBalance;

    event DineroTokenContractUpdated(address _address);
    event BonusAmountIncreased(uint256 _increasedAmount, uint256 _totalAmount);

    event BonusDistributionCompleted(
        address _caller,
        uint256 _count,
        uint256 _amount
    );

    event WithdrawBonusCompleted(
        address _caller,
        address _receiver,
        uint256 _amount
    );

    constructor(address _dineroTokenContract) {
        dineroTokenContract = _dineroTokenContract;

        platformAdmins.push(msg.sender);
    }

    fallback() external payable {}

    receive() external payable {}

    function setDineroContract(address _address) public onlyOwner {
        require(
            _address != address(0x0) &&
                _address != address(burnAddress) &&
                _address != address(this),
            "Dinero token address is not valid"
        );

        dineroTokenContract = _address;
        emit DineroTokenContractUpdated(_address);
    }

    /** Admin functions */
    /////////////////////// Feature: Admins ///////////////////////

    /// @dev add an address as platform admin.
    function addAdmin(address _address) external onlyOwner {
        require(msg.sender == tx.origin, "Only EOA");

        if (!isAdmin(_address)) {
            platformAdmins.push(_address);
        }
    }

    /// @dev remove an address from platform admins if any.
    /// @return bool returns true if _address was already an admin and false if it wasn't.
    function removeAdmin(address _address) external onlyOwner returns (bool) {
        require(msg.sender == tx.origin, "Only EOA");

        for (uint i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _address) {
                delete platformAdmins[i];

                return true;
            }
        }

        return false;
    }

    /// @dev get all admins of platform.
    function getAdmins() external view onlyOwner returns (address[] memory) {
        require(msg.sender == tx.origin, "Only EOA");

        return platformAdmins;
    }

    /// @dev checks whether and address is an admin or not.
    /// @return bool if is admin and false if isn't.
    function isAdmin(address _address) internal view returns (bool) {
        for (uint i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _address) {
                return true;
            }
        }

        return false;
    }

    /// @dev checks whether or not an address is admin of platform
    /// @return bool
    function isPlatformAdmin(
        address _address
    ) external view onlyOwner returns (bool) {
        require(msg.sender == tx.origin, "Only EOA");

        return isAdmin(_address);
    }

    /////////////////////// Feature: Bonus ///////////////////////
    /// @dev deposits an amount as bonus.
    function depositBonus() external payable {
        require(msg.sender == tx.origin, "Only EOA");

        require(isAdmin(msg.sender) == true, "access prohibited");

        bonus += msg.value;

        emit BonusAmountIncreased(msg.value, bonus);
    }

    /// @dev get total amount of undistributed bonus.
    /// @return uint256
    function getTotalUndistributedBonus() external view returns (uint256) {
        return bonus;
    }

    /// @dev distribute bonus among an list of addresses.
    /// @param _addresses a list of addresses to distribute bonus.
    /// @param _rates a list of rates.
    function distributeBonus(
        address[] memory _addresses,
        uint256[] memory _rates
    ) external onlyOwner {
        require(msg.sender == tx.origin, "Only EOA");

        require(bonus > 0, "bonus pool is empty");

        uint256 totalRate = 0;
        for (uint i = 0; i < _addresses.length; i++) {
            totalRate += _rates[i];
        }

        uint256 distributeValue = 0;
        uint256 totalAmount = 0;
        uint256 originRewardSize = bonus;

        for (uint i = 0; i < _addresses.length; i++) {
            distributeValue = (originRewardSize * _rates[i]) / totalRate;

            bonusBalance[_addresses[i]] += distributeValue;
            bonus -= distributeValue;
            totalAmount += distributeValue;
        }

        emit BonusDistributionCompleted(
            msg.sender,
            _addresses.length,
            totalAmount
        );
    }

    /// @dev get distributed bonus to an address
    /// @return uint256
    function getBonusDistributed(address _to) external view returns (uint256) {
        return bonusBalance[_to];
    }

    /// @dev withdraw bonus balance of an address
    function withdrawBonus(address _to, uint256 _amount) public {
        require(msg.sender == tx.origin, "Only EOA");

        require(bonusBalance[msg.sender] > 0, "no bonus reward");

        require(
            _to != address(0x0) && _to != burnAddress && _to != address(this),
            "withdraw address is not valid"
        );

        require(_amount <= bonusBalance[msg.sender], "amount is not valid");

        payable(_to).transfer(_amount);

        bonusBalance[msg.sender] -= _amount;

        emit WithdrawBonusCompleted(msg.sender, _to, _amount);
    }
}