// SPDX-License-Identifier: MIT


pragma solidity 0.6.12;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";

interface ISpaceportFactory {
    function registerSpaceport (address _spaceportAddress) external;
    function spaceportIsRegistered(address _spaceportAddress) external view returns (bool);
}

interface IPlasmaswapLocker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _withdrawer) external payable;
}

interface IPlasmaswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPlasmaswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract SpaceportLockForwarder is Ownable {
    
    ISpaceportFactory public SPACEPORT_FACTORY;
    IPlasmaswapLocker public PLFI_LOCKER;
    IPlasmaswapFactory public PLASMASWAP_FACTORY;
    
    constructor() public {
        SPACEPORT_FACTORY = ISpaceportFactory(0x67019Edf7E115d17086e1660b577CAdccc57dFf3);
        PLFI_LOCKER = IPlasmaswapLocker(0x0e0A514E6dB0194978920Cb86a2b40a264b9a283);
        PLASMASWAP_FACTORY = IPlasmaswapFactory(0xd87Ad19db2c4cCbf897106dE034D52e3DD90ea60);
    }

    /**
        Send in _token0 as the PRESALE token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a presale is running, but no one should have access to the presale token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function plasmaswapPairIsInitialised (address _token0, address _token1) public view returns (bool) {
        address pairAddress = PLASMASWAP_FACTORY.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }
    
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external {
        require(SPACEPORT_FACTORY.spaceportIsRegistered(msg.sender), 'SPACEPORT NOT REGISTERED');
        address pair = PLASMASWAP_FACTORY.getPair(address(_baseToken), address(_saleToken));
        if (pair == address(0)) {
            PLASMASWAP_FACTORY.createPair(address(_baseToken), address(_saleToken));
            pair = PLASMASWAP_FACTORY.getPair(address(_baseToken), address(_saleToken));
        }
        
        TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(pair), _saleAmount);
        IPlasmaswapPair(pair).mint(address(this));
        uint256 totalLPTokensMinted = IPlasmaswapPair(pair).balanceOf(address(this));
        require(totalLPTokensMinted != 0 , "LP creation failed");
    
        TransferHelper.safeApprove(pair, address(PLFI_LOCKER), totalLPTokensMinted);
        uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;
        PLFI_LOCKER.lockLPToken(pair, totalLPTokensMinted, unlock_date, _withdrawer);
    }
    
}