pragma solidity >=0.6.6;

import "./IxCAVO.sol";
import "./ICAVO.sol";
import "./IERC20.sol";
import "./IEXCV.sol";
import "./IExcavoPair.sol";
import "./IExcavoFactory.sol";
import "./SafeMath.sol";
import "./ExcavoLibrary.sol";
import "./UQ112x112.sol";
import "./ReentrancyGuard.sol";

contract xCAVO is IxCAVO, IERC20, ReentrancyGuard {
    using SafeMath for uint;
    
    event Redeem(address indexed sender, address indexed recipient, uint amount);

    string public constant override name = 'xCAVO';
    string public constant override symbol = 'xCAVO';
    uint8 public constant override decimals = 18;
    uint private constant Q112 = 2**112;
    uint private constant WEI_IN_CAVO = 10**18;
    uint private constant VESTING_PERIOD = 7020000; // 36 * 30 * 6500 = 7020000 = 36 months in blocks
    
    address public immutable override getCAVO;
    address public override excvEthPair;
    address public override cavoEthPair;
    address public override getEXCV;

    mapping(address => uint) private lastAccumulatedMintableCAVOAmount;
    mapping(address => uint) private lastAccumulatedUnclaimedLiquidity;

    uint public override accumulatedMintableCAVOAmount;
    uint private firstBlockNumber;
    uint private lastBlockNumber;
    uint internal expectedPriceInUQ;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        getCAVO = msg.sender;
    }

    function initialize(address _factory, address _EXCV) external override nonReentrant  {
        require(getEXCV == address(0) && excvEthPair == address(0) && cavoEthPair == address(0) && msg.sender == getCAVO, "xCAVO: FORBIDDEN"); 
        getEXCV = _EXCV;
        address WETH = IExcavoFactory(_factory).WETHToken();
        excvEthPair = ExcavoLibrary.pairFor(_factory, getEXCV, WETH);
        cavoEthPair = ExcavoLibrary.pairFor(_factory, getCAVO, WETH);
    }

    function registerPairCreation() external override nonReentrant {
        require(firstBlockNumber == 0 && msg.sender == cavoEthPair, "xCAVO: FORBIDDEN");
        firstBlockNumber = block.number;
        lastBlockNumber = block.number;
    }

    function totalSupply() external view override returns (uint) {
        return IERC20(getCAVO).totalSupply();
    }

    function balanceOf(address owner) external view override returns (uint) {
        uint totalUnclaimedLiquidity = IExcavoPair(excvEthPair).accumulatedLiquidityGrowth() - lastAccumulatedUnclaimedLiquidity[owner];
        if (totalUnclaimedLiquidity == 0) {
            return 0;
        }
        uint totalMintableCAVO = accumulatedMintableCAVOAmount - lastAccumulatedMintableCAVOAmount[owner];
        uint liquidity = IExcavoPair(excvEthPair).unclaimedLiquidityOf(owner);
        return liquidity.mul(totalMintableCAVO) / totalUnclaimedLiquidity;
    }

    function redeem(address recipient) external override nonReentrant {
        uint liquidity = IExcavoPair(excvEthPair).claimAllLiquidity(msg.sender);
        uint accumulatedUnclaimedLiquidity = IExcavoPair(excvEthPair).accumulatedUnclaimedLiquidity();
        uint totalUnclaimedLiquidity = accumulatedUnclaimedLiquidity - lastAccumulatedUnclaimedLiquidity[msg.sender]; // overflow desired
        if (totalUnclaimedLiquidity == 0) {
            revert('xCAVO: INSUFFICIENT_MINTED_AMOUNT');
        }
        uint totalMintableCAVO = accumulatedMintableCAVOAmount - lastAccumulatedMintableCAVOAmount[msg.sender]; // overflow desired
        uint mintedAmount = liquidity.mul(totalMintableCAVO) / totalUnclaimedLiquidity;
        require(mintedAmount > 0, 'xCAVO: INSUFFICIENT_MINTED_AMOUNT');
        lastAccumulatedUnclaimedLiquidity[msg.sender] = accumulatedUnclaimedLiquidity;
        lastAccumulatedMintableCAVOAmount[msg.sender] = accumulatedMintableCAVOAmount;
        ICAVO(getCAVO).mint(recipient, mintedAmount);
        emit Redeem(msg.sender, recipient, mintedAmount);
    }

    function mint(uint priceInUQ) external override nonReentrant {
        require(msg.sender == cavoEthPair, "xCAVO: FORBIDDEN");

        if (block.number - firstBlockNumber >= VESTING_PERIOD || block.number == lastBlockNumber) {
            return;
        }
        uint priceChangeInUQ = Q112.mul(block.number.sub(lastBlockNumber)).mul(3).div(6500000);
        if (expectedPriceInUQ + priceChangeInUQ < expectedPriceInUQ) {
            return; // overflow: stop minting
        }
        expectedPriceInUQ += priceChangeInUQ; // cannot overflow
        if (priceInUQ >= expectedPriceInUQ) {
            // mintedAmount = 10^6 * (N - Nprev) * (N + Nprev - 2 * N0) / ((36 * 30 * 6500)^2)
            // ((36 * 30 * 6500)**2) = 49280400000000
            // 10**6 = 1000000
            uint mintedAmount = block.number.sub(lastBlockNumber).mul(1000000)
                .mul(block.number.add(lastBlockNumber).sub(firstBlockNumber.mul(2)))
                .mul(WEI_IN_CAVO)
                .div(49280400000000);
            if (mintedAmount > 0) {
                accumulatedMintableCAVOAmount = accumulatedMintableCAVOAmount + mintedAmount; // overflow desired
            }
        }
        lastBlockNumber = block.number;
    }

    function allowance(address /*owner*/, address /*spender*/) external view override returns (uint) {
        revert("xCAVO: FORBIDDEN");
    }

    function approve(address /*spender*/, uint /*value*/) external override returns (bool) {
        revert("xCAVO: FORBIDDEN");
    }

    function transfer(address /*to*/, uint /*value*/) external override returns (bool) {
        revert("xCAVO: FORBIDDEN");
    }

    function transferFrom(address /*from*/, address /*to*/, uint /*value*/) external override returns (bool) {
        revert("xCAVO: FORBIDDEN");
    }
}
