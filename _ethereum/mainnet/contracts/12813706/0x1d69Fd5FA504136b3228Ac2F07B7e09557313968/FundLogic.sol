// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AssetOracle.sol";
import "./FundShares.sol";
import "./FundLibrary.sol";
import "./FundDeployer.sol";
import "./IParaswapAugustus.sol";

contract FundLogic is FundShares, FundLibrary{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public deployer;
    address public manager;
    address public oracle;

    string public fundName;
    string public managerName;

    uint256 public constant MAX_ASSETS = 20;

    mapping(address => uint256) private arbSender;
    mapping(address => uint256) private arbOrigin;

    address public depositAsset;
    uint8 public depositAssetDecimals;
    address[] public activeAssets;
    mapping(address => bool) public isActiveAsset;

    bool private wasInitialized = false;
    bool private firstDeposit;
    bool public managerFeesEnabled;

    uint256 public sharePriceLastFee;
    uint256 public timeLastFee;
    uint256 public PERFORMANCE_FEE;

    address public buybackVault;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;

    uint256 public minDeposit;
    uint256 public maxDeposit;

    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized: Only manager");
        _;
    }

    modifier arbProtection() {
        require(arbSender[msg.sender] != block.number, "ARB PROTECTION: msg.sender");
        require(arbOrigin[tx.origin] != block.number, "ARB PROTECTION: tx.origin");
        arbSender[msg.sender] = block.number;
        arbOrigin[tx.origin] = block.number;
        _;
    }

    modifier onlyProxy() {
        bool _genesisFlag;
        assembly {
            // solium-disable-line
            _genesisFlag := sload(0xa7e8032f370433e2cd75389d33b731b61bee456da1b0f7117f2621cbd1fdcf7a)
        }
        require(_genesisFlag == true, "Genesis Logic: Only callable by proxy");
        _;
    }

    modifier depositLimit(uint256 _amount) {
        if(minDeposit > 0) {
            require(_amount > minDeposit, "Deposit too small");
        }

        if(maxDeposit > 0) {
            require(_amount < maxDeposit, "Deposit too big");
        }

        _;
    }

    function init(
        address _oracle,
        address _deployer,
        address _manager,
        string memory _fundName,
        string memory _managerName,
        address _depositAsset,
        uint256 _performanceFee,
        address _paraswapProxy,
        address _paraswapAugustus,
        address _bbvault,
        uint256 _min,
        uint256 _max
    ) public onlyProxy{
        require(!wasInitialized, "Fund already initialized");
        require(_performanceFee <= 10000, "Performance fee too big");
        wasInitialized = true;

        oracle = _oracle;
        deployer = _deployer;
        manager = _manager;
        fundName = _fundName;
        managerName = _managerName;

        _addActiveAsset(_depositAsset);
        depositAsset = _depositAsset;
        depositAssetDecimals = uint8(ERC20(depositAsset).decimals()); // For USDT's non ERC20 compliant functions

        firstDeposit = false;
        timeLastFee = 0;
        PERFORMANCE_FEE = _performanceFee;
        managerFeesEnabled = true;

        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;

        buybackVault = _bbvault;

        minDeposit = _min;
        maxDeposit = _max;

        _initializeShares("BotOcean Fund", "BOF");
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getName() external view returns (string memory) {
        return fundName;
    }

    function getManagerName() external view returns (string memory) {
        return managerName;
    }

    function getBuybackFee() external view returns (uint256,uint256) {
        return FundDeployer(deployer).getBuybackFee();
    }

    function getVersion() external pure returns (string memory) {
        return "v1.0";
    }

    function getIsActiveAsset(address _asset) external view returns (bool) {
        return isActiveAsset[_asset];
    }

    function getActiveAssetsLength() external view returns (uint) {
        return activeAssets.length;
    }

    // Only Manager can call this function to get new paraswap addresses
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake ParaSwap contract and steal funds
    function upgradeParaswap() external onlyManager {
        (address _aug, address _proxy) = FundDeployer(deployer).getParaswapAddresses();

        emit ParaswapUpgrade(
            PARASWAP_TOKEN_PROXY,
            PARASWAP_AUGUSTUS,
            _proxy,
            _aug
        );

        PARASWAP_AUGUSTUS = _aug;
        PARASWAP_TOKEN_PROXY = _proxy;
    }

    // Only Manager can call this function to get new buyback addresse
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake buyback contract and steal funds
    function upgradeBuyBackVault() external onlyManager {
        address _newVault = FundDeployer(deployer).getBuybackVault();
        emit BuybackVaultUpgrade(
            buybackVault,
            _newVault
        );
        buybackVault = _newVault;
    }

    // Only Manager can call this function to get new oracle addresse
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake oracle contract and steal funds
    function upgradeOracle() external onlyManager {
        address _newOracle = FundDeployer(deployer).getOracle();
        emit OracleUpgrade(
            oracle,
            _newOracle
        );
        oracle = _newOracle;
    }

    function changeManager(address _manager, string memory _managerName) external onlyManager {
        emit ManagerUpdated(manager, managerName, _manager, _managerName);
        manager = _manager;
        managerName = _managerName;
    }

    // Sefety function for disabling manager fees in case of emergency withdrawls
    // Manager should only set this to false if _settleFees() fails
    function setManagerFeeEnabled(bool _newStatus) external onlyManager {
        managerFeesEnabled = _newStatus;
    }

    function addActiveAsset(address _asset) external onlyManager {
        _addActiveAsset(_asset);
    }

    function removeActiveAsset(address _asset) external onlyManager {
        address _tempDA  = depositAsset;
        require(_asset != _tempDA, "deposit asset");
        _removeActiveAsset(_asset);
        emit AssetRemoved(_asset);
    }

    function changeDepositLimits(uint256 _minD, uint256 _maxD) external onlyManager {
        minDeposit = _minD;
        maxDeposit = _maxD;
    }

    function changeMinDeposit(uint256 _minDeposit) external onlyManager {
        minDeposit = _minDeposit;
    }

    function changeMaxDeposit(uint256 _maxDeposit) external onlyManager {
        maxDeposit = _maxDeposit;
    }

    function _addActiveAsset(address _asset) internal {
        if(!isActiveAsset[_asset]){
            require(AssetOracle(oracle).isSupportedAsset(_asset), "Asset not supported");
            require(activeAssets.length < MAX_ASSETS, "Max assets reached");
            activeAssets.push(_asset);
            isActiveAsset[_asset] = true;
            emit AssetAdded(_asset);
        }
    }

    function _removeActiveAsset(address _asset) internal {
        if(isActiveAsset[_asset]) {
            require(ERC20(_asset).balanceOf(address(this)) <= 100, "Cannot remove asset with balance");

            isActiveAsset[_asset] = false;
            uint256 _length = activeAssets.length;
            for (uint256 i = 0; i < _length; i++) {
                if (activeAssets[i] == _asset) {
                    if (i < _length - 1) {
                        activeAssets[i] = activeAssets[_length - 1];
                    }
                    activeAssets.pop();
                    break;
                }
            }
        }
    }

    function _getAssetsBalances() internal view returns (uint256[] memory) {
        uint256 _length = activeAssets.length;
        uint256[] memory _bal = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _bal[i] = (ERC20(activeAssets[i]).balanceOf(address(this)));
        }
        
        return _bal;
    }

    function totalValueUSD() public view returns (uint256) {
        uint256[] memory _balances = _getAssetsBalances();
        uint256 _aumUSD = AssetOracle(oracle).aum(activeAssets, _balances);
        return _aumUSD;
    }

    function totalValueDepositAsset() public view returns (uint256) {
        uint256[] memory _balances = _getAssetsBalances();
        uint256 _aumDepositAsset = AssetOracle(oracle).aumDepositAsset(depositAsset, activeAssets, _balances);
        return _aumDepositAsset;
    }

    function sharePriceUSD() public view returns (uint256) {
        uint256 _valueUSD = totalValueUSD(); // 8 decimals
        uint256 _totalSupply = totalSupply(); // 18 decimals

        if(_valueUSD == 0 || _totalSupply == 0) {
            return 0;
        }

        return _valueUSD.mul(1e18).div(_totalSupply);
    }

    function deposit(uint256 _amount) external onlyProxy arbProtection depositLimit(_amount) returns (uint256){
        // Dont't mint fees on first deposit since we do not know the share of a price
        if(firstDeposit){
            _settleFees();
        }

        uint256 depositAssetValue = totalValueDepositAsset();
        uint256 totalShares = totalSupply();

        uint256 _balBefore = ERC20(depositAsset).balanceOf(address(this));
        ERC20(depositAsset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _balAfter = ERC20(depositAsset).balanceOf(address(this));

        // Extra protection
        require(_balAfter.sub(_balBefore) >= _amount, "Incorrect deposit transfer amount");

        uint256 sharesToMint;
        // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
        // This does the conversion
        // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
        if(totalShares == 0){
            sharesToMint = _amount.mul(1e18);
            sharesToMint = sharesToMint.div(10**uint256(depositAssetDecimals));
        } else {
            uint256 _amount18 = _amount.mul(1e18);
            _amount18 = _amount18.div(10**uint256(depositAssetDecimals));
            uint256 _value18 = depositAssetValue.mul(1e18);
            _value18 = _value18.div(10**uint256(depositAssetDecimals));
            sharesToMint = _amount18.mul(totalShares).div(_value18);
        }

        _mint(msg.sender, sharesToMint);

        if(!firstDeposit){
            firstDeposit = true;
            sharePriceLastFee = sharePriceUSD();
        }

        emit Deposit(
            msg.sender,
            _amount,
            sharesToMint,
            sharePriceUSD(),
            block.timestamp
        );

        return sharesToMint;
    }

    function withdraw(uint256 _sharesAmount) external onlyProxy arbProtection {
        require(balanceOf(msg.sender) >= _sharesAmount, "Not enough shares");

        // Dont't mint fees on first deposit since we do not know the share of a price
        if(firstDeposit){
            _settleFees();
        }

        // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
        // This does the conversion
        // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
        uint256 _ownership = _sharesAmount.mul(1e18).div(totalSupply());

        _burn(msg.sender, _sharesAmount);

        uint256 _length = activeAssets.length;
        for(uint256 i = 0; i < _length; i++) {
            uint256 _totalBal = ERC20(activeAssets[i]).balanceOf(address(this));
            // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
            // This does the conversion
            // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
            uint256 _withdrawAmount = _totalBal.mul(_ownership).div(1e18);

            if(_withdrawAmount > 0) {
                ERC20(activeAssets[i]).safeTransfer(msg.sender, _withdrawAmount);
            }               
        }

        emit Withdraw(
            msg.sender,
            _sharesAmount,
            sharePriceUSD(),
            block.timestamp
        );
    }

    function _swap(address _src, address _dst, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) internal returns (uint256){
        require(ERC20(_src).balanceOf(address(this)) >= _amount, "Not enough tokens");
        uint256 _before = ERC20(_dst).balanceOf(address(this));
        // TODO: SWAP
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, 0);
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, _amount);

        IParaswapAugustus.SellData memory swapData = IParaswapAugustus.SellData({
            fromToken: _src,
            fromAmount: _amount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: payable(address(this)),
            referrer: "BOTOCEAN",
            useReduxToken: false,
            path: _path
        });

        IParaswapAugustus(PARASWAP_AUGUSTUS).multiSwap(swapData);

        uint256 _after = ERC20(_dst).balanceOf(address(this));

        emit Swap(
            _src,
            _dst,
            _amount,
            _after.sub(_before),
            block.timestamp
        );

        return _after.sub(_before);
    }

    // The path will be made available from Paraswap's param transaction builder API.
    function swap(address _src, address _dst, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) external onlyManager {
        require(_src != _dst, "same asset");
        require(isActiveAsset[_src], "Unknown asset");
        if(!isActiveAsset[_dst]) {
            _addActiveAsset(_dst);
        }
        uint256 _swapAmount = _amount;
        uint256 _myBal = ERC20(_src).balanceOf(address(this));
        if(_myBal < _swapAmount) {
            _swapAmount = _myBal;
        }

        // Other Checks

        // Swap
        _swap(_src, _dst, _swapAmount, _toAmount, _expectedAmount, _path);
    }

    function _settleFees() internal {
        if(managerFeesEnabled && PERFORMANCE_FEE > 0){
            uint256 feeWaitTime = FundDeployer(deployer).getFeeWaitPeriod();
            uint256 _currentSharePrice = sharePriceUSD();
            uint256 _totalSupply = totalSupply();

            uint256 _buybackFee;
            uint256 _buybackFeeMax;
            (_buybackFee, _buybackFeeMax) = FundDeployer(deployer).getBuybackFee();

            if(timeLastFee.add(feeWaitTime) > block.timestamp) {
                return;
            }

            if(_currentSharePrice == 0 || _currentSharePrice < sharePriceLastFee) {
                return;
            }

            // Calculate fees
            uint256 profitUSD = _currentSharePrice.sub(sharePriceLastFee).mul(_totalSupply).div(1e18);
            if(profitUSD < 100000) { // If profit smaller than $0.001, don't mint fees
                return;
            }
            uint256 managerFeeUSD = profitUSD.mul(PERFORMANCE_FEE).div(10000);
            uint256 managerFeeShares = managerFeeUSD.mul(1e18).div(_currentSharePrice);
            uint256 buybackShares = managerFeeShares.mul(_buybackFee).div(_buybackFeeMax);
            managerFeeShares = managerFeeShares.sub(buybackShares);

            // Mint fees
            _mint(buybackVault, buybackShares);
            _mint(manager, managerFeeShares);

            // Emit event
            uint256 newSharePrice = sharePriceUSD();
            emit FeeMinted(
                sharePriceLastFee,
                newSharePrice,
                profitUSD,
                buybackShares,
                managerFeeShares,
                block.timestamp
            );

            // Update values
            sharePriceLastFee = newSharePrice;
            timeLastFee = block.timestamp;
        }
    }

    function settleFees() external onlyManager {
        require(firstDeposit, "Cannot mint fees before first deposit");
        _settleFees();
    }

    function getFundLogic() public view returns (address) {
        address _impl;
        assembly {
            // solium-disable-line
            _impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }

        return _impl;
    }
}