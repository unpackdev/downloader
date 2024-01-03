pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ProfitNotifier.sol";

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./IUniswapV2Router02.sol";

contract CompoundLendingStrategy is ProfitNotifier {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    address public mainAsset;
    address public compAsset;

    address public governance;
    address public vault;
    address public agent;
    uint256 public invested;

    // MAINNET ADDRESSES
    address public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(address _mA, address _compAsset, address _agent) {
        governance = msg.sender;
        vault = msg.sender;
        mainAsset = _mA;
        compAsset = _compAsset;
        agent = _agent;
        invested = 0;

        (bool isListed, , ) = ComptrollerInterface(comptroller).markets(compAsset);
        require(isListed == true, 'comp token not found');
        require(CTokenInterface(compAsset).isCToken() == true, 'comp token not cToken');

        // We are not borrowing, we shouldn't enter the market
        // address[] memory cTokens = new address[](1);
        // cTokens[0] = _compAsset;
        // ComptrollerInterface(comptroller).enterMarkets(cTokens);
    }

    function setRewardForwarder(address _new) external {
        require(msg.sender == governance, '!governance');
        feeRewardForwarder = _new;
    }

    function setProfitSharingDenominator(uint256 _new) external {
        require(msg.sender == governance, '!governance');
        profitSharingDenominator = _new;
    }

    function setGovernance(address _gov) external {
        require(msg.sender == governance, '!governance');
        governance = _gov;
    }

    function setVault(address _vault) external {
        require(msg.sender == governance, '!governance');
        vault = _vault;
    }

    function setAgent(address _agent) external {
        require(msg.sender == governance, '!governance');
        agent = _agent;
    }

    function underlyingBalance() public view returns(uint256){
        // return CTokenInterface(compAsset).balanceOfUnderlying(address(this));
        return invested;
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256){
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        CErc20Interface(compAsset).redeemUnderlying(_amount);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        invested = invested.sub(_after.sub(_before));
        return _after.sub(_before);
    }

    function _withdrawStrategyAll() internal returns(uint256){
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        uint256 _underlyingBalance = underlyingBalance();
        CErc20Interface(compAsset).redeemUnderlying(_underlyingBalance);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        invested = 0;
        return _after.sub(_before);
    }

    function liquidate() public {
        require(msg.sender == vault || msg.sender == governance, '!governance');
        _withdrawStrategyAll();
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        
        require(vault != address(0), 'burning funds');
        IERC20(mainAsset).safeTransfer(vault, _balance);
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == vault, '!vault');
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_balance < _amount){
            _amount = _withdrawStrategy(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        // Fees
        require(vault != address(0), 'burning funds');

        IERC20(mainAsset).safeTransfer(vault, _amount);
    }

    function deposit() public {
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_balance > 0){
            IERC20(mainAsset).safeApprove(compAsset, 0);
            IERC20(mainAsset).safeApprove(compAsset, _balance);

            CErc20Interface(compAsset).mint(_balance);

            invested = invested.add(_balance);
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        ComptrollerInterface(comptroller).claimComp(address(this));
        uint256 _cBalance = IERC20(comp).balanceOf(address(this));
        if(_cBalance > 0){
            address[] memory path = new address[](3);
            path[0] = comp;
            path[1] = weth;
            path[2] = mainAsset;

            IUniswapV2Router02(uniswap).swapExactTokensForTokens(_cBalance, uint256(0), path, address(this), block.timestamp.add(1800));
            uint256 _after = IERC20(mainAsset).balanceOf(address(this));
            notifyProfit(_before, _after, mainAsset);
            deposit();
        }
    }
}