// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IRouter {
    function WETH() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}

contract RevmSimulator {
    uint256 MAX_INT = 2**256 - 1;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function destroy() external {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }

    function _calculateGas(IRouter router, uint256 amountIn, address[] memory path) internal returns (uint256){
        uint256 usedGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 
            0, 
            path, 
            address(this), 
            block.timestamp + 100
        );

        usedGas = usedGas - gasleft();

        return usedGas;
    }

    function check(address dexRouter, address[] calldata path) external payable returns(uint256[6] memory) {
        require(path.length == 2);

        IRouter router = IRouter(dexRouter);

        IBEP20 baseToken = IBEP20(path[0]);
        IBEP20 targetToken = IBEP20(path[1]);

        uint tokenBalance;
        address[] memory routePath = new address[](2);
        uint expectedAmountsOut;

        if(path[0] == router.WETH()) {
            IWETH wbnb = IWETH(router.WETH());
            wbnb.deposit{value: msg.value}();

            tokenBalance = baseToken.balanceOf(address(this));
            expectedAmountsOut = router.getAmountsOut(msg.value, path)[1];
        } else {
            routePath[0] = router.WETH();
            routePath[1] = path[0];
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                routePath,
                address(this), 
                block.timestamp + 100
            );
            tokenBalance = baseToken.balanceOf(address(this));
            expectedAmountsOut = router.getAmountsOut(tokenBalance, path)[1];
        }

        // approve token
        baseToken.approve(dexRouter, MAX_INT);
        targetToken.approve(dexRouter, MAX_INT);

        uint estimatedBuy = expectedAmountsOut;

        uint buyGas = _calculateGas(router, tokenBalance, path);

        tokenBalance = targetToken.balanceOf(address(this));

        uint exactBuy = tokenBalance;

        //swap Path
        routePath[0] = path[1];
        routePath[1] = path[0];

        expectedAmountsOut = router.getAmountsOut(tokenBalance, routePath)[1];

        uint estimatedSell = expectedAmountsOut;

        uint sellGas = _calculateGas(router, tokenBalance, routePath);

        tokenBalance = baseToken.balanceOf(address(this));

        uint exactSell = tokenBalance;

        return [
            buyGas,
            sellGas,
            estimatedBuy,
            exactBuy,
            estimatedSell,
            exactSell
        ];
    }
}