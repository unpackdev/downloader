pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./OracleLibrary.sol";
import "./IIncinerator.sol";

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMWWNNNNXXX0KKKKKKKKKKKKKKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWNXKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWNNNXKK000000KKKKKKKK0KKKK00KKKKKKKKKK00KXNWMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMWNXKKKKKKKK0000KKKKKK0000KK0000KKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMWNKK0OO0K00KKKKKKK00KKKK000KKK0000KKKKKKKKKKKKKKKKKKXNNWMMMMMMMMMMMMMMM
//MMMMMMMMNK00Oxdd0K0KKKK00KKKKKKKK00KKKKKKKKKKKKKKKKKK0KKKKKKKKKKKXWMMMMMMMMMMMMM
//MMMMMMMNK0Oxoolx0K000KK00KKKK00KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0KXWMMMMMMMMMMM
//MMMMMMWX0kolollxKK000KKKKK0KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkodOKNWMMMMMMMMM
//MMMMMMNKkolooolx0KKKK0KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKo';k00KNMMMMMMMM
//MMMMMWXOxlllllld0KKK00K00KKKKKKKKKKKKKKKKK0KKKKK00KKKKKKKKKKKKKKd',x0000XWMMMMMM
//MMMMMN0xocccccclOK00OO00KKK000KKKKK00KKKKKKKKKKK0KKKKKKKKKKKK0KKx,,okxxxx0WMMMMM
//MMMMMNOxocccccclkKOolldOK000K000KKKKKKK0000KKKK000KK0KKKKKKK00KXk;'lkxxxxkXMMMMM
//MMMMMXkxdcccccccxKOoccoOKKK00KKK0KKKKKKKKKK00KKKK0KK00KKKKKKKKKKOl:oxxxxxkXMMMMM
//MMMMMKxxdcccccccd00dcclOK0KKKKKKKKKKKKKKKKKK0KKKKKK00KKKKKKKKKKK0xxxdxxxxxKWMMMM
//MMMMMKxxdcccccccd0KxlclkK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKK0kxxxxxxxx0WMMMM
//MMMMMKxdoccccccco0KklclkKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKXKkxxxxxxxdONMMMM
//MMMMMKkxdlccccc:lOKOoclx0KKKKKKKKKKKKKKKKKXKKKKKKKKKKKKKKKKKKKKKKkxxxxxxxxONMMMM
//MMMMMKxxxlccccc:lkX0dclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxkkxxxxxkNMMMM
//MMMMMXxdxl:ccccccxKKxlcd0KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKK0K0kxkkkxxxxkNMMMM
//MMMMMXxddoc:cccccx0Kklcd0KKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKxclxxddxxkXMMMM
//MMMMMNkdxoccc:cc:d0KOocoOK0KKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKXKo';dkddxxkXMMMM
//MMMMMNOdxdcccccc:o0X0dclOK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o';dkxxxdkNMMMM
//MMMMMWOdxdlccccc:lOKKOxk0KKKKKKKKKKK0KKKKKK00KKKKKKKKKK0KKKKKKKK0o';oxxxxxONMMMM
//MMMMMW0xxdlcccccclkK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKo',oxxkxxONMMMM
//MMMMMMXxxxoccccccckKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKXKdcldxxxxxONMMMM
//MMMMMMNOxxocccccccxKKKKKKK00KKKKKKKKKKK00KKKKKKKKKKKKKKKKK0KKKK0kxkkxxkxxx0WMMMM
//MMMMMMN0xxdlcccccco0KKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0Okxxxxxxkxxx0WMMMM
//MMMMMMWKkkxxxdddddodkOOOOOOOOOOO000OOOOOOOOOOOOOOkkkkkkxxkkOkkkkkkddxxddod0WMMMM
//MMMMMMMXkxkkkkkkkkkxxxddxxxxdxxkkkxxxxxxxxxxxxxxxxxdxxxdxxkkkOOkxxxxxxxddxKMMMMM
//MMMMMMMNkxkkkkkkkOkkkkxxkxxxkxxkkkxdodkkkkkkkkOOOOOOkOOO000000OxxkxxxkxxxOXMMMMM
//MMMMMMMW0xkkkkkkkkOkkkkkxkkOOkkOO0000000000000000000OO00K000KK0xxkkkxkkkkONMMMMM
//MMMMMMMMKkkOOOkxxddddddk00KKKK0KKKKK0K00K0000000000K0KKKK00KKKOookkkkkkkxONMMMMM
//MMMMMMMMXkxkxolc:::::cd0KKKKKKKKK00000KKK0000000000K000K00KKKKx,,dkxkkkkx0WMMMMM
//MMMMMMMMNOxdc::::::::d0Oxxxk0000K000KK00K000O000000K000KKKKKKKd',dxxxxkkxKWMMMMM
//MMMMMMMMW0xo:::::::::dOdcccoOK0000KK00KKK000000000KK00KKKKKKKKd';oddxxkkkKMMMMMM
//MMMMMMMMMKko:;:::::::oOxclclkK00000000KKKKK00K0000KK00K000KKKKo';dxxxxxxkXMMMMMM
//MMMMMMMMMXkdc;;;;;::;cOklcccx00000000K00000000K00000OO00000KK0d,:dxdodxxONMMMMMM
//MMMMMMMMMNkoc;;;;;;;;:xOocccd0000KKKK0000KK000K00KK0000K00K00KOdxxxxdxddOWMMMMMM
//MMMMMMMMMWOdl;;;,,,;;;oOdcccoO0K0KK00KK000KKKKK000KK00K000KK00Oxdddddxdd0WMMMMMM
//MMMMMMMMMMKdl:;;;,,,,,lOdcccoO0000KKK00000000000000000K0O0K000kxxddddddxKMMMMMMM
//MMMMMMMMMMXxoc;,;;;,,,ckklcclkOOOOOOOOO00000000000000000O00000kdddoooooxXMMMMMMM
//MMMMMMMMMMNkol;,,,,,,,:xOocclxOOOOOOO000000000000000KKK0000000koodoollokNMMMMMMM
//MMMMMMMMMMW0dd:;;;,,;;;oOxcccdO0OOO000000OO0000K0000KKKKKKK000kdoddooooOWMMMMMMM
//MMMMMMMMMMMKdoc;;;,;;;;lOklccdO00000000000O00KKK00KKKKKKKKKK00OdooddoooOWMMMMMMM
//MMMMMMMMMMMXxol;;;;;;;;ckOoccoO00KKK0000000KKKKKK0KKKKKKKKKKKKOdddddxdxXMMMMMMMM
//MMMMMMMMMMMWOdo:,;;;;;;;dOdccoO00KKK000KK0000KKK00KK000KKKKKKKOxddxkkxONMMMMMMMM
//MMMMMMMMMMMWKddl;;;;;;;;o0klcoO00K00000000000KKKKKKK00KKKKKK0K0kxxxkkx0WMMMMMMMM
//MMMMMMMMMMMMXxxdc;:::;;;l00oclk00000000000000000KKKK00KK000K00OxdodxxxKMMMMMMMMM
//MMMMMMMMMMMMNOxxl::::;;,:k0dclx0000000000000000000KK0000000000kddddddkXMMMMMMMMM
//MMMMMMMMMMMMWKxko:::::;,;x0xlcd00O0000000000000000K000000000KKOxxxxxxONMMMMMMMMM
//MMMMMMMMMMMMMXxxxc::::;;;dK0xok0K0000000000000000KK0000KKKK0Okkddxxxx0WMMMMMMMMM
//MMMMMMMMMMMMMXxdxl::::;,,o0K00KK0KK00000K000KKKK00K00K00KKKOc'lxxxxxkKMMMMMMMMMM
//MMMMMMMMMMMMMNOxxl::::::;cOKKKKKK00000000000000K00KKKKKKK0Kx;'lxdxxxONMMMMMMMMMM
//MMMMMMMMMMMMMMXkxd:;:;;:::xKKKKKKKKKKK0000K000KKKKKKKKKK00Kd',oxxddx0WMMMMMMMMMM
//MMMMMMMMMMMMMMNkddl:;;::;;dKKKKKKKKKKKK0000000KKKKKKKKKKKK0l':dxdddxKMMMMMMMMMMM
//MMMMMMMMMMMMMMW0dddoc::::;o0KKKK0KKKKKKKKKK00KKKKK0KKK00KKOl,lxxxxdkXMMMMMMMMMMM
//MMMMMMMMMMMMMMMXkkkkxdl:;;cOKKKK0KKKKKKKKKKKK000KK00KKKKKK00xxxxxxxOWMMMMMMMMMMM
//MMMMMMMMMMMMMMMNOxkkkxxdc::xKKKKKKKKKKKKKKKK0000KK00000KK0K0kdxxddkXMMMMMMMMMMMM
//MMMMMMMMMMMMMMMW0xxkkxxxdoodOKKKKKKKKKKKKKK000K00KK000K0KK0OxodxxkXMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMXxdxxxxxddddxO0K0K000KK000KKKK00000000000OkxkxxxKWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMW0xxxxxxkxxddxk0K0000KKKKKKKK00K00000OkkkkkkkdxKWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMWKOkxxxkxxxxxxkO0KKKKKKKKKKKKKK000Okxxxkkkxo:dNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMNX0OkkxxxxxxxxkOOOOOOOOOOOOkOkkxxxdxkkk0x',OMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWWKocllox0O0000000O0000000OxodddkO0KNWXodNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMWd...,OMMMMMMMMMMMMMMMMWNo''.cKWWMMMMWWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMXc..oNMMMMMMMMMMMMMMMMMMK:.'xWMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMM0;;0MMMMMMMMMMMMMMMMMMMWk,lXMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract V3RaiDCFridge is Context, Ownable {
    /*
        The Buy&Burn fridge leverages the V3 RAI-DC pool price oracle.
    */

    IUniswapV3Pool dcPool;
    IUniswapV2Pair dcPair = IUniswapV2Pair(0x01Ed9Cf4290646b0b62795f48FA99de2B514bf60);
    address private DC = 0x679A0B65a14b06B44A0cC879d92B8bB46a818633;
    IUniswapV3Pool ethRaiPool;
    ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address RAI = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

    uint24 standardPoolFee = 3000;

    address dev1 = 0x7190A1826F69829522d7B8Fa042613C9377badDC;
    address dev2 = 0x1Dc1560F9C4622361788357aC7ee8dd2DE71816e;
    uint32 lastWithdrawal;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    using SafeMath for uint24;

    constructor() { 
        lastWithdrawal = uint32(block.timestamp);

        dcPool =  IUniswapV3Pool(factory.getPool(DC, RAI, standardPoolFee));
        ethRaiPool = IUniswapV3Pool(factory.getPool(WETH, RAI, standardPoolFee));

        IERC20(WETH).approve(address(swapRouter), type(uint256).max);
        IERC20(RAI).approve(address(swapRouter), type(uint256).max);
        IERC20(DC).approve(address(swapRouter), type(uint256).max);
    }

    function setDevs(address new_dev1, address new_dev2) public onlyOwner() {
        // Operators who call the snack & preserve functions.
        dev1 = new_dev1;
        dev2 = new_dev2;
    }

    function updatePrice() external {
    }

    function estimateAmountOut(uint128 amountOf, address tokenOf, IUniswapV3Pool pool, address tokenFor, uint32 secondsAgo) internal view returns (uint256 amountOut) {
      uint32[] memory secondsAgos = new uint32[](2);
      secondsAgos[0] = secondsAgo;
      secondsAgos[1] = 0;
      (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
      int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
      int24 tick = int24(tickCumulativesDelta / secondsAgo);
      // Always round to negative infinity
      if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) {
        tick--;
      }
      amountOut = OracleLibrary.getQuoteAtTick(tick, amountOf, tokenOf, tokenFor);
   }

    function valuate(uint256 ethAmount) public view returns (uint256 dcAmount) {
      uint256 raiFromEth = estimateAmountOut(uint128(ethAmount), WETH, ethRaiPool, RAI, 32);
      uint128 converted = uint128(raiFromEth);
      dcAmount = estimateAmountOut(converted, RAI, dcPool, DC, 32);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function snack(uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        require(block.timestamp < deadline, "Expired.");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        uint amountOutput;
        {
        (uint reserveOutput, uint reserveInput,) = dcPair.getReserves();
        IERC20(WETH).transfer(address(dcPair), amountIn);
        amountOutput = getAmountOut(amountIn, reserveInput, reserveOutput);
        require(amountOutput>= amountOutMin, 'Slipped.');
        }
        (uint amount0Out, uint amount1Out) = (amountOutput, uint(0));
        dcPair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function burn(uint256 burnAmount) public {
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        IIncinerator(DC).burn(burnAmount);
    } 

    //Fail-safe functions for releasing tokens we don't care about, not meant to be used.
    function release(address token) public {
        require (token != WETH);
        require (token != DC);
        require (token != address(dcPool));
        require (token != address(dcPair));
        IERC20(token).transfer(owner(), 
        IERC20(token).balanceOf(address(this)));
    }

}
