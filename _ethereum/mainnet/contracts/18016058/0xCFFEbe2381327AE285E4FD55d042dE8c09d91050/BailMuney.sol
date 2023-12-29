// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
                   8 8                                                                                                                                  
                ad88888ba   88888888ba         db         88  88              88b           d88  88        88  888b      88  88888888888  8b        d8  
               d8" 8 8 "8b  88      "8b       d88b        88  88              888b         d888  88        88  8888b     88  88            Y8,    ,8P   
               Y8, 8 8      88      ,8P      d8'`8b       88  88              88`8b       d8'88  88        88  88 `8b    88  88             Y8,  ,8P    
               `Y8a8a8a,    88aaaaaa8P'     d8'  `8b      88  88              88 `8b     d8' 88  88        88  88  `8b   88  88aaaaa         "8aa8"     
                 `"8"8"8b,  88""""""8b,    d8YaaaaY8b     88  88              88  `8b   d8'  88  88        88  88   `8b  88  88"""""          `88'      
                   8 8 `8b  88      `8b   d8""""""""8b    88  88              88   `8b d8'   88  88        88  88    `8b 88  88                88       
               Y8a 8 8 a8P  88      a8P  d8'        `8b   88  88              88    `888'    88  Y8a.    .a8P  88     `8888  88                88       
                "Y88888P"   88888888P"  d8'          `8b  88  88888888888     88     `8'     88   `"Y8888Y"'   88      `888  88888888888       88       
                   8 8                                                                                                                                  

777777!77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::::
77777!7777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::::::::::::::::
77777!!77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::^::::::::::::::
7777777!!!!!!!!!!!!!77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::::::::
7777777!!!!!!!77!!!!7?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!~!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::::::
7777777777!!!!77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::::::
7777777!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::^:::::::::::
7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!~!~!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::
7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^^^:::
77777!77!!!!!!7!!!!!!!!!~~!!7!7!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::
7777777777!!!!!!!!!!!!!^~!!!7~!!!~~^^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
77777777777777!!!!!!!!~~~!~~~^^~~!~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~!!~!~:::::^^^~~~~!!!7?77!~~^^^~~^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
!7777777777777!!!!!~~^^~~^^~!!!!~:^^^^^~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~!!!!77?J?77!~^.   ..:^~!!!!7?JJJ?!^::.:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
777777777777777777!~^^^^~~~J~~~~J~^~^^:^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7??????JJ?77!!!~^^:......:^~!!!!7??YJ?!^......:::^^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
77777777777777777!77!!^^^^~J7~!7J~^~^^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!777????7777!~~^:.....::::::......^!!!!!!7JJ7!^:.......:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
7777777777777777777!7!^~!~^^!!!!^^~!~^!!!!!!!!!!!!!!!!!!!!!!!!!!!?YYJJJJJJJ?77!~^:..   ....::::::..:^^^^~~~~~!77!~~^::::.  :^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:
77777777777777777!!!!~^^~77!~^~^!!!~^^^!!!!!!!!!!!!!!!!!!!!!!!77JJJJJJJJJ??7!~~^:..   ....:::::^^^~~^^^^^^^^^^^^~~~~^:::::..:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
77777777777777777!!!!!!~~7!77!!~77!~~!!!!!!!!!!!!!!!!!!!!!!!!?JYJJJJJJJJ?777!!~~^:.    ..::^^^^^^^^^^~^^^^^^^^:..:^^^:.  ..:^^~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
777777777777777777!!7777!!!!!~~!7!!!!!!!!!!!!!!!!!!!!!!!!!!7Y5YJYYYYYJJJJ??777!!~~^..   ..:::^~~^^^^^^^:::^^^^^:.  .....     ..:^~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^
7777777777777777777!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!755YYYYYYYYYJJJJ???7!!~~^::..   ....:^^^:^^^^:::::^^^:::..             ..:^!77!~~^^^^^^^^^^^^^^^^^^^^^
777777777777777777777!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!?5PP5P5YYJJ5YYJJJJJ?77!!!~~^::.       .....:::^^:::::::..::..     ..     ..:~7?7!~~^^^^^^^^^^^^^^^^^^^^
7777777777777777777!7777777!77!!!!!!!!!!!!!!!!!!!!!!!!!!75PGGPPY55YJJYYJJJJ????77!!~~~~^^::..     ..:::::::::...........   .......:::~!777!!~~~~^^^^^^^^^^^^^^^^
777777777777777777777777777777777777777777!777!!!!!!!!!!JGGGGGGYY55JJYJJJJJJJ?7777!!!!!!~~^:..   ....:::::::....    ...  .......:::::~!!!!!!~~^~~^^^^^^^^^^^^^^^
7777777777777777777777777777777777777777777777!!!!!!!!77PGBBGGGP55YYJY?JJJ?JJ77!!77777!!!~~^:::.... ...:^^:::..         .....::^^:::::^~~~~!!!!!~^^^^^^^^^^^^^^^
7777777777777777777777777777777777777777777777!!7!!!!77JBBBBGG55PP5YJJ?!!77JY??7~7?77777!!~^::::...... .^~::....     .....:::^^:::::.:::^~~~!!!~~^^^^^^^^^^^^^^^
777777777777777777777777777777777777777777777777777777!5#BBGPPPPPP5YJJJ?~~~!7JJ7777777!7777~~~~^^^^:..  .:^^:::.   ..:::::::^^^^^^^^^~~~!~~~~!!!~~^^^^^^^^^^^^^^
7777777777777777777777777777777777777777777777777777777G#BGPPPP55555??Y777!~^~77!77!!!~!777!77!!!~~^^:..:::^^^::. ....:::::^:::^~~~~~~!!!!!~~~~~~~^^^^^^^^^^^^^^
777777777777777777777777777777777777777777777777777777?##GGGPP55555YYYJJJ?!~~~^~~!7!7?77??7777777!!~~^::....::..  ....::::^^^^^^~~~~!!!!!!~~~~~~^~^^^^^^^^^^^^^^
777777777777777777777777777777777777777777777777777777Y#BGGGPP55YY55JY5JJYYJ?!~::^!!!7???J?J?J7!!!!!!~^^:..........:~~~~^~~~~~~~!!!!!77!!!~~~~~~~^~~^^^^^^^^^^^^
777777777777777777777777777777777777777777777777777777PBGGBGP55555555YJYJJJJYYJ?!^~!!!7??JYYJ?7!~!!!~!~^^::.....^~~~~~!!!!!!7777!77!!7?!~~~~~~~~~~~~~^^^^^^^^^^^
77777777777777777777777777777777777777777777777777777?BBBBGPP555555Y55YY55YYYYYYYY?77?7!!7?JJJ?7!~~~~~^^^^^^::::^^^~~!77777777???7777??!~~~~~~~~~~~~~^~^^^^^^^^^
777777777777777777777777777777777777777777777777777775B##BBGPPP5Y555555555555555YYYYJJJJ?!7!7?JJ?!!777!~^^^~^^^^^^~~~!77??????JJJJ?7?Y7~~~~~~~~~~~~~~~~~~^^^^^^^
777777777777777777777777777777777777777777777777777775BB##BBGGP5555555555P55555PP555YYYJ?7777!77!77??YJ??7!!~~~^^~~~~!77!!!7??JYYY5J??!~~~~~~~~~~~~~~~~~~~~~~~~^
777777777777777777777777777777777777777777777777777J?YGGGGBBBGPPP5555555PPP55555555PPP5YYJ??7!!~~!!77?777!!77!!!!!7!!!!!7777J?Y5YYP5?!!~~~~~~~~~~~~~~~~~~~~~~~^^
777777777777777777777777777777777777777777777777777JJYPGPPGBGGPP5PPPP555PPPPP55555Y555PPP5YJ?777!!77?J?JJYJ?7777?J?77!7777??7?Y5JYYJ7~~~~~~~~~~~~~~~~~~~~~~~~~~^
77777777777777777777777777777777777777777777777777777?5GGPPPPPP5PP55P5PPP5P5YYJYYY55YJJ5PGGP5Y?????JJYYYJPPYYJ??77777?!~~!7!!7Y5JYJ7~~~~~~~~~~~~~~~~~~~~~~~~~~~^
777777777777777777777777777777777777777777777777777777YG#G5PP5555555PPPPP555YJJ?777??JJJ?JYY55JY55555Y5PJPPJJ?777!7777!!!!7777YYYY?~^~~~~~~~~~~~~~~~~~~~~~~~~~~^
777777777777777777777777777777777777777777777777777777?P#G5PPPP55555PPPPPP55P55P55Y?777777777?J55P5PP555Y5PJY?7??7??JY5555YY??YYJ7~~!!~~~~~~~~~~~~~~~~~~~~~~~~~~
7777777777777777777777777777777777777777777777777777777JBGPPB#B55555PPPPPPPPPGGGBGBBBGP55YY5PPPGGGGGPPGPPPGPGGGGGBBB#BBBBBB5775YJ?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
77777777777777777777777777777777777777777777777777777777PPPGB#B55555PPPPPPPPPGGG#GG&@&&&B##BGBB#BBGGGPPPBBBBB#BB&&&&BPPGGBP?7!55Y?!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
77777777777777777777777777777777777777777777777777777777JGPG##5Y5555PPPPPPPPPPP5PGGB##BGGB##BBB##BG5Y??JP&#B#&#GBBBG5J?7J??7!!JJ?!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~
777777777777777777777777777777777777777777777777777777777PGGB&B5555PPPPPPPPPPPPPPPPPPPPGGGBBBBB#BG5Y?7!7?##BBBBGP5YYJJJ777!~~77~~!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~
777777777777777777777777777777777777777777777777777777777JPPPG##5PPPPPPPP55PPPPPPPPPGPPGGBBBBBGGGP5Y?!~~7YBBGBBGPPPPPP5J?7~~!?~^!!!!!!!!!!~!!!!!!!~~~~~~~~~~~~~~
77777777777777777777777777777777777777777777777777777?77?7JPP5PGPPPPPPPPP555PPPPPGGGGGGGGGGGGP5PPP5J?!~~!?J5PPGGGGGP5Y7!!~~~7?~^!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~
777777777777777777777777777777777777777??????77777??777????YPGPPGGPPPPPPPPPPPPPPPGGGPPPPPPPPGPPPPPYJ?!~~!?JJYYJJJJ?7!777!!!7?777!!!!!!!!!!!!!!!!!!!!!!!!~~!~~~~~
77777777777777???????7777777??7????????7??????????????7?????JPGGGGGPPPPPGGPPPPPPGGGGGPPP555PGGPPPYJJ7~:^!7YJJ??777????????JY?777!!!!!!!!!!!!!!!!!!!!!!!!~!!!!~~~
77777777777????????????????????????????????????????????????????G&GPPPPPPPGGGGGPGGGGGPPP5555PGBBGGJ??!^:^~~YGY?7777???JJY555J777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~
77777777???????????????????????????????????????????????????7??P@@?PPPPPPGGGGGGGGGGPPPP5555PGB#BBP7777!~~^:!BGJ?777??JYY5P5?7777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~
?7???????????????????????????????????????????????????????J5G#&@@G~PGPPPGGGGPPGGGGGGPPPPPPPPB&B5P5?7!~~~^::^!BGY?????JJY5Y???7777!777!!77!!!!!!!!!!!!!!!!!!!!!!!~
?????????????????????????????????????????????????????J5B#&@@@@@@J!JBGGGGGGGPPGGGGGGPPPPPPPGB#GGBGYJ?777!~~???BPYJ7?JJJJJ?????7!7777777!77!!!!!!!!!!!!!!!!!!!!!!~
7????????????????????????????????????????????????Y5G#&@@@@@@@@@@?!!GBBGGGGGPPPPPGGGPPPPPPPPGGB###BGPPGPPG#Y^~7PPYJ?7???77??7YY??77!!!!!!!!!77!77!!!!!!!!!!!!!!!!
??????????????????????????????????JJJ??????JYPG#&@@@@@@@@@@@@@@@?!!?GBBGGGGGPPPPPGGGGGGPPPPGGGGGGGGGGGGB#G!^~~!5G5YJ77!77?7J#BBBBGPP5YJ?7!!!!!777!!!!!!!!!!!!!!!
????????????????????J????JJ?????????JY5PG#&&@@@@@@@@@@@@@@@@@@@@P!!!JGBBBGGPPPPPGPGGGGGP5PGGGGGGGGGGGG#G?~~!~!~^?PY?77!!777G#BBBBBBBBBBBBGP5J?77!!!!!!!!!!!!!!!!
?????????????????J?JJJ??????JY5PGB#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@#!!!!?GBBBGGPGGGGGGGGGPPPPGGGGGGGGGGGB5!!!!!!!7!~!YY7!!77?5&BBBBBBBBBBBBBBBBBBBBGP5JJ?777!!!!!!!
????????JJJJJJJJJJ????JY5G#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J!!!!7PBBBGGGGGGGGGGGGGGGGGGPPGGGGGB57?JJ?77J55Y?!7J?77?5&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBG5Y?7!!
???????JJJJJ?J???JYPG#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G?!!!!!YGBBGGGGGGPGGGGBBBGGGGGBBB###B#BGP5YJJ5B#B577J??Y#&##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG5
????JJ?J????JY5G#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&57!!!!!7P##GGGGGGGGGBBGGGGGGGGGGGGPP5YY5PP5?77JG#5JYJY######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG
???????JYPGB#&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ7!!!!!!?G#BGGGGGGGGGGGGGGGBBBBBB###&&#BGGGP5JJGBPPP##BB####BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG
??JYPGB#&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5J7!!!!!~!JGBBGGGGGGGGGGGGBBBBBBGGPYJ?777?77!77?5BP5&#BB#####BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
PB#&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BYJ77!!!!~~~?PBBGGGGGGGGGGGGGBGJ7777!!!!!!!!7?YY7: 7&#BBB######BBBBBBBBBBBBBBBBBBBBBBBBBBBB#B
&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&YJ??7!!~~~~~~7YPGGGGGGGGGGGGBGGPYJJJJ???7?J?^.    ^##BB#######BBBBBBBBBBBBBBBBBBBBBBBBBB###B
&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5J??77!!~~~~~~~!?5GGGGGGGBGGGGGGGPP5555PP5J:      .B#BBB########BBBBBBBBBBBBBBBBBBBBB######B
&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ??777!!!~~~~~~!!?PGGGGGGBBBBGGGGGP5YJ?7!^        5#BBB#########BBBBBB#BBBBBBBBBBBB########
&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J??7777!!~~~~~~~~~!J5PPPPBBBP5YYJ7!~~~~~~.        ?&BBB#########BBBBB##BBBBBBBBBB##########
&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5?77777!!!~~~~~~~~~~~~!Y#&&&#B57~^~~~~~!^         !&BBBB########BBBB##BBBBBBBBBB#########&#
&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#??7777!!!~~~~~~~~^^!5#@&&&@@@@&BY!~~~~^.         :#BBB###############BBBBBBBB######&&##&&#
&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J?777!!!!!~~~~~^~?B&&&&&&&&&&&&&@&5!~~.          .B#BB#############BBBBBBBBB######&&&&#&&#
&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5?777!!!!!~~~~~!?5#&&&&&&&&&&&&&&PJJ?!.          .G#BB###############BBB##B######&&&&###&#
&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B??777!!!!~!!7??Y!7JP#&&&&&&&&&B?!!!!!!:.        .5&BBB##########################&&&&&##&#
&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J?77!!!!!7?JJ??Y7!!7JB&&&&&&&B?777!!!!!~^:       J&BBB#########################&&&&&###&#
&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P?77777??JJJJ?JY7!!77P&&&&&&&5JJ?!^::......      7&#B##########################&&&&&&##&#
&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#??????JJJJ?JJJJ7!77Y&@&&&&&&J??~:               ^##BB#########################&&&&&&##&#
@&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@JJJ??JJJJ??????777Y#@&&&&&&&#?!^.               .##BB#########################&&&&&&&&&#
@@&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P?JJJYJ????????77JB&&&&&&&&&&5^..               .G#BB#########################&&&&&&&&&#
@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7?YYY?777777???75&&&&&&&&&&#B^                  P&BB########################&&&&&&&&&&#

    Website: https://bailmuney.com
    Twitter: https://twitter.com/BAILMUNEY
    Telegram: https://t.me/bail_portal

**/

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(address from, address to, uint256 value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

interface IUniswapV2Router02 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

contract BailMuney is ERC20, Ownable {
	using SafeMath for uint256;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public uniswapV2Pair;
	address public constant deadAddress = address(0xdead);

	bool private swapping;

	address public teamWallet;
	address public immutable dev;

	uint256 public maxWallet;
	uint256 public maxTransactionAmount;
	/// @notice Current percent of supply to swap tokens at (i.e. 5 = 0.05%)
	uint256 public swapPercent;

	bool public limitsInEffect = true;
	bool public tradingActive = false;
	bool public swapEnabled = false;

	bool public blacklistRenounced = false;

	// Anti-bot and anti-whale mappings and variables
	mapping(address => bool) blacklisted;

	uint256 public buyTotalFees;

	uint256 public sellTotalFees;

	/******************/

	// exclude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) public _isExcludedMaxTransactionAmount;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

	event ExcludeFromFees(address indexed account, bool isExcluded);

	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

	event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);

	event TradingEnabled(address indexed pair, uint ethAmount, uint tokenAmt, uint block);

	/// @dev only dev can do these special commands once renounced ownership.
	modifier onlyDev() {
		_checkDev();
		_;
	}

	function _checkDev() internal view virtual {
		require(dev == _msgSender(), "Dev: caller is not based!");
	}

	constructor(address _teamWallet) ERC20("$BAIL_MUNEY", "BAIL") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		excludeFromMaxTransaction(address(_uniswapV2Router), true);
		uniswapV2Router = _uniswapV2Router;

		// dev is our deployer
		dev = owner();
		teamWallet = address(_teamWallet);

		uint256 totalSupply = 696_969_696_969_696 * 1e18;

		maxTransactionAmount = (totalSupply * 2) / 100; // 2%
		maxWallet = (totalSupply * 2) / 100; // 2%
		swapPercent = 5; // 0.05%

		buyTotalFees = 10;
		sellTotalFees = 38;

		// exclude from paying fees or having max transaction amount
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(teamWallet, true);
		excludeFromFees(address(0xdead), true);

		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		excludeFromMaxTransaction(teamWallet, true);
		excludeFromMaxTransaction(address(0xdead), true);

		// mint 100% here
		_mint(address(this), totalSupply);

		// transfer % to newOwner
		_transfer(address(this), dev, (totalSupply * 10) / 100); // 10%
	}

	receive() external payable {}

	// once enabled, can never be turned off
	function enableTrading() external payable onlyOwner {
		require(!tradingActive, "Trading is already enabled, cannot relaunch.");
		uint256 liquidityTokens = balanceOf(address(this)); // 100% of the balance assigned to this contract
		require(msg.value > 0, "Send liquidity eth");
		require(liquidityTokens > 0, "No tokens!");

		// setup the approvals
		uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
		excludeFromMaxTransaction(address(uniswapV2Pair), true);
		_setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

		IERC20Metadata weth = IERC20Metadata(uniswapV2Router.WETH());
		weth.approve(address(uniswapV2Router), type(uint256).max);
		_approve(address(this), address(uniswapV2Router), type(uint256).max);
		// add the liquidity
		uniswapV2Router.addLiquidityETH{value: msg.value}(
			address(this),
			liquidityTokens,
			0,
			0,
			owner(),
			block.timestamp
		);
		// set the params and emit
		tradingActive = true;
		swapEnabled = true;
		emit TradingEnabled(uniswapV2Pair, msg.value, liquidityTokens, block.timestamp);
	}

	/// @notice Returns at what percent of supply to swap tokens at.
	function swapTokensAtAmount() public view returns (uint256 amount_) {
		amount_ = (totalSupply() * swapPercent) / 10_000;
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(!blacklisted[from], "Sender blacklisted");
		require(!blacklisted[to], "Receiver blacklisted");

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (limitsInEffect) {
			if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
				if (!tradingActive) {
					require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
				}

				//when buy
				if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
					require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
					require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
				}
				//when sell
				else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
					require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
				} else if (!_isExcludedMaxTransactionAmount[to]) {
					require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
				}
			}
		}

		uint256 contractTokenBalance = balanceOf(address(this));

		bool canSwap = contractTokenBalance >= swapTokensAtAmount();

		if (
			canSwap &&
			swapEnabled &&
			!swapping &&
			!automatedMarketMakerPairs[from] &&
			!_isExcludedFromFees[from] &&
			!_isExcludedFromFees[to]
		) {
			swapping = true;
			swapBack();
			swapping = false;
		}

		bool takeFee = !swapping;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		// only take fees on buys/sells, do not take on wallet transfers
		if (takeFee) {
			uint256 fees = 0;
			// on sell
			if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
				fees = amount.mul(sellTotalFees).div(100);
			}
			// on buy
			else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
				fees = amount.mul(buyTotalFees).div(100);
			}

			if (fees > 0) {
				super._transfer(from, address(this), fees);
			}

			amount -= fees;
		}

		super._transfer(from, to, amount);
	}

	function swapTokensForEth(uint256 tokenAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function swapBack() private {
		uint256 contractBalance = balanceOf(address(this));
		bool success;

		if (contractBalance == 0) {
			return;
		}

		if (contractBalance > swapTokensAtAmount() * 20) {
			contractBalance = swapTokensAtAmount() * 20;
		}

		uint256 initialETHBalance = address(this).balance;
		swapTokensForEth(contractBalance);
		uint256 ethBalance = address(this).balance.sub(initialETHBalance);

		(success, ) = address(teamWallet).call{value: ethBalance}("");
	}

	/// @dev - Getter/Setter Functions

	// remove limits after token is stable
	function removeLimits() external onlyOwner {
		limitsInEffect = false;
	}

	/// @notice Update percent of supply to swap tokens at. 1 = 0.01%
	function updateSwapTokensAtPercent(uint256 newPercent) external onlyOwner returns (bool) {
		require(newPercent >= 1, "Swap amount cannot be lower than 0.01% total supply.");
		require(newPercent <= 50, "Swap amount cannot be higher than 0.50% total supply.");
		swapPercent = newPercent;
		return true;
	}

	// only use to disable contract sales if absolutely necessary (emergency use only)
	function updateSwapEnabled(bool enabled) external onlyOwner {
		swapEnabled = enabled;
	}

	function updateBuyFees(uint256 _newBuyfee) external onlyOwner {
		buyTotalFees = _newBuyfee;
	}

	function updateSellFees(uint256 _newSellFee) external onlyOwner {
		sellTotalFees = _newSellFee;
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}

	function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
		_isExcludedMaxTransactionAmount[updAds] = isEx;
	}

	function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
		require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.5%");
		maxTransactionAmount = newNum * 1e18;
	}

	function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
		require(newNum >= ((totalSupply() * 10) / 1000) / 1e18, "Cannot set maxWallet lower than 1.0%");
		maxWallet = newNum * 1e18;
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		automatedMarketMakerPairs[pair] = value;
		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function isBlacklisted(address account) public view returns (bool) {
		return blacklisted[account];
	}

	function renounceBlacklist() public onlyOwner {
		blacklistRenounced = true;
	}

	function blacklist(address _addr) public onlyOwner {
		require(!blacklistRenounced, "Team has revoked blacklist rights");
		require(
			_addr != address(uniswapV2Pair) && _addr != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
			"Cannot blacklist token's v2 router or v2 pool."
		);
		blacklisted[_addr] = true;
	}

	// @dev blacklist v3 pools; can unblacklist() down the road to suit project and community
	function blacklistLiquidityPool(address lpAddress) public onlyOwner {
		require(!blacklistRenounced, "Team has revoked blacklist rights");
		require(
			lpAddress != address(uniswapV2Pair) && lpAddress != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
			"Cannot blacklist token's v2 router or v2 pool."
		);
		blacklisted[lpAddress] = true;
	}

	// @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
	function unblacklist(address _addr) public onlyOwner {
		blacklisted[_addr] = false;
	}

	// @dev - dev only commands.

	function updateTeamWallet(address newWallet) external onlyDev {
		require(newWallet != address(0), "Cannot be the zero address");
		teamWallet = newWallet;
		excludeFromFees(newWallet, true);
		excludeFromMaxTransaction(newWallet, true);
		emit TeamWalletUpdated(newWallet, teamWallet);
	}

	function withdrawStuckToken() external onlyDev {
		uint256 balance = IERC20(address(this)).balanceOf(address(this));
		IERC20(address(this)).transfer(msg.sender, balance);
		payable(msg.sender).transfer(address(this).balance);
	}

	function withdrawStuckToken(address _token, address _to) external onlyDev {
		require(_token != address(0), "_token address cannot be 0");
		uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).transfer(_to, _contractBalance);
	}

	function withdrawStuckEth(address toAddr) external onlyDev {
		(bool success, ) = toAddr.call{value: address(this).balance}("");
		require(success);
	}
}
