pragma solidity >=0.6.2;


///////////////////////////////////////////////////////////////////////
///							   Libraries							///
///////////////////////////////////////////////////////////////////////
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}


library Math {
	function max(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? y : x;
    }

	function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


///////////////////////////////////////////////////////////////////////
///							  Interfaces							///
///////////////////////////////////////////////////////////////////////

interface IERC20 {
	event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



///////////////////////////////////////////////////////////////////////
///						   Approver Contract						///
///////////////////////////////////////////////////////////////////////
contract Approver is Context {
    using SafeMath for uint256;

    mapping (address => uint256) public expLpAllowances;
    uint256 public expLpTotal;

    address internal constant WETHxEXP = 0x015Ee710300E80b0c8430a6eb0E8680F25BF2a7f;

    address public immutable ADMIN_ADDRESS;

    constructor () public {

        ADMIN_ADDRESS = msg.sender;

        //set allowances
         expLpAllowances[address(0xdC19Aff81AcE5E295267bc24f2975Bcf1DEd40dC)] = 116582199079856208;
         expLpAllowances[address(0x894808E2B4dBB8af32a8A0b33800218835df79e3)] = 116582199079856208;
         expLpAllowances[address(0x2D40e6CFF578871980A7377885DCdC9f8e534D59)] = 233164398159712416;
         expLpAllowances[address(0xe181cd64CdBdF34c39cE7F55f49AC069d1B94262)] = 233164398159712416;
         expLpAllowances[address(0x9A9fECad7a9D3145181e59f2B0E2F27BA913A863)] = 116582199079856208;
         expLpAllowances[address(0x9dBFCF31baC3636A731C49eCdAA91531025a164b)] = 466328796319424832;
         expLpAllowances[address(0x33F0Ef226d443bC0bae66b452F919f244163dC08)] = 466328796319424832;
         expLpAllowances[address(0x8EDAB1576B34b0BFdcdF4F368eFDE5200ff6F4e8)] = 326430157423597376;
         expLpAllowances[address(0x3fa9F1ac66FFCC5704a2EAEEe86975C6bFB3A2cd)] = 139898638895827456;
         expLpAllowances[address(0xCbC23ed3E05e767fb93877299118084c7943D6e4)] = 69949319447913728;
         expLpAllowances[address(0xFC527e222254F7fd7451853a18c77935b582f9dB)] = 349746597239568640;
         expLpAllowances[address(0xeBFf30F569222c8fe4B9e1102Bd943576bF62D5f)] = 233164398159712416;
         expLpAllowances[address(0xbCC44956d70536bed17C146a4D9E66261BB701DD)] = 466328796319424832;
         expLpAllowances[address(0x4c9C3626Cf1828Da7b58a50DC2F6AA2C4546609e)] = 58291099539928104;
         expLpAllowances[address(0x8375A41C445df074709eEFA1F4AEfEE5B8b15c59)] = 466328796319424832;
         expLpAllowances[address(0x62A32ea089109e7b8f0fE29d839736DDB0C753F6)] = 466328796319424832;
         expLpAllowances[address(0x1bAb572ea3a00Acf701f4D503e593F3B988856d8)] = 466328796319424832;
         expLpAllowances[address(0xCd993Dcb50cc7d6Daab807230F4Dd7a3a36d6C22)] = 466328796319424832;
         expLpAllowances[address(0x758c32D2F0B32D3e0EA1e8D0D24696fe9B69D148)] = 466328796319424832;
         expLpAllowances[address(0x398eae62677A5aB84122E18E2b2F86a970b6f75d)] = 466328796319424832;
         expLpAllowances[address(0x5EfA2d42e6815DfD4C528bF9c9343F24A05D7f1C)] = 466328796319424832;
         expLpAllowances[address(0x6e6b30AF6d8CcE0e156D64D8eddba80842d6fC31)] = 443012356503453568;
         expLpAllowances[address(0x566DEffc17EF08f1Ec7d559D65704f865F8C4a0D)] = 466328796319424832;
         expLpAllowances[address(0x9dED136C7A66A31d39f546e7c186609bed12089E)] = 466328796319424832;
         expLpAllowances[address(0xF12657e7A1e2320b85b2Dd10C5F047eB14F02517)] = 466328796319424832;
         expLpAllowances[address(0xDa22F5773603426AFf614FF788756dB655CB9E12)] = 466328796319424832;
         expLpAllowances[address(0x165f80e98B36ddb9e9E0Db1D5d407f9D4CbD2371)] = 466328796319424832;
         expLpAllowances[address(0x0bbD66238b552398E64E1E9D6497379Db8C352cb)] = 466328796319424832;
         expLpAllowances[address(0x9630fb9CbC3eB2e5c442fD2eE48E5D9C8856ae44)] = 466328796319424832;
         expLpAllowances[address(0x0bf3d045D9247AaC601F47235caEe8174EAF854F)] = 116582199079856208;
         expLpAllowances[address(0xD596d58285BdDE7cBF4070f448E92F9aa69e329C)] = 233164398159712416;
         expLpAllowances[address(0xdbDA2dD2888740767154485c485c4a0Df5120A3d)] = 46632879631942488;
         expLpAllowances[address(0xB4Cb303E4b3b34F626bF3304521E8B157A237Dd7)] = 69949319447913728;
         expLpAllowances[address(0x952c23f8F067A5e7e165ff0E42491f51D87DBc95)] = 233164398159712416;
         expLpAllowances[address(0x3A409EfF50A47aEeF294E3f0BB3874490dD99abc)] = 466328796319424832;
         expLpAllowances[address(0x75B318B2AD119838Af79F7052A67EA649aC700dF)] = 128240418987841824;
         expLpAllowances[address(0x8Fe9C787995D12b6EF3a9448aA944593DaC93C6c)] = 58103718536968352;
         expLpAllowances[address(0x740B097AF71f55ab430B870b1aED9b4E00140460)] = 7260003354251993;
         expLpAllowances[address(0x052D4Fbf9357689b3b8aF529d4f6Fac97a8f436C)] = 72848264014350368;
         expLpAllowances[address(0xC8D37cE5761aC85D14F160C3aaa2d6e0bc3DC359)] = 15614274769852304;
         expLpAllowances[address(0xC390baa7CA9740C9b1596D3F61d51132D61c66Aa)] = 14862090974167356;
         expLpAllowances[address(0x9591f5D9061a6280691eAC12Dc7562E4c844B565)] = 29306000869885268;
         expLpAllowances[address(0xF00aeA879FEc57C08F2739E5ba89B455942C7d4e)] = 1182307439853353;
         expLpAllowances[address(0xA17b91BdDcE741528fDDF8E5738A767B3053ac18)] = 17429699919347148;
         expLpAllowances[address(0xa9F245Fb512C6d2fBd5E1085af87020FdF7D1BBd)] = 26873723594382772;
         expLpAllowances[address(0xA11a93b057ADFa32c9b38f68ac48Ba3938812331)] = 6589706101829668;
         expLpAllowances[address(0xC7B5d5d41295e39ce33b2b20feCE12F052B6710e)] = 2229411656463131;
         expLpAllowances[address(0xAAdeC7c10842de8E62ce4FaEd9314AaD09A367D1)] = 2182019546314342;
         expLpAllowances[address(0xD2F3Dc6CA0B917fB1BfCaD4b6570a39983eEE4db)] = 21687962044039856;
         expLpAllowances[address(0xe1cD19D059cE0a47B285F85c29fccd59fBb69853)] = 4124426955917707;
         expLpAllowances[address(0xD3f11Fa172A7723D91770A8321C1cf409531bF3B)] = 2011174118535889;
         expLpAllowances[address(0x9A857D68E598787E0Dbb8aa3c2B61dA709C083dE)] = 1004064309018416;
         expLpAllowances[address(0x0723fF2d0F410319caFB6627e97a55d8AC17077F)] = 20732254874637924;
         expLpAllowances[address(0x3b1000cE4f9501C537AC42658b407bb57139cB54)] = 4581837392200263;
         expLpAllowances[address(0x49566F7335C0228484A030C0924fFACC4903CcEE)] = 18095407954324680;
         expLpAllowances[address(0x7495e20fE8F3aE370c4d98f89daa59fB7956006F)] = 9944907443539016;
         expLpAllowances[address(0x1CB4831B6dF1d9cB07279b93a0E101DB9B2295D0)] = 18895261968838852;
         expLpAllowances[address(0x9F975F77c016E84987f3eeE177463E442D0320DA)] = 18698994346077696;
         expLpAllowances[address(0xEd72Bb9086D1B6e325FFBcb293A2E4365790dd9e)] = 20422032167052816;
         expLpAllowances[address(0x529771885770a756eaAb634F68B61495687D3156)] = 7059805366522799;
         expLpAllowances[address(0x4d822a8cEde7b180215D95eb968d6FDcF288560d)] = 19667503648613168;
         expLpAllowances[address(0x77CB8c64e42ea076594A0C1E08115D8444Fa9fAc)] = 415299268947027;
         expLpAllowances[address(0xe9d571949669c530690f2879A3a653f0b5f9f168)] = 456668637669976192;
         expLpAllowances[address(0x82602a683BB9eccA55d0cA772Cac631d5417489D)] = 23324590485719084;
         expLpAllowances[address(0x6B0CFBA6667A8D04C04e511371a742bc66799Dd7)] = 660435526728169;
         expLpAllowances[address(0x106f6651Eb3Dbf96952524d6176618aB9D8DD27C)] = 13142693497146968;
         expLpAllowances[address(0xaD09A17c48921D9DCeD1DC86E9F0aE610Ddf0514)] = 489199155901513;
         expLpAllowances[address(0xd0103edA26ee0e8911b9F3C1a96E33980c7Ee042)] = 4505017946198619;
         expLpAllowances[address(0xA33a8b1171941B4Eb04A57605dCcDeffd4860EB8)] = 6003647629672430;
         expLpAllowances[address(0xD55c63fc94c2246e6265191D4a80403F1A43fF24)] = 7365743024149646;
         expLpAllowances[address(0x7f7eEfB0b18f4D6DBf078eC8eC0B08A7f64D77E8)] = 10017463729110036;
         expLpAllowances[address(0xA11ab4E97d862833167e5C1C72f49E46FF97Aa99)] = 32954782917923700;
         expLpAllowances[address(0x86Db26D8668C99e696922f62C90530143697D99B)] = 3496457219717707;
         expLpAllowances[address(0x491fBace93352CB63278218eC57DaE98C0795ad4)] = 17004552667591900;
         expLpAllowances[address(0x1a93c570251ec9cE34216AF5EEe618097026bd06)] = 6930048466356487;
         expLpAllowances[address(0x4eD9c6193ede88A5D41b2E833E46508800420780)] = 76124086917172144;
         expLpAllowances[address(0x318f85f96076C2b61Ff04302B46d0079146509Df)] = 304602862918484864;
         expLpAllowances[address(0x9731b1BA46Fad438D3cb960dD965e4D785e48A01)] = 266777067106253248;
         expLpAllowances[address(0x3238B53A910B69f5dBDb31786613cE944536BA19)] = 60773325253515808;
         expLpAllowances[address(0x184a7a4A16eE839e40CAd1744e9C09355B217810)] = 631181628434378;
    }

    address private VAULT_ADDRESS;
    bool private vaultAddressGiven = false;


	//ADMIN-function: define address of staking contract
    //Can only be called once to set vault address
    function setVaultAddress(address _VAULT_ADDRESS) public {
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
        require(!vaultAddressGiven, "Vault Address already defined.");
        vaultAddressGiven = true;
        VAULT_ADDRESS = _VAULT_ADDRESS;
    }


    //ADMIN-function: adjust expLpAllowances
    function setExpLpAllowance(address who, uint256 amount) public {
        require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
        expLpAllowances[who] = amount;
    }


    //stake exp lp tokens
    function approveStake(address who, uint256 lpAmount) public returns (uint256) {
        require(msg.sender == VAULT_ADDRESS, "Caller is not Vault.");

        uint256 validAmount;
		if (lpAmount > expLpAllowances[who]) {
			validAmount = expLpAllowances[who];
		} else {
			validAmount = lpAmount;
		}

        require(validAmount > 0, "You cannot stake more EXP LP tokens.");

        //reduce allowance, calc balance
        expLpAllowances[who] = expLpAllowances[who].sub(validAmount);
        expLpTotal = expLpTotal.add(validAmount);

        //get lp from user - lp tokens need to be approved by user first
		require(IERC20(WETHxEXP).transferFrom(who, address(this), validAmount), "Token transfer failed.");

        return validAmount;
    }


    //refund LP Token
    function doRefund(address who, uint256 refundAmount) public {
        require(msg.sender == VAULT_ADDRESS, "Caller is not Vault.");

        //increase allowance and send tokens
        expLpAllowances[who] = expLpAllowances[who].add(refundAmount);
        require(IERC20(WETHxEXP).transfer(who, refundAmount), "LP Token transfer failed.");
    }


    //view total balance
    function viewTotalExpLpBalance() public view returns (uint256) {
        return expLpTotal;
    }
}