// SPDX-License-Identifier: MIT
// SandBox1 
pragma solidity 0.8.21;

import "IMarketRegistry.sol";
import "IMarketAdapter.sol";
import "IOracleAdapter.sol";
import "ISandbox1.sol";
import "ISandbox2.sol";
import "ITreasury.sol";
import "IERC20Mint.sol";
import "Ownable.sol";
import "TransferHelper.sol";
import "TimeLock.sol";

/// @title MarketRegistry 
/// @author UBD Team
/// @notice This contract encapsulate all AMM logic for UBD ecosystem
/// @dev  Check deploy params so they are immutable
contract MarketRegistry is IMarketRegistry, Ownable, TimeLock{

    uint8 public constant   NATIVE_TOKEN_DECIMALS = 18;
    uint256 public constant PERCENT_DENOMINATOR = 10000; 
    uint8 public immutable  MIN_NATIVE_PERCENT;

    // Slippage params in Base Points ( https://en.wikipedia.org/wiki/Basis_point )
    uint256 public constant DEFAULT_SLIPPAGE_MAX = 1000; // 10%=1000 bp, 0.1%=10 bp, etc
    uint256 public   DEFAULT_SLIPPAGE =  100; //   1%=100 bp, 0.1%=10 bp, etc
    
    address public UBD_TEAM_ADDRESS;
    UBDNetwork public ubdNetwork;

    // from asset() to market for this asset.
    mapping(address => Market) public markets;

    event ReceivedEther(address, uint);
    event TreasuryChangeScheduled(bytes32 indexed ParamsHash, uint256 ScheduledAt);
    event TreasuryChanged(bytes32 indexed ParamsHash, uint256 FactdAt);

    modifier onlySandboxes()
    {
        require(
            msg.sender == ubdNetwork.sandbox1 || 
            msg.sender == ubdNetwork.sandbox2, 
            'Only for SandBoxes'
        );
        _;
    }


    constructor(uint8 _minNativePercent, uint256 _timeLockDelay)
    TimeLock(_timeLockDelay)
    {
        MIN_NATIVE_PERCENT = _minNativePercent;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    /// @notice Swap any asset (available at AMM) to Sandboxe1  BASE asset
    /// @dev only called from Sandboxes
    /// @param amountIn - amount with decimcals
    /// @param amountOutMin - min acceptable amount of base asset
    /// @param assetIn - contract address of in asset
    /// @param to - address which receive base asset
    /// @param deadline - acceptable time
    function swapExactInToBASEOut(
        uint256 amountIn,
        uint256 amountOutMin,
        address assetIn,
        address to,
        uint deadline
    ) external onlySandboxes returns (uint256 amountOut) 

    {
        address[] memory path = new address[](2);
        path[0] = assetIn;
        path[1] = ISandbox1(ubdNetwork.sandbox1).EXCHANGE_BASE_ASSET();
        // Because this method used for swap ANY asset to Base, 
        // lets get market fror EXCHANGE_BASE_ASSET
        Market memory mrkt = _getMarketForAsset(path[1]); 

        TransferHelper.safeTransferFrom(
            assetIn, to, mrkt.marketAdapter, 
            amountIn // 
        );
        
        uint256 notLessThen = _getNotLessThenEstimate(amountIn, path, mrkt.slippage);
        amountOut = IMarketAdapter(mrkt.marketAdapter).swapExactERC20InToERC20Out(
                amountIn,
                notLessThen, 
                path,
                to,
                block.timestamp
            );
    }

    /// @notice Swap Treasury assets  to Sandbox1 (usdt) or to Sandbox2  (dai) asset
    /// @dev only called from Sandboxes
    function swapTreasuryAssetsPercentToSandboxAsset() 
        external
        onlySandboxes 
        returns(uint256 totalStableAmount)
    {
        // For GAS safe
        address sandbox1 = ubdNetwork.sandbox1;
        address treasury = ubdNetwork.treasury;
        address sandbox2 = ubdNetwork.sandbox2;
        uint256 etherFromTreasuryAmount;
        uint256 topupPercent;
        address[] memory path = new address[](2);
        
        // authentificate
        if (msg.sender == sandbox1){
            path[1] = ISandbox1(sandbox1).EXCHANGE_BASE_ASSET();
            topupPercent = ITreasury(treasury).SANDBOX1_REDEEM_PERCENT();
            
        } else if (msg.sender == sandbox2) {
            path[1] = ISandbox2(sandbox2).SANDBOX_2_BASE_ASSET();
            topupPercent = ITreasury(treasury).SANDBOX2_TOPUP_PERCENT();
            require (ITreasury(treasury).isReadyForTopupSandBox2(), "Not ready for topup Sandbox2");
        }

        etherFromTreasuryAmount = ITreasury(treasury).sendEtherForRedeem(topupPercent);
        Market memory mrkt = _getMarketForAsset(path[1]);
     
        // Swap Native Asset 
        path[0] = IMarketAdapter(mrkt.marketAdapter).WETH();
        uint256 notLessThen = _getNotLessThenEstimate(etherFromTreasuryAmount, path, mrkt.slippage);
        totalStableAmount =  IMarketAdapter(
            mrkt.marketAdapter
        ).swapExactNativeInToERC20Out{value: etherFromTreasuryAmount}(
            etherFromTreasuryAmount, 
            notLessThen, 
            path,
            msg.sender,
            block.timestamp
        );

        // Swap ERC20 Treasure assets
        uint256[] memory sended = new uint256[](ubdNetwork.treasuryERC20Assets.length);
        sended = ITreasury(ubdNetwork.treasury).sendERC20ForSwap(mrkt.marketAdapter, topupPercent);
        for (uint256 i; i < sended.length; ++ i){
            path[0] = ubdNetwork.treasuryERC20Assets[i].asset;
            notLessThen = _getNotLessThenEstimate(sended[i], path, mrkt.slippage);
            totalStableAmount += IMarketAdapter(mrkt.marketAdapter).swapExactERC20InToERC20Out(
                sended[i],
                notLessThen, 
                path,
                msg.sender,
                block.timestamp
            );

        }
    }

    /// @notice Swap Sandbox1 (usdt) or  Sandbox2 (dai) asset to Treasury assets
    /// @dev only called from Sandboxes
    function swapExactBASEInToTreasuryAssets(uint256 _amountIn, address _baseAsset) 
        external 
        onlySandboxes 
    {
        // Prepare all parameters: percenet of native and erc20 assets for swap
        // Call adapter swap methods
        
        Market memory mrkt = _getMarketForAsset(address(0)); 
        // 2. Transfer all  amount of in asset from sandbox1 to adapter
        TransferHelper.safeTransferFrom(
            _baseAsset, 
            msg.sender, 
            mrkt.marketAdapter, 
            _amountIn 
        );
        // 3. Call Swap
        address[] memory path = new address[](2);
        path[0] = _baseAsset;
        path[1] = IMarketAdapter(mrkt.marketAdapter).WETH(); // Native asset
        // 1. First define shares of Native asset 
        uint256 inSwap = _amountIn * _getNativeTreasurePercent() / 100;
        uint256 notLessThen = _getNotLessThenEstimate(inSwap, path, mrkt.slippage);
        IMarketAdapter(mrkt.marketAdapter).swapExactERC20InToNativeOut(
            inSwap,
            notLessThen, 
            path,
            ubdNetwork.treasury,
            block.timestamp
        );

        // 4. Call Swap for other Treasuru assets
        address _asset; // GAS safe
        for (uint256 i; i < ubdNetwork.treasuryERC20Assets.length; ++ i){
            _asset = ubdNetwork.treasuryERC20Assets[i].asset;
            mrkt = _getMarketForAsset(_asset); 
            inSwap = _amountIn * (ubdNetwork.treasuryERC20Assets[i].percent * PERCENT_DENOMINATOR) / (100 * PERCENT_DENOMINATOR);
            path[0] = _baseAsset;
            path[1] = _asset; 
            notLessThen = _getNotLessThenEstimate(inSwap, path, mrkt.slippage);
            IMarketAdapter(mrkt.marketAdapter).swapExactERC20InToERC20Out(
                inSwap,
                notLessThen, 
                path,
                ubdNetwork.treasury,
                block.timestamp
            );
        }
    }

    
    ///////////////////////////////////////////////////////////
    ///////    Admin Functions        /////////////////////////
    ///////////////////////////////////////////////////////////
    function setMarketParams(address _asset, Market memory _market) external onlyOwner {
        require(
            _market.marketAdapter != address(0) &&
            _market.oracleAdapter != address(0) &&
            _market.slippage <= DEFAULT_SLIPPAGE_MAX,
            'No zero address'
        );

        if (_market.slippage == 0) {
           _market.slippage = DEFAULT_SLIPPAGE;    
        }
        markets[_asset] = _market;
    }

    function setSandbox1(address _adr) 
        external 
        onlyOwner 
    {
        ubdNetwork.sandbox1 = _adr;
    }
    function setSandbox2(address _adr) 
        external 
        onlyOwner 
    {
        ubdNetwork.sandbox2 = _adr;
    }

    function setTreasury(address _adr) 
        external 
        onlyOwner 
    {
        ubdNetwork.treasury = _adr;
    }

    function addERC20AssetToTreasury(AsssetShare memory _assetShare) 
        external 
        onlyOwner
        afterTimeLock(keccak256(abi.encode(_assetShare.asset, _assetShare.percent))) 
    {
        for (uint256 i; i < ubdNetwork.treasuryERC20Assets.length; ++ i){
            require(ubdNetwork.treasuryERC20Assets[i].asset != _assetShare.asset, 'Asset already exist');
        }
        ubdNetwork.treasuryERC20Assets.push(_assetShare);
        
        //check sum percent
        uint8 sumPercent;
        for (uint256 i; i < ubdNetwork.treasuryERC20Assets.length; ++ i){
            sumPercent += ubdNetwork.treasuryERC20Assets[i].percent;
        }
        require(sumPercent + MIN_NATIVE_PERCENT <= 100, 'Percent sum too much');
        _rebalance();
    }

    function editAssetShares(uint8[] calldata _percentShares)
        external
        onlyOwner
    {
        uint256 erc20AssetsCount = ubdNetwork.treasuryERC20Assets.length;
        require(_percentShares.length == erc20AssetsCount, 'Arrays len mismatch');
        uint8 sumPercent;
        for (uint256 i; i < _percentShares.length; ++ i){
            sumPercent += _percentShares[i];
        }
        require(sumPercent + MIN_NATIVE_PERCENT <= 100, 'Percent sum too much');

        for (uint256 i; i < erc20AssetsCount; ++ i){
            ubdNetwork.treasuryERC20Assets[i].percent = _percentShares[i];
        }
        _rebalance();

    }

    function removeERC20AssetFromTreasury(address _erc20) 
        external 
        onlyOwner 
    {
        require(
            IERC20(_erc20).balanceOf(ubdNetwork.treasury) == 0, 
            'Cant remove asset with non zero balance'
        );

        uint256 assetsCount = ubdNetwork.treasuryERC20Assets.length;
        for (uint256 i; i < assetsCount; ++ i){
            if (ubdNetwork.treasuryERC20Assets[i].asset == _erc20){
                // if not last then replace last  to this position
                if (i != assetsCount - 1){
                    ubdNetwork.treasuryERC20Assets[i] = ubdNetwork.treasuryERC20Assets[assetsCount-1];
                }
                ubdNetwork.treasuryERC20Assets.pop();
            } 
        }
    }

     function setTeamAddress(address _adr) 
        external 
        onlyOwner 
    {
        require(_adr != address(0), 'Cant be zero address');
        UBD_TEAM_ADDRESS = _adr;
    }

    function rebalance() external payable onlyOwner {
        _rebalance();    
    }
    
    ///////////////////////////////////////////////////////////////
    

    function getAmountOut(
        uint amountIn, 
        address[] memory path
    ) public view returns (uint256 amountOut)
    {
        Market memory mrkt = _getMarketForAsset(path[path.length - 1]); 
        return IOracleAdapter(mrkt.oracleAdapter).getAmountOut(amountIn, path);

    }
    function getCollateralLevelM10() external view returns(uint256 level){
        address sandbox1 = ubdNetwork.sandbox1; //GAS safe
        // Sandbox 1
        address sandbox1BaseAsset = ISandbox1(sandbox1).EXCHANGE_BASE_ASSET();
        uint256 s1BalanceInBaseAsset = IERC20(sandbox1BaseAsset).balanceOf(
            ubdNetwork.sandbox1
        );

        // bring balance to common decimals (18 as native chain token)
        s1BalanceInBaseAsset = _bringAmountToNativeDecimals(
            sandbox1BaseAsset, s1BalanceInBaseAsset
        );

        uint256 ubdTotalSupply = IERC20Metadata(
            ISandbox1(sandbox1).ubdTokenAddress()
        ).totalSupply();
        
        // bring supply to common decimals (18 as native chain token)
        ubdTotalSupply = _bringAmountToNativeDecimals(
            ISandbox1(sandbox1).ubdTokenAddress(), ubdTotalSupply
        );

        level =  (
            s1BalanceInBaseAsset + 
            getBalanceInStableUnits(ubdNetwork.treasury, treasuryERC20Assets()) *
            10**NATIVE_TOKEN_DECIMALS
        ) * 10 / ubdTotalSupply;

    }

    function getBalanceInStable18(address _holder, address[] memory _assets) 
        public 
        view 
        returns(uint256 stableUnitsNoDecimal)
    {
        address sandbox1BaseAsset = ISandbox1(ubdNetwork.sandbox1).EXCHANGE_BASE_ASSET();
        uint256 originalBalance;
        uint256 erc20BalanceCommonDecimals;
        address[] memory path = new address[](2);
        
        // First calc _holder erc20 balance in base assets but with native decimals for safe precision
        for (uint256 i; i < _assets.length; ++ i){
            //bring to a common denominator
            path[0] = _assets[i]; 
            path[1] = sandbox1BaseAsset;
            originalBalance = getAmountOut(
                IERC20(_assets[i]).balanceOf(_holder), 
                path
            );
            erc20BalanceCommonDecimals += _bringAmountToNativeDecimals(
                sandbox1BaseAsset,
                originalBalance
            );
        }

        
        // Calc _holder native balance
        Market memory mrkt = _getMarketForAsset(address(0)); 
        path[0] = IMarketAdapter(mrkt.oracleAdapter).WETH();
        path[1] = sandbox1BaseAsset;
        
        
        uint256 tBalanceNative = _holder.balance;
        originalBalance = getAmountOut(tBalanceNative, path);
        tBalanceNative = _bringAmountToNativeDecimals(
            sandbox1BaseAsset,
            originalBalance
        );
        // Sum and devide for get balance in Stable coin units
        stableUnitsNoDecimal = (erc20BalanceCommonDecimals + tBalanceNative);
    }
    
    

    function getBalanceInStableUnits(address _holder, address[] memory _assets) 
        public 
        view 
        returns(uint256 stableUnitsNoDecimal)
    {
         stableUnitsNoDecimal = getBalanceInStable18(_holder, _assets)/ 10 ** NATIVE_TOKEN_DECIMALS;
    }
    
    function treasuryERC20Assets() public view returns(address[] memory assets) {
        assets = new address[](ubdNetwork.treasuryERC20Assets.length);
        for (uint256 i; i < ubdNetwork.treasuryERC20Assets.length; ++ i) {
            assets[i] = ubdNetwork.treasuryERC20Assets[i].asset;
        }
        
    }

    // 1% = 100 bp
    function getActualAssetsSharesM100() public  view returns(ActualShares[] memory sharesM100, uint256 trBalance) {
        // Gas Save local vars
        address treasury = ubdNetwork.treasury;
        address baseAsset = ISandbox1(ubdNetwork.sandbox1).EXCHANGE_BASE_ASSET();
        uint256 treasuryBalanceWithNativeDecimals = getBalanceInStable18(
            ubdNetwork.treasury, 
            treasuryERC20Assets()
        );
        //debug
        trBalance = treasuryBalanceWithNativeDecimals;

        address[] memory path = new address[](2);
        sharesM100 = new ActualShares[](ubdNetwork.treasuryERC20Assets.length + 1);
        uint256 assetBalance;
        Market memory mrkt = _getMarketForAsset(address(0)); 
        for (uint256 i; i < sharesM100.length; ++ i) {
            path[1] = baseAsset;
            if (i != sharesM100.length - 1) {
                // ERC20 assets
                path[0] = ubdNetwork.treasuryERC20Assets[i].asset;
                
                sharesM100[i].asset = path[0];
                // balance in asset
                assetBalance = IERC20(path[0]).balanceOf(treasury);
                if (assetBalance > 0) {
                    (sharesM100[i].actualPercentPoint, sharesM100[i].excessAmount) = calcAssetShareAndExcess(
                        assetBalance,
                        path,
                        uint256(ubdNetwork.treasuryERC20Assets[i].percent),
                        treasuryBalanceWithNativeDecimals
                    );
                }
            } else {
                //Native asset
                path[0] = IMarketAdapter(mrkt.oracleAdapter).WETH();
                assetBalance = treasury.balance;
                if (assetBalance > 0) {
                    (sharesM100[i].actualPercentPoint, sharesM100[i].excessAmount) = calcAssetShareAndExcess(
                        assetBalance,
                        path,
                        _getNativeTreasurePercent(),
                        treasuryBalanceWithNativeDecimals
                    );
                }
            }
            
        }
    }

    
    function getUBDNetworkTeamAddress() external view returns(address) {
        return UBD_TEAM_ADDRESS;
    }
    function getUBDNetworkInfo() external view returns(UBDNetwork memory) {
        return ubdNetwork;
    }

    function calcAssetShareAndExcess(
        uint256 _actualBalance, 
        address[] memory _path,
        uint256 _nominalShare,
        uint256 _treasuryBalanceWithNativeDecimals
    ) public view returns (uint256 share, uint256 exceed) {
        uint256 assetBalanceInBaseAsset = getAmountOut(
            _actualBalance, 
            _path
        );
        // balance in BASE asset but with Native Decimals
        uint256 factAssetBalanceInBaseAssetNativeDecimals = _bringAmountToNativeDecimals(_path[1], assetBalanceInBaseAsset);
        uint256 nominalAssetBalanceInBaseAssetNativeDecimals = 
            _treasuryBalanceWithNativeDecimals * _nominalShare * PERCENT_DENOMINATOR/ (100 * PERCENT_DENOMINATOR); 
        share  = factAssetBalanceInBaseAssetNativeDecimals * PERCENT_DENOMINATOR / _treasuryBalanceWithNativeDecimals;
        
        // Case when owner want to remove asset and  set it share=0 before 
        if (_nominalShare == 0) {
            exceed = _actualBalance;
            return (share, exceed);
        }

        uint256 diffInStableNativeDecimals;
        address a0 = _path[0];
        if (nominalAssetBalanceInBaseAssetNativeDecimals < factAssetBalanceInBaseAssetNativeDecimals) {
            diffInStableNativeDecimals =
                factAssetBalanceInBaseAssetNativeDecimals - nominalAssetBalanceInBaseAssetNativeDecimals;
            _path[0] = _path[1];
            _path[1] = a0;
            exceed = getAmountOut(
                diffInStableNativeDecimals  * 10 ** IERC20Metadata(_path[0]).decimals() / 10**18, 
                _path
            );  
        }
    }
    
    function isInitialized() public view returns(bool){
        UBDNetwork memory _ubdnetwork = ubdNetwork;
        if (_ubdnetwork.sandbox1 != address(0) &&
            _ubdnetwork.sandbox2 != address(0) &&
            _ubdnetwork.treasury != address(0) &&
            _ubdnetwork.treasuryERC20Assets.length > 0 
        ) {
            return true; 
        }
    }
/////////////////////////////////////////////////////////////////////////////////////
    function _rebalance() internal {
        address treasury = ubdNetwork.treasury;
        ActualShares[] memory actshrs = new ActualShares[](
            ubdNetwork.treasuryERC20Assets.length + 1
        );
        (actshrs, ) = getActualAssetsSharesM100();
        
        uint256 notLessThen;

        address[] memory path = new address[](2);
        path[1] = ISandbox1(ubdNetwork.sandbox1).EXCHANGE_BASE_ASSET();
        for (uint256 i; i < actshrs.length; ++ i){
            if (actshrs[i].asset != address(0) && actshrs[i].excessAmount > 0){
                // Sell ERC20
                path[0] = actshrs[i].asset;
                Market memory mrkt = _getMarketForAsset(path[0]); 
                // Transfer erc20 asset to MarketAdapter for Swap from Treasury
                ITreasury(ubdNetwork.treasury).sendOneERC20ForSwap(
                    mrkt.marketAdapter, 
                    actshrs[i].asset, 
                    actshrs[i].excessAmount
                );
                notLessThen = _getNotLessThenEstimate(actshrs[i].excessAmount, path, mrkt.slippage);
                IMarketAdapter(mrkt.marketAdapter).swapExactERC20InToERC20Out(
                    actshrs[i].excessAmount,
                    notLessThen, 
                    path,
                    ubdNetwork.sandbox1,
                    block.timestamp
                );
            } else if (actshrs[i].asset == address(0) && actshrs[i].excessAmount > 0) {
                // Sel Native
                Market memory mrkt = _getMarketForAsset(path[0]); 
                path[0] = IMarketAdapter(mrkt.marketAdapter).WETH();
                notLessThen = _getNotLessThenEstimate(actshrs[i].excessAmount, path, mrkt.slippage);
                // First need send ether from Treasury to this contract
                uint256 etherPercent = actshrs[i].excessAmount * 1000000 / treasury.balance;
                uint256 etherFromTreasuryAmount = ITreasury(treasury).sendEtherForRedeem(etherPercent);
                notLessThen = _getNotLessThenEstimate(etherFromTreasuryAmount, path, mrkt.slippage);
                IMarketAdapter(
                    mrkt.marketAdapter
                ).swapExactNativeInToERC20Out{value: etherFromTreasuryAmount}(
                    etherFromTreasuryAmount, 
                    notLessThen, 
                    path,
                    ubdNetwork.sandbox1,
                    block.timestamp
                );
            }
        }

    }

    function _getNativeTreasurePercent() internal view returns(uint256) {
        uint8 sumPercent;
        for (uint256 i; i < ubdNetwork.treasuryERC20Assets.length; ++ i){
            sumPercent += ubdNetwork.treasuryERC20Assets[i].percent;
        }
        return uint256(100 - sumPercent);

    }

    function _bringAmountToNativeDecimals(address _erc20, uint256 _amount) 
        internal 
        view 
        returns(uint256 amount)
    {
        uint8 decimals = IERC20Metadata(_erc20).decimals(); 
        if (decimals < NATIVE_TOKEN_DECIMALS) {
            amount = _amount * 10 ** (NATIVE_TOKEN_DECIMALS - decimals);
        } else if (decimals > NATIVE_TOKEN_DECIMALS) {
            amount = _amount / 10 ** (decimals - NATIVE_TOKEN_DECIMALS);
        } else {
            amount = _amount;
        }

    }

    function _getMarketForAsset(address _asset) internal view returns(Market memory market) {
        market = markets[_asset];
        if (market.slippage == 0) {
            market.slippage == DEFAULT_SLIPPAGE;
        }
    }

    function _getNotLessThenEstimate(uint256 _amountIn, address[] memory _path, uint256 _slippagePercentPoints) 
        internal 
        view 
        returns (uint256 notLessThen) 
    {
        uint256 out = getAmountOut(_amountIn, _path); 
        notLessThen = out - out * _slippagePercentPoints / 10000;  
    }  
}
