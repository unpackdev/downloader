// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

contract yzyCITADEL is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    modifier canTransfer() {
        require(_msgSender() == address(0), "This token can't transfer.");
        _;
    }

    constructor () {
        _name = 'yzyCITADEL';
        _symbol = 'yzyCTD';
        _decimals = 18;
        _totalSupply = 122e18;

        _balances[0x04d79eF033e7b3039cF1556aD1B188A2C270FDD1] = 1e18;
        _balances[0x068994fDC513F4C61DEa5D52602c823bf5301FA3] = 1e18;
        _balances[0x09247BcA14D8222D563668771c3EAA2830A61dC4] = 1e18;
        _balances[0x0981F4663EaE659910357Daae7B9C66d4261e514] = 1e18;
        _balances[0x0CF31714d614322b9Cd93105c01f4B1c8717c2ED] = 1e18;
        _balances[0x0E96D498C134F006A3994424CAdF7687f5930A70] = 1e18;
        _balances[0x0Ef8582381874780e4CDbbeaEf8Bfa1F9cd34DAe] = 1e18;
        _balances[0x12042A785b8D3D9f8b24FDbEdd0c11B2B35dCFCE] = 1e18;
        _balances[0x125A32B12Bc520a5191d23D3a58c5cA4C64033F9] = 1e18;
        _balances[0x12670A2Cf547C47f3C8Cf9cAD5AEf114555B9be7] = 1e18;
        _balances[0x146503b3a53106f17D9BA759C6e2b16162d43652] = 1e18;
        _balances[0x15f0233D5F839f990dbA34ba8889432b82583d73] = 1e18;
        _balances[0x176D83328AAD92bdD088FA1fe1f7ece248d5Ee7A] = 1e18;
        _balances[0x20519479AeCf40C6E048203A150f5aa914ad2A60] = 1e18;
        _balances[0x21F17ac84f7B0E795101f97eE57681D639c36638] = 1e18;
        _balances[0x2353B9acAD5d915CD36ae98256f224Cc734A4305] = 1e18;
        _balances[0x245F698621c5F7d4B92D7680b78360afCB9df9af] = 1e18;
        _balances[0x2488f090656BddB63fe3Bdb506D0D109AaaD93Bb] = 1e18;
        _balances[0x25054f27C9972B341Aee6c0D373A652566075431] = 1e18;
        _balances[0x28Ac32ECA079e42D33FCFd1EE3bB5954846761ed] = 1e18;
        _balances[0x29E1D58Fb40E43E4E772cA803cC5764028f7Fb7d] = 1e18;
        _balances[0x2a6A8B9fA287Bbfa38c0159CD09E485a9C6D2A98] = 1e18;
        _balances[0x2B3352e94EB8bCC46391d89ec7A8C30D352027f8] = 1e18;
        _balances[0x2d4005AE33b1E5C05085D46e1ec27c2eF98b8b86] = 1e18;
        _balances[0x2F0780A7a231E492CD644658219d2BC8f31B50a1] = 1e18;
        _balances[0x32C167E1F6100f113edB55bFb5e1C729133261C9] = 1e18;
        _balances[0x3314d7Beede579C9D544Dbf51B32416F947eF2a4] = 1e18;
        _balances[0x36162C7B2D4a94686d74F8C9649769e1733Ee42E] = 1e18;
        _balances[0x42D455B219214FDA88aF47786CC6e3B5f9a19c37] = 1e18;
        _balances[0x46b4cde357189e141FFe1bEAEA4036dfa4e3D193] = 1e18;
        _balances[0x47262B32A23B902A5083B3be5e6A270A71bE83E0] = 1e18;
        _balances[0x4Ab68AA5163A3d7b0dAf780A8C9Da8df8b2bCc79] = 1e18;
        _balances[0x4b1bA9aA4337e65ffA2155b92BaFd8E177E73CB5] = 1e18;
        _balances[0x4DbE965AbCb9eBc4c6E9d95aEb631e5B58E70d5b] = 1e18;
        _balances[0x54F394b404c68bF824F69e4540C663173b454E8a] = 1e18;
        _balances[0x58ECE5D474e54AB50DD034959903347810B86B8f] = 1e18;
        _balances[0x59880058DBED37ec6ca8e29738a49C5Cc710Fce9] = 1e18;
        _balances[0x59a4a2f3814E42657E142af86878F4E380c704Fc] = 1e18;
        _balances[0x5a0533D0260AA288E113B34c6696F68670911A98] = 1e18;
        _balances[0x5Af08F5a0E43A3587cE7C8BfA21E77082e559F37] = 1e18;
        _balances[0x5Af8DA7F1b54E286895A36c1AF7af38c0d0A4b5D] = 1e18;
        _balances[0x62b85F0Dd05b3b0Ee8Ec0d4F3787486527eBdDb6] = 1e18;
        _balances[0x6a57b28E32EDf5B94c6A4d35a3367bba69214a5C] = 1e18;
        _balances[0x6b1CFe6E8EAC7e387671D4d493E691f96220F624] = 1e18;
        _balances[0x6Cb95a2B8F69e4a05e1aBFc2aE4E2dBA12d8c6D0] = 1e18;
        _balances[0x707D048708802Dc7730C722F8886105Ff07f0331] = 1e18;
        _balances[0x71f69CF35071E403f680Ae67be0Ff9A3496a5764] = 1e18;
        _balances[0x72b9E97d6321A628A365785eFd95F0Cd1a7A7005] = 1e18;
        _balances[0x74Dbf16a4ab7fD477Ed6bA82565Ce32e7Fa4c767] = 1e18;
        _balances[0x10FD23C4A9AC80A0e8F0c6f2D3589186a5bE3533] = 1e18;
        _balances[0x79C778b2daBD922Fcb6B0b872E50489c1E945f0f] = 1e18;
        _balances[0x7A53451bcFE3e3442dbE7b60E4A2BB3D39334c25] = 1e18;
        _balances[0x7D3fA0647911d7D967e0aC0C53E3E28cf9C7aFA7] = 1e18;
        _balances[0x7fCc3B4a05826c14afaFe6830F3511E9DDE48171] = 1e18;
        _balances[0x803b66997Aa50C08480C305C7D4fda49310DC4e8] = 1e18;
        _balances[0x820BB4C40AC66416E684BC12B8b46384Fa3aFAF2] = 1e18;
        _balances[0x83cc63E4fA4811D6102dF871d91Bf0CA3F24D820] = 1e18;
        _balances[0x84F28eB50EE410f362EfFc3Ec7f8cdC7301497F5] = 1e18;
        _balances[0x87ab8f2C5a5E85C9EC85AC853f31313385058F8d] = 1e18;
        _balances[0x8857cbF7bB9D45Da2969f24f950e00e07c975FC9] = 1e18;
        _balances[0x8A6c29f7fE583aD69eCD4dA5A6ab49f6c850B148] = 1e18;
        _balances[0x92048DB9D572F3D153d415A41502aD20e9756904] = 1e18;
        _balances[0x923B26470a3164FEc6911D9cbF66B0426C72d2E9] = 1e18;
        _balances[0x9382c1FBe902711275d309b9f3702B8D958C5e4D] = 1e18;
        _balances[0x9690f7E8Fc67E1F62109b58Da797C0Ec78CDCEd7] = 1e18;
        _balances[0x9E0eE8CAD01A4DFc4167D077B0e5227E0090141b] = 1e18;
        _balances[0xA024f75f00252D996369Cf1C0CbDc245C6264Ab6] = 1e18;
        _balances[0xA11a93b057ADFa32c9b38f68ac48Ba3938812331] = 1e18;
        _balances[0xa4BD82608192EDdF2A587215085786D1630085E8] = 1e18;
        _balances[0xa574469c959803481f25f825b41f1137BAfcF095] = 1e18;
        _balances[0xA6D6A1320fE6e26474b74623d4cDC02BA56073b1] = 1e18;
        _balances[0xA85a78a942fA046093e1D4440E5Bc1c887fe3f7C] = 1e18;
        _balances[0xAC5373587B5187346e25C1b0b47D60A7c2D22e21] = 1e18;
        _balances[0xad50d90B2Bf0aD70B8bC05e7002F1486d4149e7B] = 1e18;
        _balances[0xaDD1657f8a727C3245f4b6E5c9f0D914a5692f2e] = 1e18;
        _balances[0xb3C843c2E4834402Cab6D0a8bb2E88a75865FecE] = 1e18;
        _balances[0xb669b9E2613d7c3dF3F7E05521dc9721a9A92D10] = 1e18;
        _balances[0xC0a0ADD83f96f455f726D2734f2A87616810c04B] = 1e18;
        _balances[0xc45b3E05102A17eEc215d17AFb756F501552B5b8] = 1e18;
        _balances[0xc50546981EbB808f092B6e0634100e8E664f5662] = 1e18;
        _balances[0xC51F6396458E03F846af5AB2E049F608A5dCa87B] = 1e18;
        _balances[0xc64bd5763dB00FE121BafD9372F9b3632aB1Bb77] = 1e18;
        _balances[0xca6F7bCA983EFEc130245d18Ca62a72588000d89] = 1e18;
        _balances[0xCbC23ed3E05e767fb93877299118084c7943D6e4] = 1e18;
        _balances[0xCCa178a04D83Af193330C7927fb9a42212Fb1C25] = 1e18;
        _balances[0xcd30eA45715C478A3812963aAcfea8002dd9eAB8] = 1e18;
        _balances[0xd0BCFFcf931af6fe009Bceed7C172D81Aeb5CfD2] = 1e18;
        _balances[0xd25fA1a20b701e8b22E9c66D2702E5C2CBF752Dd] = 1e18;
        _balances[0xD670AD7009813940acb1A3D36Aa6160055565D57] = 1e18;
        _balances[0xd89b164AC89bDd21bC5de94b764BA56e88633801] = 1e18;
        _balances[0xD8F8C01bf25B9620ba033384E149CAA73875d0D0] = 1e18;
        _balances[0xD8Fbb76d51fCb06d6d8Dc29d0d3D69D2A6F41b0C] = 1e18;
        _balances[0xd93dcCE10767119fc89AD53917A0127B4Ecb784a] = 1e18;
        _balances[0xDb1e1981ad2B95DFfAb4A86C8a4eCef9E4B851f3] = 1e18;
        _balances[0xDB4b807DdcF7b263C183aD6e486E6a3AcC9d76A5] = 1e18;
        _balances[0xdE5bACc8880421fa08864D240627862E4423EAa2] = 1e18;
        _balances[0xE1860b7308B8B9ac9ff61AE86F27919AA8f70E8c] = 1e18;
        _balances[0xe24C2133714B735f7dFf541d4Fb9a101C9aBcb40] = 1e18;
        _balances[0xe2cf5FFFafA0f6e07BebEAac69895ea222D290e5] = 1e18;
        _balances[0xE3054fC03E36fFb252DAf7bA2cBFcAA2e3d24AC5] = 1e18;
        _balances[0xe5963480aCE624A003cb1645C75eF468d7d533C5] = 1e18;
        _balances[0xEb338d00E16E7f2018e3121D5f1e040265E92C30] = 1e18;
        _balances[0xeb42523A092CeaFb6b5b52b0a88d3F88154A3494] = 1e18;
        _balances[0xeD2a45611B967Df5647a17dFeaa0DEc40806De54] = 1e18;
        _balances[0xEdd2dab938801306D410808713e4aFE715FAc166] = 1e18;
        _balances[0xEFEa7c883B74eF2865D953D8fA46D6e654B8FFdf] = 1e18;
        _balances[0xf03b5F229A14B53094D9566642Fb5e2e7273586d] = 1e18;
        _balances[0xf1228C34651348F12d05D138896DC6d2E946F970] = 1e18;
        _balances[0xf2d2a2831f411F5cE863E8f836481dB0b40c03A5] = 1e18;
        _balances[0xF309921083CdaEB3758Bc8c24a4156eDfA64ca2F] = 1e18;
        _balances[0xf30b321970b3a4BBA00d068284F9E4C09D2befE1] = 1e18;
        _balances[0xf5f737C6B321126723BF0afe38818ac46411b5D9] = 1e18;
        _balances[0xf619aAf947bC74C0a0Ebf905E3D73cFe4c205DcF] = 1e18;
        _balances[0xf63370F0a9C09d53e1A410181BD80831934EfB19] = 1e18;
        _balances[0xf84975C731E88bd46c7017887b66C8e62efCe9A3] = 1e18;
        _balances[0xFF5a08d8b76943272F03ECfc274b0d60024a8686] = 1e18;
        _balances[0xFfC041B1c734f8bC0502A9Fc0d7c35AB437C416d] = 1e18;
        _balances[0x1d7A9b26223130c833FeD044d398D6179D39EfEE] = 1e18;
        _balances[0x29Bf6652e795C360f7605be0FcD8b8e4F29a52d4] = 1e18;
        _balances[0xdfa1c19a31257d29cC80aa4aeAc4FB0588727e28] = 1e18;
        _balances[0x266E02C82a01988404E8cfB2e0f78FE30DF02Df4] = 1e18;
        _balances[0x765Ed8c0A74645F29d3F9d1883e44Dd9435a30B9] = 1e18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override canTransfer returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override canTransfer returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}