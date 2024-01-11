pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IFridge.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./OracleLibrary.sol";

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXKKKK00000000000KKKXXNNWWWMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWXOkdoolcc:;;;,,,,''''''''''',,,,;;::cclloddxkO0KXWMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMW0:.........''''''''''''''''''''''''..........'cdOWMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMXd,.......................................,o0WMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMWKl'....................................lKWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMWO:.................................,xNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.....''.......................:0WMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:............................cKMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.........................cXMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,.......................lXMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.....................lXMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl....,'.............cXMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.................cKMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:...............;0MMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.............,OWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:............;KMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.............oNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,....'........:XMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;.....'........lNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...............dWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl................kMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd................,OMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'....''..........;KMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.................cXMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;..................oWMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...................xMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.....'.............'kMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd......'.............,0MMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'....................:XMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.....................lNMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMK;.....',,,,''..........lKKXWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMXc.',;;::::::cc:'........,;;:lxKWMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMNl..;:::::::c:ccc;',,,'.',,,,;;;:oONMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMNd..';:::::llcclol;',,,'',,,,,,,,,,;cxNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMNOxxxkOkc,',,,;;;;::;;:::;'''',''',,,,,,;;;;;,oNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMWKx:,;:ccc;''',,'',,,'''',,,,''',,,'''',,;:;;:c:'cKMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMKc',;,;cc:;,''',,,,,,,'',,,,,''',,,,'''',;;,;c:,:OWMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMk,,::::c:;::;,','''',,,,,',,,'',,,,,,,,,'''',,':0MMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMXd::c:cc:;;;;,'','',,,,,'',,,,,,,,,,',,,,,,',,',d0OxkKWMMMMMMMMMMMM
//MMMMMMMMMMMMMMW0l,;::;;;,,,'',,,,'',,,'''''',,,,,,,,,,,,,,,,,''.'',oXMMMMMMMMMMM
//MMMMMMMMMMMMMMMXl',;,,,,',,,,,,,'..............'''',,,,,,,,,,.......cKMMMMMMMMMM
//MMMMMMMMMMMMMMNd,''''''',,,'''.....................',,,,'',,,.....'''dWMMMMMMMMM
//MMMMMMMMWXKXNWk,',,,'''''''.........................',,,'.',,'''''';oKWMMMMMMMMM
//MMMMMMMNx;,;:c;''''''''''.............................''..',',,,''oKNWMMMMMMMMMM
//MMMMMMWO:'''''''''''''....................................','',,,'cdxxONMMMMMMMM
//MMMMMMKc..',',,'',,'......................................,'',,,,;clcccxXMMMMMMM
//MMMMMWd,',,,',,,,,'.......................................',,,,,,;ccclc:xNMMMMMM
//MMMMW0c,'',,'',,,'........................''...............',,,,,,;:llc;lKMMMMMM
//MMMMKl,,,,,,,,,''.........................'.................',,,,,,;::;:xNMMMMMM
//MMMMO:,,,,,,,,,'.................'........''..................,,,,,',oOKWMMMMMMM
//MMMMW0xol:,'',''..........'.....,'........''......''...''.....',,,,,'dWMMMMMMMMM
//MMMMMMMWNo',,,'..........''....''.........'''....','...,'......'',,,'cXMMMMMMMMM
//MMMMMMMMNl',,''..........,'...''..........''''...,;'..,;........',,,';0MMMMMMMMM
//MMMMMMMMXc',,,'.........';,...';,........''''''.,;,..';;.........,,,,;kMMMMMMMMM
//MMMMMMMMXc',,,'.........';;...,;:,'....',;,''',;;;'..,:;.........',,,,xWMMMMMMMM
//MMMMMMMMKc',,,'.........';;'.',;;;;;,'';c:,',',;;;..';:;.........',,,'oNMMMMMMMM
//MMMMMMMMKc',,,.....'.....;:;;,,,;;;::::cc:'',,,;;,..';:;,'.......',,,'oNMMMMMMMM
//MMMMMMMMKc',,,....''.....';;;;,,;:::;;;:c;,',,,,,,,,,::;;;'......',,,'lNMMMMMMMM
//MMMMMMMMKc',,'....'''....',;;;,,;;;;;;::::;;,;,',:;,,::;;;'......',,,'lXMMMMMMMM
//MMMMMMMMKc',,'.....'''''',,;,,;;;;::;;::;;cc;,;;;;;,;:;;;,.......,,,,'lXMMMMMMMM
//MMMMMMMMXc',,'......''',,,''',::;:c:;,;;,:llc;:c;;:;;::;;'......',',,'lNMMMMMMMM
//MMMMMMMMXl',,'.......',,,,;,,,:c::ccc:::cllllll:;cl:;;;;,.......',,,,'oNMMMMMMMM
//MMMMMMMMNo',,'........',,;c:;;cllcllllllllloolccllllc;;;'......',,,','dWMMMMMMMM
//MMMMMMMMWx,','..........'':lcclxdodxxoollldkkxdddoodl;;,.......',,,,',xMMMMMMMMM
//MMMMMMMMMK:','............':cldkkkkOkkkkkkkkOOkkxxkxl:,........',,,,',kMMMMMMMMM
//MMMMMMMMMWd''''...............,;;;;:::::::::::::;;;,..........',,,,,':0MMMMMMMMM
//MMMMMMMMMMO,.,'..''''''......'........................''''',,,,',,,,'cKMMMMMMMMM
//MMMMMMMMMMNl','..'''''...''.',',;;;,;;;,,,,,,,,',:cccccccccccl:'',,,,oNMMMMMMMMM
//MMMMMMMMNK0o''''''''',,''''.',,;;;;,;;;,,,;;;,,'';:::::::;;;:;,'',,''oNMMMMMMMMM
//MMMMMMMNd:;;,,,,,''''',,,,'',,,,,,,,,,,,,,,,,,,,'''''''''''''''',,,;;:dXMMMMMMMM
//MMMMMMM0c::;:::::::;,;;,,,,,,,,'',''''''',,,''''''''''''',,;;;;::c::c:c0MMMMMMMM
//MMMMMMMNd;;;::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;::::ccccc::cc:::dXMMMMMMMM
//MMMMMMMMNOkkxc,,;;;;:::::::::::::::::c:::::cc::ccccccccccccc::::;;,;dKNMMMMMMMMM
//MMMMMMMMMMMMMO,',''',,,,,,,;;;;;;;:::::::::::::::::::::;;;;;,,,,,,'cXMMMMMMMMMMM
//MMMMMMMMMMMMMXl',,',,,,,,'',''',,,,,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,xWMMMMMMMMMMM
//MMMMMMMMMMMMMWx,,,,,,,,,,,,,,,,,,,,,,,,'''''''',,,,,,,,,,,,,,,,,,':0MMMMMMMMMMMM
//MMMMMMMMMMMMMMK:',,,,,,,,,,,,,,,,,,,,,,''''',,,,,,,,,,,,,,,,,,,,,,dWMMMMMMMMMMMM
//MMMMMMMMMMMMMMWd',,,,,,,,,,,,,,,,,,,,,,''''',,'',,,,,,,,,,,,,,,,';0MMMMMMMMMMMMM
//MMMMMMMMMMMMMMMO;',,,,,,,,'''',,,,,,,,,,,,,,,,,''',,,''',,,,,,,,'oNMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMNl''''''...'''''''''''''''''''''''''''''''',,,,,';OMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMk,',,,'. .'',,'''''''''''''''''''.'''''''.',,,,'oNMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMKc',,,,.. .'''''''''''''''''''''. .'''''.',,,,':0MMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWx,,,,,'. .','''''''''''''''''''.  .''''.',,,,,xWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMM0:',,,,'..'''''''''''''''''''''.  .''''',,,,'cXMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMNo',,',,,'.''''''''''''''''''''......',,'',''xMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMO;,,,,,,'..''''''''''''''''''''..'',,,,,'..,0MMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMXl',,,,,,'.''''''''''''''''''''',,,,,,'';. cNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMWk,',,,,,,,,,''''''''''''''''',,,,,,,';d0:.dWMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMNx;''.',,,,,,,,,,,,,,,,,,,,,,,,'''';oKWN:.:kXMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWXo. .:lccc::;;,,,,'''''''''''. 'oKWMMNo'',oXMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMM0, .xWWWNNXXKK000OOOkkxxddo:. lNMMMMWNNNNNWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMNl .kMMMMMMMMMMMMMMMMMMMMMMk..kMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMk..kMMMMMMMMMMMMMMMMMMMMMMk.,KMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMNOo:..kMMMMMMMMMMMMMMMMMMMMMMk..lOWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMWOc;;;c0MMMMMMMMMMMMMMMMMMMMMM0:'':kWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMWNNNNNWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract TurboV3Oven is Context, Ownable {
    /*
        The Oven's job is to consume tokens and send WETH to the fridge.
        The TurboV3Oven is designed for taxless V3 tokens, and gets 
        cheaper price reads thanks to V3 price oracle.
    */
    
    // V3 Oven
    address private DC = 0x679A0B65a14b06B44A0cC879d92B8bB46a818633;
    ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory  factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping (address => bool) public _targeted;
    mapping (address => uint24) private fee; //Note that fee is in hundredths of basis points (e.g. the fee for a pool at the 0.3% tier is 3000; the fee for a pool at the 0.01% tier is 100).
    mapping (address => IUniswapV3Pool) private pools;
    IFridge _fridge;
    address dev1 = 0x7190A1826F69829522d7B8Fa042613C9377badDC;
    address dev2 = 0x1Dc1560F9C4622361788357aC7ee8dd2DE71816e;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    using SafeMath for uint8;
    event UsingFridge(address fridge);

    constructor (address fridge) {
        // V3 Oven
        replaceFridge(fridge);
    }

    // Oven
    function addTarget(address token, uint24 new_fee) public onlyOwner() {
        // Record the exact cooking instructions for new targets
        _targeted[token] = true;
        fee[token] = new_fee;
        pools[token] = IUniswapV3Pool(factory.getPool(token, WETH, new_fee));
        IERC20(token).approve(address(swapRouter), type(uint256).max);
    }

    function removeTarget(address token) public onlyOwner() {
        _targeted[token] = false;
    }

    function replaceFridge (address fridge) public onlyOwner() {
        emit UsingFridge(fridge);
        _fridge = IFridge(fridge);
    }

    function setDevs(address new_dev1, address new_dev2) public onlyOwner() {
        // Operators who call the cook function.
        dev1 = new_dev1;
        dev2 = new_dev2;
    }

    function updatePrice(address token) external {
        // Don't do nothin'.
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function estimateAmountOut(address token, uint128 amountIn, uint32 secondsAgo) public view returns (uint256 amountOut) {
      //uint128 amountIn = uint128(amountIn256);
      // optimized of: (int24 tick, _liquidity) = OracleLibrary.consult(pool, secondsAgo)
      uint32[] memory secondsAgos = new uint32[](2);
      secondsAgos[0] = secondsAgo;
      secondsAgos[1] = 0;
      IUniswapV3Pool pool = pools[token];
      (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
      int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
      int24 tick = int24(tickCumulativesDelta / secondsAgo);
      // Always round to negative infinity
      if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) {
        tick--;
      }
      amountOut = OracleLibrary.getQuoteAtTick(tick, amountIn, token, WETH);
    }

    function getValues(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue) {
        // Estimates value of a given amount of target token, based on market conditions.
        require(_targeted[token]);
        uint128 amount128 = uint128(amount);
        ethValue = estimateAmountOut(token, amount128, 32).mul(99).div(100);
        paperValue = 0;
    }

    function otcOffer(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue, uint256 vestedTime) {
        // Provides the estimated values back to DC, along with the "cook time" for the vest.
        (ethValue, paperValue) = this.getValues(token, amount);
        vestedTime = block.timestamp.add(7 days);
    }

    function cook(address token, address pairAddr, uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        // Liquidates target tokens and passes the profits along to the fridge.
        require(block.timestamp < deadline, "Expired");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Only chefs allowed in the kitchen!");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        uint balanceBefore = IERC20(WETH).balanceOf(address(_fridge));
        IERC20(token).transfer(address(pair), amountIn);
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH > token ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(token).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = WETH > token ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, address(_fridge), new bytes(0));
        require(IERC20(WETH).balanceOf(address(_fridge)).sub(balanceBefore) >= amountOutMin, 'Slipped.');
    }

    //Fail-safe function for releasing non-target tokens, not meant to be used.
    function release(address token) public {
        require (!_targeted[token]);
        IERC20(token).transfer(owner(), 
            IERC20(token).balanceOf(address(this)));
    }
}
