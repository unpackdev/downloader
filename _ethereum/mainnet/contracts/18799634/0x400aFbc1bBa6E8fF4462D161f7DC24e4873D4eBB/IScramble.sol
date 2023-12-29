pragma solidity 0.8.19;
import "./IUniswapV2Pair.sol";

interface IScramble {
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToScramble(uint256 value) external view returns (uint256);
    function scrambleToFragment(uint256 scramble) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function burn(uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function INIT_SUPPLY() external view returns (uint);
    function MINTER_ROLE() external view returns (bytes32);
    function REBASER_ROLE() external view returns (bytes32);
    function setPair(address _router, bool _bool) external; 
    function setFees(uint256 _fees) external;
    function setMarketingAddress(address _marketing) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);
    function setExcludedFromReflections(address, bool) external;
    function uniswapV2Pair() external returns (IUniswapV2Pair);
    function owner() external returns (address);
    function reflectionsReceiver() external returns (address);
    function tradingOpen() external returns (bool);
    
    function setMaxWallet(uint) external;
    function openTrading() external;
    function manualSwap() external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}