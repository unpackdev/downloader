// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
//import "./console.sol";


interface ILSDVaultV2 {
    function deposit(address lsd, uint256 amount) external;
    function swapperAddress() external returns(address);
    function darknetAddress() external returns(address);
    function balanceInUnderlying() external view returns(uint256);
    function lsdConfigs(address lsd) external view returns(uint256 targetWeightBps, uint256 weightCapBps, uint256 absoluteCapEth);
}

interface IDarknet {
    function checkPrice(address lsd) external view returns (uint256);
}

interface IunshETH {
    function timelock_address() external view returns (address);
}

interface IVdAmm {
    function getDepositFee(uint256 lsdAmountIn, address lsd) external returns(uint256, uint256);
}

interface FRXETH {
    function submitAndDeposit(address recipient) payable external;
}

interface SFRXETH {
    function deposit(uint256 assets, address receiver) external;
}

interface RETH {
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) payable external;
}

interface IANKRDeposits {
    function stakeAndClaimAethC() payable external;
}

interface ISWETH {
    function deposit() payable external;
}

interface IRocketDepositPool {
    function deposit() external payable;
    function getMaximumDepositAmount() external view returns (uint256);
}

interface IRocketSettings {
    function getDepositEnabled() external view returns (bool);
}

interface IWETH is IERC20{
    function deposit() payable external;
    function withdraw(uint wad) external;
}

interface IWStETH is IERC20{
    function wrap(uint256 _stETHAmount) external;
}

interface IStaderDeposit { 
    function deposit(address receiver) external payable; 
}

contract unshETHZapv2 is ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_PATH_ID = 11;

    address public constant wstETHAddress = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant frxETHMinterAddress = 0xbAFA44EFE7901E04E39Dad13167D089C559c1138;
    address public constant frxETHAddress = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant sfrxETHAddress = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant rETHAddress = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant cbETHAddress = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant stEthAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant ankrETHAddress = 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb;
    address public constant ankrDepositsAddress = 0x84db6eE82b7Cf3b47E8F19270abdE5718B936670;
    address public constant swETHAddress = 0xf951E335afb289353dc249e82926178EaC7DEd78;

    address public constant rocketDepositPoolAddress = 0xDD3f50F8A6CafbE9b31a427582963f465E745AF8;

    address public constant staderDepositAddress = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;
    address public constant ethxAddress = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;
    address public immutable lsdVaultAddressV2; // 0x00..;
    address public immutable unshETHAddressV2; //0x00...;

    ISwapRouter public uniswapRouterV3 = ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));
    uint24 public constant POOLFEE = 500; // pool fee to use uniswapv3. for now its set to 0.05% as default

    address public vdAmmAddress;
    address public darknetAddress;

    mapping (uint256 => address) public swapPathIdToAddress;
    mapping (uint256 => address) public mintPathIdToAddress;
    mapping (address => uint256) public lsdToMintPathId;

    event DepositLsd(address indexed sender, address lsdAddress, uint256 depositAmount, uint256 depositFee, uint256 protocolFee, uint256 unshETHMinted);
    event DepositEth(address indexed sender, uint256 ethAmount, uint256 pathId);

    /*
    ============================================================================
    Constructor
    ============================================================================
    */
    constructor(address _unshETHAddressV2) {

        unshETHAddressV2 = _unshETHAddressV2;

        lsdVaultAddressV2 = IunshETH(unshETHAddressV2).timelock_address();
        vdAmmAddress = ILSDVaultV2(lsdVaultAddressV2).swapperAddress();
        darknetAddress = ILSDVaultV2(lsdVaultAddressV2).darknetAddress();

        //give infinite approval for the lsd vault to spend the wstETH, sfrxETH, rETH, and cbETH
        TransferHelper.safeApprove(wstETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(sfrxETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(rETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(cbETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(wethAddress, lsdVaultAddressV2, type(uint256).max);

        //give infinite approval for the lsd vault to spend the ankrETH and swETH
        TransferHelper.safeApprove(ankrETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(swETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(ethxAddress, lsdVaultAddressV2, type(uint256).max);

        //approve weth and uniswap to facilitate swapping into lsds
        TransferHelper.safeApprove(wethAddress, address(uniswapRouterV3), type(uint256).max);

        //approvals to facilitate wrapping of frxETH and stETH
        TransferHelper.safeApprove(frxETHAddress, sfrxETHAddress, type(uint256).max);
        TransferHelper.safeApprove(wstETHAddress, stEthAddress, type(uint256).max);

        //set up swap path ids

        lsdToMintPathId[wstETHAddress] = 0; // mint wstETH
        lsdToMintPathId[sfrxETHAddress] = 1; // mint sfrxETH
        swapPathIdToAddress[2] = cbETHAddress; // 2 -> swap for cbETH
        swapPathIdToAddress[3] = rETHAddress; // 3 -> swap for rETH
        swapPathIdToAddress[4] = wstETHAddress;  // 4 -> swap for wstETH
        swapPathIdToAddress[5] = frxETHAddress; // 5 -> swap for frxETH (sfrxETH not liquid)
        lsdToMintPathId[rETHAddress] = 6; // swap for cbETH
        lsdToMintPathId[wethAddress] = 7; // swap for rETH
        lsdToMintPathId[ankrETHAddress] = 8; // swap for rETH
        lsdToMintPathId[swETHAddress] = 9; // swap for swETH
        swapPathIdToAddress[10] = swETHAddress; // 10 -> swap for swETH.. //no swap path for ankrETH as limited liquidity on uniswap
        lsdToMintPathId[ethxAddress] = 11; // swap for ETHx
    }

    /*
    ============================================================================
    ETH -> LSD deposit functions
    ============================================================================
    */

    function _mint_sfrxETH(uint256 ethAmount) internal {
        // Mint sfrxETH
        FRXETH(frxETHMinterAddress).submitAndDeposit{value:ethAmount}(address(this));
        // Get balance of sfrxETH minted
        uint256 sfrxETHBalance = IERC20(sfrxETHAddress).balanceOf(address(this));
        // Check to see that the balance minted is greater than 0
        require(sfrxETHBalance > 0, 'sfrxETH minting failed');
        // Call LSDVault to mint unshETH
        _deposit_lsd(sfrxETHAddress, sfrxETHBalance);
    }

    function _mint_wstETH(uint256 ethAmount) internal {
        // Mint wstETH
        (bool success, )= address(wstETHAddress).call{value:ethAmount}("");
        // Check the success of the wstETH mint
        require(success, "wstETH minting failed");
        // Get balance of wstETH minted
        uint256 wstETHBalance = IERC20(wstETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(wstETHAddress, wstETHBalance);
    }

    function _mint_rETH(uint256 ethAmount) internal {
        //Check if deposits are open, then if yes (and under weight cap)  mint
        require(rocketPoolDepositEnabled(ethAmount), "rETH deposits are disabled");
        IRocketDepositPool(rocketDepositPoolAddress).deposit{value: ethAmount}();
        // Get the balance of rETH minted
        uint256 rETHBalance = IERC20(rETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(rETHAddress, rETHBalance);
    }

    function rocketPoolDepositEnabled(uint256 ethAmount) public view returns (bool) {
        return IRocketDepositPool(rocketDepositPoolAddress).getMaximumDepositAmount() > ethAmount;
    }


    function _mint_wETH(uint256 ethAmount) internal {
        IWETH(wethAddress).deposit{value: ethAmount}();
        _deposit_lsd(wethAddress, ethAmount);
    }

    function _mint_ankrETH(uint256 ethAmount) internal {
        // Mint ankrETH
        IANKRDeposits(ankrDepositsAddress).stakeAndClaimAethC{value:ethAmount}();
        // Get balance of ankrETH minted
        uint256 ankrETHBalance = IERC20(ankrETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(ankrETHAddress, ankrETHBalance);
    }

    function _mint_swETH(uint256 ethAmount) internal {
        // Mint swETH
        ISWETH(swETHAddress).deposit{value:ethAmount}();
        // Get balance of swETH minted
        uint256 swETHBalance = IERC20(swETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(swETHAddress, swETHBalance);
    }
  
    function _mint_ETHx(uint256 ethAmount) internal { 
        // mint ETHx 
        IStaderDeposit(staderDepositAddress).deposit{value:ethAmount}(address(this));
        // get the balance of ETHx 
        uint256 ethxBalance = IERC20(ethxAddress).balanceOf(address(this));
        // call LSDVault to mint unshETH 
        _deposit_lsd(ethxAddress, ethxBalance); 
    }
 
    function deposit_stEth(uint256 stETHAmount) external nonReentrant {
        // Deposit stETH into wstETH
        IWStETH(wstETHAddress).wrap(stETHAmount);
        // Get the wrapped balance
        uint256 wstETHAmount = IERC20(wstETHAddress).balanceOf(address(this));
        // Deposit into lsd vault
        _deposit_lsd(wstETHAddress, wstETHAmount);
    }

    function _deposit_frxEth(uint256 frxETHAmount) internal {
        // Deposit frxETH into sfrxETH
        SFRXETH(sfrxETHAddress).deposit(frxETHAmount, address(this));
        // Get the wrapped balance
        uint256 sfrxETHAmount = IERC20(sfrxETHAddress).balanceOf(address(this));
        // Deposit into lsd vault
        _deposit_lsd(sfrxETHAddress, sfrxETHAmount);
    }

    /*
    ============================================================================
    Direct LSD deposit functions
    ============================================================================
    */

    function deposit_lsd(address lsdAddress, uint256 amount) external  {
        // Assume user has approved token
        TransferHelper.safeTransferFrom(lsdAddress, msg.sender, address(this), amount);
        _deposit_lsd(lsdAddress, amount);
    }

    function _deposit_lsd(address lsdAddress, uint256 amount) internal {

        uint256 depositFee;
        uint256 protocolFee;
        if(vdAmmAddress != address(0)) {
            (depositFee, protocolFee) = IVdAmm(vdAmmAddress).getDepositFee(amount, lsdAddress);
        }

        uint256 amountToMint = amount - depositFee;
        uint256 unshETHFee = depositFee - protocolFee;

        if(protocolFee > 0) {
            // Transfer protocol fee to vdAmmAddress
            TransferHelper.safeTransfer(lsdAddress, vdAmmAddress, protocolFee);
        }

        if(depositFee > 0) {
            // Transfer unshETH fee to lsdVault
            TransferHelper.safeTransfer(lsdAddress, lsdVaultAddressV2, unshETHFee);
        }

        // Call LSDVault to mint unshETH
        ILSDVaultV2(lsdVaultAddressV2).deposit(lsdAddress, amountToMint);
        // Send unshETH to the msg.sender
        uint256 unshETHMinted = IERC20(unshETHAddressV2).balanceOf(address(this));
        TransferHelper.safeTransfer(unshETHAddressV2, msg.sender, unshETHMinted);

        emit DepositLsd(msg.sender, lsdAddress, amountToMint, depositFee, protocolFee, unshETHMinted);
    }

    /*
    ============================================================================
    Mint with ETH - primary zap function
    ============================================================================
    */

    function optimal_mint_pathId(uint256 ethAmountIn) public view returns(uint256 pathId) {

        //Hardcoded list to make things simple, excludes cbETH
        uint lsdsLength;

        address[7] memory lsds = [sfrxETHAddress, rETHAddress, wstETHAddress, wethAddress, ankrETHAddress, swETHAddress, ethxAddress];

        address lsdToMint; // default condition
        uint256 pctDistance = 0;
        uint256 ethBalanceInLsdVault = ILSDVaultV2(lsdVaultAddressV2).balanceInUnderlying();

        for(uint256 i=0; i<lsds.length; i++) {
            address lsd = lsds[i];

            if(lsd == rETHAddress && !rocketPoolDepositEnabled(ethAmountIn)) {
                continue;
            }

            uint256 darknetRate = IDarknet(darknetAddress).checkPrice(lsd);

            (uint256 targetWeightBps, uint256 weightCapBps, ) = ILSDVaultV2(lsdVaultAddressV2).lsdConfigs(lsd);
            uint256 targetAmountEth = ethBalanceInLsdVault * targetWeightBps / 10000;
            uint256 weightCapEth = ethBalanceInLsdVault * weightCapBps / 10000;

            uint256 lsdBalanceInEthTerms = IERC20(lsd).balanceOf(lsdVaultAddressV2) * darknetRate / 1e18;

            //If deposit would cause exceeding the cap, skip
            if(lsdBalanceInEthTerms + ethAmountIn > weightCapEth) {
                continue;
            }

            //If balance is above the target already, skip
            if(lsdBalanceInEthTerms > targetAmountEth) {
                continue;
            }

            uint256 distanceToTarget = targetAmountEth - lsdBalanceInEthTerms;
            uint256 newPctDistance = distanceToTarget * 1e18 / targetAmountEth;

            //Evaluate the optimal mint lsd based on the greatest pct diff to target
            //Not fully correct as it will fail on large deposits in small lsds, but close enough
            if(newPctDistance > pctDistance) {
                pctDistance = newPctDistance;
                lsdToMint = lsd;
            }
        }

        require(lsdToMint != address(0), "No LSD to mint");
        return lsdToMintPathId[lsdToMint];
    }

    function mint_unsheth_with_eth_optimalmint() external payable nonReentrant returns(uint256){
        uint256 pathId = optimal_mint_pathId(msg.value);
        _ETH_to_unsheth_mintPaths(msg.value, pathId);
        return pathId;
    }

    function mint_unsheth_with_eth(uint256 amountOutMin, uint256 pathId) external payable nonReentrant {
        // Validate the path
        require(pathId <= MAX_PATH_ID, "Invalid path");

        if(mintPathIdToAddress[pathId] != address(0)) {
            _ETH_to_unsheth_mintPaths(msg.value, pathId);
        } else {
            IWETH(wethAddress).deposit{value: msg.value}();
            uint256 wethAmount = IERC20(wethAddress).balanceOf(address(this));
            _weth_to_unsheth_swapPaths(wethAmount, amountOutMin, pathId);
        }
        emit DepositEth(msg.sender, msg.value, pathId);
    }

    function _ETH_to_unsheth_mintPaths(uint256 ethAmount, uint256 pathId) internal {
        if(pathId == 0) {
            _mint_wstETH(ethAmount);
        } else if(pathId == 1) {
            _mint_sfrxETH(ethAmount);
        } else if(pathId == 6) {
            _mint_rETH(ethAmount);
        } else if(pathId == 7) {
            _mint_wETH(ethAmount);
        } else if (pathId == 8) {
            _mint_ankrETH(ethAmount);
        } else if (pathId == 9) {
            _mint_swETH(ethAmount);
        } else if (pathId == 11) { 
            _mint_ETHx(ethAmount);
        }
    }

    function _weth_to_unsheth_swapPaths(uint256 wethAmount, uint256 amountOutMin, uint256 pathId) internal {
        require(swapPathIdToAddress[pathId] != address(0), "swap path not supported");
        require(amountOutMin > 0, "amountOutMin must be greater than 0");
        if (pathId == 5) {
            //swap weth to frxETH (sfrxETH not liquid)
            uint256 frxEthAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, frxETHAddress);
            //mint unshETH with frxETH->sfrxETH
            _deposit_frxEth(frxEthAmountOut);
        } else {
            address lsdAddress = swapPathIdToAddress[pathId];
            //swap weth to lsd
            uint256 lsdAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, lsdAddress);
            //mint unshETH with lsd
            _deposit_lsd(lsdAddress, lsdAmountOut);
        }
    }

    function _swap_weth_lsd(uint256 _wethAmount, uint256 _amountOutMin, address _lsdAddress) internal returns(uint256) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: wethAddress,
        tokenOut: _lsdAddress,
        fee: POOLFEE,
        recipient: address(this),
        deadline: block.timestamp + 3600,
        amountIn: _wethAmount,
        amountOutMinimum: _amountOutMin,
        sqrtPriceLimitX96: 0
        });

        uint256 lsdAmountOut = uniswapRouterV3.exactInputSingle(params);
        return(lsdAmountOut);
    }

    /*
    ============================================================================
    Other functions
    ============================================================================
    */
    function updateVdAmmAddress() external {
        vdAmmAddress = ILSDVaultV2(lsdVaultAddressV2).swapperAddress();
    }

    function updateDarknetAddress() external {
        darknetAddress = ILSDVaultV2(lsdVaultAddressV2).darknetAddress();
    }

    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    //Allow receiving eth to the contract
    receive() external payable {}
}
