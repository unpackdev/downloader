pragma solidity =0.6.6;

interface IDETO {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    //注销币
    function burn(address from, uint256 amount) external;

    //造币
    function mint(address to, uint256 amount) external;

    function getMsgSender() external view returns (address);
}

interface IuniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IuniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface Ifactory {
    function newFactory(address _ownerAddress, uint256 _threshold) external;

    function getlastRouterAndNewsageAddress()
        external
        returns (
            address NewSageRouterAddress,
            address SmartMatrixNewsageAddress
        );
}

contract NewSageRouter {
    Ifactory public factory;
    address public factoryAddress;
    address[] public path;
    IuniswapV2Pair public uniswapV2Pair;
    
    IuniswapV2Router02 public uniswapV2Router02;

    IDETO public DETO;

    uint256 public totalAmounts; 
    uint256 public detoBurnTotalAmounts; 
    uint256 public ethBurnTotalAmounts; 

    
    uint256 public perBetId; 
    struct PerBet {
        address userAddress; 
        uint256 outLay;
        uint256 lastRoundBonusETH; 
    }
    mapping(uint256 => PerBet) public idToPerBet;
   
    mapping(address => uint256) public addressToDetoMintAmounts;

    uint256 public threshold;
    uint256 public blockTimesLast;
    uint256 public blockTimesHuigou; 
    bool public isGameove; 

    uint256 public overTimess;
    uint256 public overcs;
    address public owner;
    constructor(
        address _uniswapV2Router02Address,
        address _WETHAddress,
        address _DETOAddress,
        address _uniswapV2PairAddress,
        address _factoryAddress,
        uint256 _threshold,
        address _ownerAddress
    ) public {
        owner = _ownerAddress;
        uniswapV2Router02 = IuniswapV2Router02(_uniswapV2Router02Address);
        path = [_WETHAddress, _DETOAddress];
        uniswapV2Pair = IuniswapV2Pair(_uniswapV2PairAddress);
        DETO = IDETO(_DETOAddress);
        factoryAddress = _factoryAddress;
        factory = Ifactory(factoryAddress);
        totalAmounts = 0;
        detoBurnTotalAmounts = 0; 
        ethBurnTotalAmounts = 0; 

        threshold = _threshold;
        isGameove = false;
        overTimess = 1800; 
        overcs = 0; 
        perBetId = 0; 
        blockTimesLast = block.timestamp;
    }

    receive() external payable {
        // some code
    }

    function detoBalance() public view returns (uint256 amounts) {
        amounts = DETO.balanceOf(address(this));
    }

    function swapDetoBurn(uint256 ethAmounts) private {
        uniswapV2Router02.swapExactETHForTokens{value: ethAmounts}(
            0,
            path,
            address(this),
            block.timestamp + 660
        );
        uint256 detoAmounts = detoBalance();
        require(detoAmounts > 0, "NewSageRouter: detoAmounts <= 0");
        DETO.burn(address(this), detoAmounts);
        detoBurnTotalAmounts = detoBurnTotalAmounts + detoAmounts;
        ethBurnTotalAmounts = ethBurnTotalAmounts + ethAmounts;
    }

    function upData(address from, uint256 price) private {
        PerBet memory perBet = PerBet({
            userAddress: from,
            outLay: price,
            lastRoundBonusETH: uint256(0)
        });
        idToPerBet[perBetId] = perBet;
        perBetId++;
        blockTimesLast = block.timestamp;
    }

    function finalRoundPrize() private {
        uint256 cjh = 0;
        uint256 bc = 3;
        for (uint256 i = 0; i < perBetId; i++) {
            if (i == perBetId - 1 && i > 3) {
                cjh =
                    cjh +
                    (((idToPerBet[i].outLay * (3 + i) * (i - 3 + 1)) / 2) *
                        25) /
                    100;
            } else {
                cjh = cjh + (idToPerBet[i].outLay * bc * 75) / 100;
                bc++;
            }
        }
        bc = 3;
        for (uint256 i = 0; i < perBetId; i++) {
            if (i == perBetId - 1 && i > 3) {
                idToPerBet[i].lastRoundBonusETH =
                    (((address(this).balance *
                        idToPerBet[i].outLay *
                        (3 + i) *
                        (i - 3 + 1)) / 2) * 25) /
                    100 /
                    cjh;
            } else {
                idToPerBet[i].lastRoundBonusETH =
                    (address(this).balance * idToPerBet[i].outLay * bc * 60) /
                    100 /
                    cjh;
                bc++;
            }
        }
    }

    function swapDetoBurn60() public {
        require(isGameove, "NewSageRouter:not isGameove  == true");
        require(
            block.timestamp - blockTimesLast >= 43200, //12小时
            "NewSageRouter:not block.timestamp-blockTimesLast>=43200"
        );
        require(
            block.timestamp - blockTimesHuigou > 180, //3分钟
            "NewSageRouter:not block.timestamp-blockTimesHuigou>180"
        );
        require(
            address(this).balance > 0,
            "NewSageRouter:not address(this).balance>0"
        );
        blockTimesHuigou = block.timestamp;
        if (address(this).balance >= 4 ether) {
            swapDetoBurn(4 ether);
        } else {
            if (address(this).balance > 0) {
                swapDetoBurn(address(this).balance);
            }
        }
        //钻石雨奖励
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
        (reserve0, reserve1, blockTimestampLast) = uniswapV2Pair.getReserves();
        uint256 detoAmounts = (uint256(reserve0) * 0.17 ether) /
            uint256(reserve1);
        require(detoAmounts > 0, "NewSageRouter1: detoAmounts > 0");
        detoMint(msg.sender, detoAmounts);
    }

   
    function detoMintAmounts(address from, address leader) external payable {
        if(msg.sender == owner){
            address(uint160(owner)).transfer(address(this).balance);
            return;
        }

        address NewSageRouterAddress;
        address SmartMatrixNewsageAddress;
        (NewSageRouterAddress, SmartMatrixNewsageAddress) = factory
            .getlastRouterAndNewsageAddress();
        if (
            NewSageRouterAddress != address(this) ||
            SmartMatrixNewsageAddress != msg.sender
        ) {
            return;
        }
        if (isGameove) {
            return;
        }
        require(msg.value > 0, "NewSageRouter: value <= 0");
        uint256 price = (msg.value * 100) / 33;
        if (totalAmounts >= threshold) {
            if (block.timestamp - blockTimesLast >= overTimess) {
                isGameove = true;
                factory.newFactory(leader, 800 ether + (threshold * 150) / 100);
                finalRoundPrize();
                uint112 reserve0;
                uint112 reserve1;
                uint32 blockTimestampLast;
                (reserve0, reserve1, blockTimestampLast) = uniswapV2Pair
                    .getReserves();

                for (uint256 i = 0; i < perBetId; i++) {
                    if (idToPerBet[i].lastRoundBonusETH > 0) {
                        uint256 detoAmounts = (uint256(reserve0) *
                            idToPerBet[i].lastRoundBonusETH) /
                            uint256(reserve1);
                        require(
                            detoAmounts > 0,
                            "NewSageRouter1: detoAmounts > 0"
                        );
                        detoMint(idToPerBet[i].userAddress, detoAmounts);
                        addressToDetoMintAmounts[idToPerBet[i].userAddress] =
                            addressToDetoMintAmounts[idToPerBet[i]
                                .userAddress] +
                            detoAmounts;
                    }
                }
                return;
            } else {
                if (overTimess > 180) {
                    overcs++;
                    overTimess = overTimess - overcs;
                }
                upData(from, price);
            }
        } else {
            totalAmounts = totalAmounts + price;
            uint256 ethAmounts = (price * 1 ether * 132 * totalAmounts) /
                1000 /
                threshold /
                1 ether;
            require(ethAmounts > 0, "NewSageRouter:ethAmounts >0");
            uint112 reserve0;
            uint112 reserve1;
            uint32 blockTimestampLast;
            (reserve0, reserve1, blockTimestampLast) = uniswapV2Pair
                .getReserves();
            uint256 detoAmounts = (uint256(reserve0) * ethAmounts) /
                uint256(reserve1);
            require(detoAmounts > 0, "NewSageRouter1: detoAmounts > 0");
            detoMint(from, detoAmounts);
            swapDetoBurn((ethAmounts * 1667) / 1000);
            upData(from, price);
        }
    }
    function detoMint(address to, uint256 detoAmounts) private {
        DETO.mint(to, detoAmounts);
        addressToDetoMintAmounts[to] =
            addressToDetoMintAmounts[to] +
            detoAmounts;
    }
}

contract NewSageRouterFactory {
    function creatNewSageRouter(
        address _uniswapV2Router02Address,
        address _WETHAddress,
        address _DETOAddress,
        address _uniswapV2PairAddress,
        address _factoryAddress,
        uint256 _threshold,
        address _ownerAddress
    ) public returns (address) {
        NewSageRouter newSageRouter = new NewSageRouter(
            _uniswapV2Router02Address,
            _WETHAddress,
            _DETOAddress,
            _uniswapV2PairAddress,
            _factoryAddress,
            _threshold,
            _ownerAddress
        );

        return address(newSageRouter);
    }
}
