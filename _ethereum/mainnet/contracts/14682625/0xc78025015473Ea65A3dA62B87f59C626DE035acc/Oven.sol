import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IFridge.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

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

contract BasicV2Oven is Context, Ownable{
    /*
        The Oven's job is to consume tokens and send WETH to the fridge.
        The BasicV2Oven is designed for those poor tax-on-transfer tokens that are
        stuck in antiquated UniSwap pools.
    */
    IUniswapV2Factory factory;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping (address => bool) private _targeted;
    mapping (address => uint8) private tax;
    mapping (address => uint256) private batchsize;
    // Sandwich-resistance:
    struct PriceReading {
        uint64 ethReserves;
        uint64 tokenReserves;
        uint32 block;
    }
    mapping (address => PriceReading) reading1;
    mapping (address => PriceReading) reading2;
    IFridge _fridge;
    address dev1;
    address dev2;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    event UsingFridge(address fridge);

    constructor (address fridge) {
        replaceFridge(fridge);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }

    function addTarget(address token, uint8 new_tax, uint256 new_batchsize) public onlyOwner() {
        // Record the exact cooking instructions for new targets
        require(new_tax < 100);
        require(new_batchsize > 0);
        _targeted[token] = true;
        tax[token] = new_tax;
        batchsize[token] = new_batchsize;
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(factory.getPair(token, WETH)).getReserves();
        (uint ethReserves, uint tokenReserves) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        PriceReading memory initialReading;
        initialReading.ethReserves = uint64(ethReserves / 10**9);
        initialReading.tokenReserves = uint64(tokenReserves / 10**9);
        initialReading.block = uint32(block.number);
        reading1[token] = initialReading;
        reading1[token].block = uint32(block.number - 1);
        reading2[token] = initialReading;
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
        // Take a new price reading from Uniswap.
        PriceReading storage my_reading1 = reading1[token];
        PriceReading storage my_reading2 = reading2[token];
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(factory.getPair(token, WETH)).getReserves();
        (uint ethReserves, uint tokenReserves) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        if (my_reading1.block < my_reading2.block && my_reading2.block < block.number) {
            my_reading1.ethReserves = uint64(ethReserves / 10**9);
            my_reading1.tokenReserves = uint64(tokenReserves / 10**9);
            my_reading1.block = uint32(block.number);
        } else if (my_reading1.block > my_reading2.block && my_reading1.block < block.number) {
            my_reading2.ethReserves = uint64(ethReserves / 10**9);
            my_reading2.tokenReserves = uint64(tokenReserves / 10**9);
            my_reading2.block = uint32(block.number);
        }
    }

    function getReserves(address token) internal view returns (uint256 ethReserves, uint256 tokenReserves) {
        // Retrieves recorded pool reserves.
        PriceReading memory toRead = reading1[token].block < reading2[token].block ? reading1[token] : reading2[token];
        ethReserves = uint256(toRead.ethReserves) * 10**9;
        tokenReserves = uint256(toRead.tokenReserves) * 10**9;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function apply_tax(uint amount, address token) internal view returns (uint256) {
        return amount.mul(100 - tax[token]).div(100);
    }

    function getValues(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue) {
        // Estimates value of a given amount of target token, based on market conditions.
        require(_targeted[token]);
        (uint256 ethReserves, uint256 tokenReserves) = getReserves(token);
        ethValue = getAmountOut(apply_tax(apply_tax(amount, token), token), tokenReserves, ethReserves);
        paperValue = apply_tax(apply_tax(amount.mul(ethReserves) / tokenReserves, token), token);
    }

    function otcOffer(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue, uint256 vestedTime) {
        // Provides the estimated values back to DC, along with the "cook time" for the vest.
        require(_targeted[token]);
        (ethValue, paperValue) = this.getValues(token, amount);
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        uint nPeriods = tokenBalance.add(amount) / batchsize[token];
        vestedTime = block.timestamp.add(7 days).add(nPeriods.mul(1 days));
    }

    function cook(address token, uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        // Liquidates target tokens and passes the profits along to the fridge.
        require(block.timestamp < deadline, "Expired");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Only chefs allowed in the kitchen!");
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, WETH));
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
