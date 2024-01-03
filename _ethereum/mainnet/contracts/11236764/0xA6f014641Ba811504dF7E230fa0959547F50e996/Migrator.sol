pragma solidity ^0.4.24;


 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Migrator {
    address public CHARGED;
    address public VOLTS;
    address public devAddress;
    mapping(address => uint256) CHARGEDBalances;



    constructor(address _CHARGED, address _VOLTS) public {
        CHARGED = _CHARGED;
        VOLTS = _VOLTS;
        devAddress = msg.sender;
        populateMapping();
    }

    function transmute(uint _amount) external {

        require (
            CHARGEDBalances[msg.sender] > 0, 
            "No CHARGED balance"
        );

        require(
            SafeMath.sub(CHARGEDBalances[msg.sender], _amount) >= 0, 
            "Insufficient CHARGED balance"
        );

        
        require(
            IERC20(CHARGED).transferFrom(msg.sender, address(this), _amount),
            "CHARGED transfer failed"
        );
        
        uint256 transferAmount = SafeMath.div(_amount, 2);
        CHARGEDBalances[msg.sender] = SafeMath.sub(CHARGEDBalances[msg.sender], _amount);
        
        require(
            IERC20(VOLTS).transfer(msg.sender, transferAmount),
            "VOLTS transfer failed"
        );
    }
    
    function returnFunds() public {
        require(msg.sender == devAddress, "Cannot perform this action");
        IERC20(VOLTS).transfer(msg.sender, IERC20(VOLTS).balanceOf(this));
        IERC20(CHARGED).transfer(msg.sender, IERC20(CHARGED).balanceOf(this));
    }

    function availableSwapBalance(address _address) external view returns(uint256){
        return CHARGEDBalances[_address];
    }

    function populateMapping() internal{
        CHARGEDBalances[0x000000000000084e91743124a982076c59f10084] =  1;
        CHARGEDBalances[0x0000000071e801062eb0544403f66176bba42dc0] =  1;
        CHARGEDBalances[0x000000a61aa8c4e48a832cc39655ef8156097aa2] =  1;
        CHARGEDBalances[0x0079e5a13ae87e7af9fb710216fba413b0062277] =  267694596758486000;
        CHARGEDBalances[0x00a9ddfa3ea4a6a29abb8fee65b8ea5b2c722730] =  5873445291704500000;
        CHARGEDBalances[0x00e6e9b5f984e609dd6e6873d9355d8714859754] =  1519547073954750000;
        CHARGEDBalances[0x012916ed48b20433b698cb32b488e52c639a2a66] =  237183521209852000;
        CHARGEDBalances[0x01368f7aa6f1ad5d0ce99b0f37e994e874f630b4] =  1;
        CHARGEDBalances[0x0228d303473dba1d64a1ebdf22ffa011408bf93c] =  1050881498074960000;
        CHARGEDBalances[0x0403f317873d2c52f8b210c27e4cec0f14e00312] =  9336997850757710000;
        CHARGEDBalances[0x0520d6094b8e10948211aa574e6809f52eee30f8] =  620190146874594000;
        CHARGEDBalances[0x05eb7f0ebcfc8bee7d5283521a08ebef149569ed] =  14250000000000000000;
        CHARGEDBalances[0x06c975751658c6349862a1705f6852a212379a14] =  948867654455209000;
        CHARGEDBalances[0x0799442ce0f90f8837fdeece82cd2735625b4bf9] =  156012622214125000;
        CHARGEDBalances[0x07ea9230a3da74cf3f7080069b8a102e74b66c26] =  971312868042678000;
        CHARGEDBalances[0x080061ff771d2344954f588b984e746b9fb5a244] =  195276176599368000;
        CHARGEDBalances[0x0855f08e143e1db081cc3c571f40787dcfb69b9d] =  1140000000000000000;
        CHARGEDBalances[0x09dfa9bc0faa770c5e5873442c97e0dd54ab3916] =  1344235124284440000;
        CHARGEDBalances[0x09f2c78e77260c078cbb5191f0c54c6c2277010e] =  980000000000000000;
        CHARGEDBalances[0x0bfdce45ec0005f393e4c345179a60c113177a04] =  599000000000000000;
        CHARGEDBalances[0x0e87257112b8841517380851a319180e09f34438] =  474478871338209000;
        CHARGEDBalances[0x0fc58f8f1b078a35a69c951e3e8ae477fb5fdef1] =  212776562547036000;
        CHARGEDBalances[0x106a960f6b9f85699319b9244eab4b2133f57ef7] =  1506306521771880000;
        CHARGEDBalances[0x11825c571b48d06e033eca251522f6d65610d99c] =  802737957635692000;
        CHARGEDBalances[0x11dcb306e31798206b9ea2381725a3990dffe0c6] =  3695894188977260000;
        CHARGEDBalances[0x126da110a5ea0a849c65f6f51d43098245bb7f5d] =  101083441973728000000;
        CHARGEDBalances[0x1299bbf9b60ff5d0e8f9f3c4d39f609ff86736fb] =  2066234143603850000;
        CHARGEDBalances[0x1312550a2b48ced7d5ee04f5a150e9a0ca3f22f2] =  8977736946109130000;
        CHARGEDBalances[0x14a3d16c7aa0c51f2ce004e5face2f84874b027e] =  444858983139614000;
        CHARGEDBalances[0x14e2effd5f0bee065cc10cc6c1891a77ab8b2f57] =  222973802844588000;
        CHARGEDBalances[0x184c2b6ab4fb28f9a092ea66df398ba8019681fa] =  394677788973508000;
        CHARGEDBalances[0x1a93c570251ec9ce34216af5eee618097026bd06] =  1562461157484330000;
        CHARGEDBalances[0x1a94c85fd6f02638a1209b8a96184292bf5cb405] =  681636445083521000;
        CHARGEDBalances[0x1b7aa51b26564804c497cbd8db15886645ebf4ad] =  118902196541638000;
        CHARGEDBalances[0x1bc64307e6ddc620635b862fd2051be32bbf26a3] =  14251742980184700000;
        CHARGEDBalances[0x1ce1d70523bf3660d66eaff6aa3aa21d86671b77] =  2501011099961340000;
        CHARGEDBalances[0x1d5fe8351abbce2c7d65224d5c8661bf78b1c4e2] =  100000000000000000000;
        CHARGEDBalances[0x1deb8041a866b1b17c31051003537eeb7d6ae146] =  35453530911222800000;
        CHARGEDBalances[0x1e58a2934f4015be77fb1d8248c0013344c5dc01] =  266000000000000000;
        CHARGEDBalances[0x1e946be3f1e8e01c69517f5f4b4cfe28586f9af7] =  5072871084156350000;
        CHARGEDBalances[0x1f634d48fd9fc9e6a9c27c19d28679cec64be963] =  1097473002341280000;
        CHARGEDBalances[0x21f894dbbdd5edb552687e540c8d0db1d0043d22] =  32754191971790100;
        CHARGEDBalances[0x22626ad06127744167700aaf52e07e8459702939] =  84787911120522700;
        CHARGEDBalances[0x250b680b857bf561f5839c8bf5169907b6cf229c] =  13489869761980700;
        CHARGEDBalances[0x26a443b6a388530f3852f48443cd50d75a070964] =  24560761477270800000;
        CHARGEDBalances[0x2844e9686bf83ac41b28caf9f6e8b018d9b8d5a9] =  3325183965094390000;
        CHARGEDBalances[0x28537039d9bcad6f66c8c8a3f95997d9866c5207] =  742267817833519000;
        CHARGEDBalances[0x29458f736833e336b4209b4514685f3dd98fb4a6] =  98000000000000000;
        CHARGEDBalances[0x2bd581ed4f840a5493552551bc7db6d074c0a594] =  96062168450607200;
        CHARGEDBalances[0x2c4997a28bcd5dcd87080b2209b3b5cba3137e48] =  569734640934261000;
        CHARGEDBalances[0x2cc7f8513680c7e6da091f7e96a5228ae4c1d583] =  485231578976281000;
        CHARGEDBalances[0x3073ca162b2ba228b913fcbdcbd275c08bb8c408] =  9484434112210680000;
        CHARGEDBalances[0x3141c650773055e3be54e5a82ad457137cdf51d6] =  2187686654198090000;
        CHARGEDBalances[0x337a7d6ac92db8181da2e172b6a6aa60b2e31b4c] =  502937332598408000;
        CHARGEDBalances[0x33ad4555126530148e19fe3a1d7cf02c7f31ca13] =  158489563901630000;
        CHARGEDBalances[0x344bb243fd288370bbf6124e9771300f5c125c56] =  539982194125725000;
        CHARGEDBalances[0x345c203870257119c00e72a76894e5a30211da20] =  857110599091651000;
        CHARGEDBalances[0x353d29ad13cd34cbb190d25975975f5bbfded072] =  1080950093435580000;
        CHARGEDBalances[0x356ae8934c4b45357af9f3d0b716f26c1968152f] =  324388722168513000;
        CHARGEDBalances[0x376a80f1532e3124ade38889f35ada85f212c3c8] =  2747946769680020;
        CHARGEDBalances[0x3832366cc385dd16c8ff5bef099f4139a81ea676] =  1458833869251360000;
        CHARGEDBalances[0x383d8272f27b9e116bbde35871d0942529ede3e6] =  2197849903636300000;
        CHARGEDBalances[0x397ddde10d108c44bfdecbe15d71aaf5257a4a20] =  31245085984790300;
        CHARGEDBalances[0x39f6c2f214ce8ff97224ec96c79ce1f96986dc70] =  1007000000000000000;
        CHARGEDBalances[0x3b857c73b63b290f05b37bfb8f0ab0347d118834] =  404537027936200000;
        CHARGEDBalances[0x3ba247f11a6e47584500424fba49a1c079e995b4] =  28124698230148400;
        CHARGEDBalances[0x3c3f8ae7a00cabec565c8ff1045e5696cfee29cc] =  592600000000000000;
        CHARGEDBalances[0x3c728c550ead2dc6eb54378e863e6128483f7010] =  950000000000000000;
        CHARGEDBalances[0x3d5a0942b1c51407a514c853419de4163b2ee41f] =  4202272444993000000;
        CHARGEDBalances[0x3e61c2bb09954fb21b366dd25685f0a2dd8d322b] =  3477166089996070000;
        CHARGEDBalances[0x3edbb957bcc2d0200bfde061e232ba396331a05b] =  1169978747601230000;
        CHARGEDBalances[0x3f1175c5b5c0507f7569a35871192b6f63347523] =  230112209677155000;
        CHARGEDBalances[0x3f8dcc43a53b9eeb9996c0c5ec7791a0689f1bbe] =  681464252512806000;
        CHARGEDBalances[0x3fdd9392c1bbe0f877f2ee47c9049f8efa32a7e1] =  475000000000000000;
        CHARGEDBalances[0x4124196648682cd7039460a7c2847e2fa6df9ae2] =  74492723865857500;
        CHARGEDBalances[0x413daa2967b5ac63cc32acd979ec3d7254939b95] =  5395601489407160000;
        CHARGEDBalances[0x4158d5a7a69619db9b67a7021a6d876ceeaea271] =  118271710762031000;
        CHARGEDBalances[0x425d438497f744d39acec7e85a3ef1d0af799486] =  628751199821174000;
        CHARGEDBalances[0x426ef0dac23082cb7243ccf21e7193884e200a87] =  980798993473823000;
        CHARGEDBalances[0x43813b7667b9367a1742b535e2bead9517431252] =  397437775202181000;
        CHARGEDBalances[0x43d8a6fa74105ca0ce2c0890ea7b747bcb4198dd] =  714781229980496000;
        CHARGEDBalances[0x43de60ec5e9ac404c8b00da9dce5fc7f92a71e53] =  225990845353190000;
        CHARGEDBalances[0x43e1a62dfc020712b00e677c9ba0e54dc00f2d8a] =  224191670471377000;
        CHARGEDBalances[0x449d874e7c37011cdfc5f673418328a28d184389] =  531408130908017000;
        CHARGEDBalances[0x45521513bc20012b079b462df1ca2fdf1aa87f73] =  980000000000000000;
        CHARGEDBalances[0x45881dcfa7df0b129bb87b1b09033c6fe87e8056] =  20316156893211500;
        CHARGEDBalances[0x45ada4d4828d2e5a5b7bd846794decc5ade63164] =  470352927973168000;
        CHARGEDBalances[0x45fb861a63324880bf954817a70a9efadd8e4581] =  2349000514724850000;
        CHARGEDBalances[0x46486a4fdce2b42613852297c8a1d9d69af23b35] =  36577143389638200;
        CHARGEDBalances[0x464c821167faa55178cfa09dbb7ce84ba59991bb] =  587662130492150000;
        CHARGEDBalances[0x465eb36bbc37147967d0562ef1e481e2c8c6efa4] =  53986886626;
        CHARGEDBalances[0x46778beb44a7bb3fc0bc232e785cd11604f8d9d9] =  1033549407793860000;
        CHARGEDBalances[0x46b47c6aa864bcea9516614d09b60e9ead3bca0d] =  100000000000000000;
        CHARGEDBalances[0x476f0cff76d6ce4ce423263716f621c76713ee61] =  9819748330058860;
        CHARGEDBalances[0x4937080e1a0f96e1f1e1264dd91dfdf04c09e8e7] =  1000000000000000000;
        CHARGEDBalances[0x49373c9b31644bae4bb62c13e5fb8ba237b4256b] =  36000000000000000;
        CHARGEDBalances[0x49a375bc938e3cc2184e1b1b3a5f2c4b386da2da] =  252915723291730000;
        CHARGEDBalances[0x49ecb7085bcf00ee561402eeef2e92ea428d3360] =  3200620000000000000;
        CHARGEDBalances[0x4a3bc613af649bd9ea770640df823850de6a062a] =  147375416985736000;
        CHARGEDBalances[0x4b9f6f28002182491a2796937f21b476140f84c7] =  8787369839379;
        CHARGEDBalances[0x4ba42b8811d5d50930a8be400dcbf6db3264799b] =  10773982337227500000;
        CHARGEDBalances[0x4c1caa47d4c7a6971d19ffab7e82c206d9dd55af] =  1470000000000000000;
        CHARGEDBalances[0x4e4da5abb3c4e27db723db8f543c2f6794c6a212] =  96338651085332800;
        CHARGEDBalances[0x4f3378c79930367d663142030b02ede7d2f98921] =  2221804986478160000;
        CHARGEDBalances[0x4faf51e00082c41b08e87bb89d11e9c71fb888b5] =  146525030778955000000;
        CHARGEDBalances[0x509217593100cb61ee1078af760e8aa00cbda7c4] =  200158132736809000;
        CHARGEDBalances[0x50f03cb97ec47e1284918f003e75fe2e1686e2bf] =  116350477710333000;
        CHARGEDBalances[0x519bc13d6e365406b09ae4602515e0fc7bdf7ec2] =  266284263044693000;
        CHARGEDBalances[0x51ad1db815ccc9de24e7c861c7f6f815db2b8acc] =  9500000000000000000;
        CHARGEDBalances[0x51f6552878110fa129c462a6780b3904b7e9792b] =  1000000000000000000;
        CHARGEDBalances[0x51fdb1b29a104a57cde9c83c21b73f5831b4be13] =  180350726390678000;
        CHARGEDBalances[0x5272468bfafa288c4479e315c37edf9f9ee35c4d] =  4159600000000000000;
        CHARGEDBalances[0x52f875860f398aa84435f21b214f518164a56e3a] =  920704560702447000;
        CHARGEDBalances[0x53f1535888a268fc1dabac7248dd401183918189] =  5038912259356570000;
        CHARGEDBalances[0x5567d26e8c2ec9d2c6c6bba6034d4f01a3dab384] =  208180372184102000;
        CHARGEDBalances[0x55acb87be31c9997473f7e0e17ec621d473852db] =  241423349777647000;
        CHARGEDBalances[0x55b038b3f2e4b5e5c2aa47923da9f58cc5b449b8] =  2880000000000000000;
        CHARGEDBalances[0x56ae0d4ee42ead80a7986f148d6d73ac88ab1dec] =  785600000000000000;
        CHARGEDBalances[0x57013830fe1d1e6a960692c5841ae2b6aec11ded] =  243040000000000000;
        CHARGEDBalances[0x573d5f45d5d3e92eb27d3529271a08fcfa9b9087] =  916344059696;
        CHARGEDBalances[0x5860e70ebfd0c275aabe4bf18b0f0c344d040b0a] =  1189640750000000000;
        CHARGEDBalances[0x58e1fa26fcc0b6bb1cadc8bebf804fdbc1c09505] =  245000000000000000;
        CHARGEDBalances[0x5b39829b09a1b81e920a0c514a46a390cb0aa4cb] =  329755162765437000;
        CHARGEDBalances[0x5bed699eacb5f208b1df7c0615f54efce5999cc2] =  81390888982151200;
        CHARGEDBalances[0x5cbcd91b76194512a638e96ade8253d7455c5b4b] =  27920947166696200;
        CHARGEDBalances[0x5d18d0c0b4c5d496fa6320b0cf45806782ad2aaf] =  97504833932789500;
        CHARGEDBalances[0x5db0a9d38250930600a04c63cbaeded7856a14d3] =  515915748726834000;
        CHARGEDBalances[0x5dcb37e8bd0552f6ec2612a1d69ccb80ebe1f222] =  2832318425574620000;
        CHARGEDBalances[0x600e0fbeae0df0cd378b4c65d1c96ad354e13ea7] =  143120860696101000;
        CHARGEDBalances[0x60aa466be00acc37dc5e3b89ff299331907df045] =  604567187019335000;
        CHARGEDBalances[0x61c9b0c054aa37f5b51429a5a18dc03181c7ab0f] =  98000000000000000;
        CHARGEDBalances[0x62ec8aa138d8de8f30fceb4ba9c7b04d8131f2c4] =  617017464811603000;
        CHARGEDBalances[0x66d8368be63f4c4b4a0d5169e03bddd7de5f5596] =  567138283;
        CHARGEDBalances[0x683b2388d719e98874d1f9c16b42a7bb498efbeb] =  51092478867753400;
        CHARGEDBalances[0x6aca675cfa67a49a708376a722953a14a0cbcfb3] =  1820320002240;
        CHARGEDBalances[0x6b4736e50ef0f3dc471ab062e7abb2051592b32a] =  23687618393630400;
        CHARGEDBalances[0x6b52b84648581040fa932693091da02d45244ffe] =  885144819623483000;
        CHARGEDBalances[0x6bc587e9fe4fe89cfa7aa097992b709610750e3f] =  131812505661933000;
        CHARGEDBalances[0x6bfab9b77b1288569deca8d74c904ca7f5d8d954] =  1583860737069640000;
        CHARGEDBalances[0x6c92a763d1ad5fb1cb509e014217816dc5ade475] =  11899324942476200000;
        CHARGEDBalances[0x6e2cca86d27714ca6d9b272c7ff08e307574001d] =  30059346621351400;
        CHARGEDBalances[0x6ef2f8d260ee634e1176782006127230e841ea64] =  324967896472502000;
        CHARGEDBalances[0x6f0f1b1e8f86f0a47b727e53a46b5c5fada5b885] =  724359616652509000;
        CHARGEDBalances[0x7067bce753801201b94fae26a344b7d16f6ae039] =  1671953079082660000;
        CHARGEDBalances[0x711c86e95590daa071995612fb9bcb91e62a18c7] =  950000000000000000;
        CHARGEDBalances[0x72cad03410d16be62535281a0ebcd9eac7d90959] =  3490532878109950000;
        CHARGEDBalances[0x748fcaa9b58b373af5ec85e59b51c1717016841e] =  134073278752812000;
        CHARGEDBalances[0x74986e123b6b49719348d101f11b95ebeccb0946] =  200261495446412000;
        CHARGEDBalances[0x778e6362b2edcefc06a768ca0a438cae0cb568b1] =  1857951183241070000;
        CHARGEDBalances[0x78d18416d976ed23ec3dcb9b2251d39bdfddffb5] =  310960628830974000;
        CHARGEDBalances[0x793b43537859de732a301caee79e18e7ca85fe69] =  1584243965221190;
        CHARGEDBalances[0x79459cd84b2ae87b39301b0424e54182dc82836b] =  580167934300097000;
        CHARGEDBalances[0x7ab2cbc5816a950bb4f5c5261645f16b7d457f85] =  950000000000000000;
        CHARGEDBalances[0x7b63f11c829a0d72b5a0ee83b1925d5e3bdd6559] =  2611739264510370000;
        CHARGEDBalances[0x7bb54099c371b7d6db78af6ce9aeec5094233579] =  58642009691952600;
        CHARGEDBalances[0x7c01e3e60682bb65adc0424f70205d66450fd763] =  2748639560578580000;
        CHARGEDBalances[0x7c4eccc19f2c90bd2bf36cd581bd38f6f01800f8] =  1012739527778720000;
        CHARGEDBalances[0x7d6db0c8b1c5c01e288725d1c1cfe0b2ab2d30f0] =  1900000000000000000;
        CHARGEDBalances[0x7d9b3a68639cd6133ee69936f564f9f542d21f2c] =  454551536209051000;
        CHARGEDBalances[0x7e1ac74b09210f535f5b04b29df0e640ed12e9e6] =  4837449638101270000;
        CHARGEDBalances[0x7e786ac64a0480c3a003b852f8d9b5b91332bcfc] =  3065000000000000000;
        CHARGEDBalances[0x812f3f26b40e15920782a9eac26edc3d3cef212c] =  545346137419724000;
        CHARGEDBalances[0x81fcc672139b7993786b29c067ed6b08e197c028] =  226319057816432000;
        CHARGEDBalances[0x8298c75155c9ff043a63b52cf703e4c8b1bf7446] =  475059986927004000;
        CHARGEDBalances[0x82da7a2ee725185539cbd0a72c428b9b98bd350b] =  2248414556604780000;
        CHARGEDBalances[0x82ec6851f3776650e401dc8cb94cedb7b1b43d1c] =  5652035819226480;
        CHARGEDBalances[0x8301e03c9fb69ff87f63dddb7670335dd18ee4fc] =  176582932924950000;
        CHARGEDBalances[0x833538ce2cb1f13280d3f7813d467baef7ad0c10] =  3800000000000000000;
        CHARGEDBalances[0x833cbc7785ae1c6bf4496c8f77b77a2cf9ab8175] =  123103427395122000;
        CHARGEDBalances[0x8380d1c04705af662ece8a3ee5255e83bb2e35ca] =  714699798048838;
        CHARGEDBalances[0x83b278a3fc234618bffd238e9df7964a2c9c6177] =  940159196536475000;
        CHARGEDBalances[0x83d371d26fe57a17849f87b14717fbad7c6b82a5] =  125589184667927000;
        CHARGEDBalances[0x83d3a545bd2a091bf1c67be7b5a3bf83a04a83d3] =  6348962932926830000;
        CHARGEDBalances[0x840a785172946c172d21ab9f92746f85d05b5de2] =  395531216533657000;
        CHARGEDBalances[0x855a5b16782304d3382dd764ef69a10efbeb9a77] =  1;
        CHARGEDBalances[0x87d46314487c0c09264310c683a4940f0818a144] =  619272066668967000;
        CHARGEDBalances[0x882db27cf3359b863b94c19108cfeeeb58cc544c] =  2850000000000000000;
        CHARGEDBalances[0x88d2f1c24dc59481ab77690cec4ba670dc7cb539] =  2301156359778120000;
        CHARGEDBalances[0x893a9988d27a9e6e30645b70af23d5d0b2b16115] =  196944573941099000;
        CHARGEDBalances[0x89a7407abe1e72b5983421dd38421d577995ffcd] =  801566166707175000;
        CHARGEDBalances[0x89b9edde3b1658091e85fd380299a15598c1e103] =  2330831880587590;
        CHARGEDBalances[0x8ab338cf555eac7304e14b5d612deeb224fb9b0a] =  1503859697426910000;
        CHARGEDBalances[0x8ae682dd3f7598faf229348ccf3d7bdb35e617f3] =  1003957203629930000;
        CHARGEDBalances[0x8bcf86e6822ad0af1896bc57e4afd83321f579ba] =  192540569663332000;
        CHARGEDBalances[0x8c0adfc5b30a7f8ebf45fbe1923d544a03df95e6] =  10000000000000000;
        CHARGEDBalances[0x8cc140e41f064079f921f53a1c36e765db4b7e59] =  4237271037448840000;
        CHARGEDBalances[0x8ce0ffa9a232ebb8f1ece9ae44662d75cc25b84d] =  8042595842045700000;
        CHARGEDBalances[0x8d1655258c6523261eab93aaf29e18f17dee1152] =  475000000000000000;
        CHARGEDBalances[0x8d415f8e29b6cac93e3dc7dadd9c8daecf4f736e] =  2032026225567200000;
        CHARGEDBalances[0x8da40e48770760e36c83f1d2fb2f42d529c36f5b] =  342111677761072000;
        CHARGEDBalances[0x8f352fb591a250f407a27509fdd510079e7ef381] =  95000000000000000;
        CHARGEDBalances[0x8f759d4e7c4ca8f9ee4c19644ac51cf63ca16bec] =  103336386510837000;
        CHARGEDBalances[0x8ffb65e51d3a9427a086a9e5c8a2e99e73ad6ce0] =  2999730048076430000;
        CHARGEDBalances[0x91182ff24a73e7ddbc251db6e020bebb43d76dd4] =  78106430114087;
        CHARGEDBalances[0x91ab1b211ce411a0597f7cc6a1ab860bc936cc06] =  216264817791641000;
        CHARGEDBalances[0x92353d9186a1d02be280f55c8a563762a9edc100] =  125114458825601000;
        CHARGEDBalances[0x93b05e0f3c705cb9efc21d0cc8ccc6f563455ef6] =  3023079717200730000;
        CHARGEDBalances[0x940f011848f2f3aa5fd47a641a643ea489090c0b] =  181482127200208000;
        CHARGEDBalances[0x94debc57081c4c58dd69f4dfce589b82fc3c2866] =  941873345115908000;
        CHARGEDBalances[0x95b02cfae2cb8cec514e507aaea8eb001ae67431] =  2850000000000000000;
        CHARGEDBalances[0x965cc23004afa37924323836d5cf90407b98f6a8] =  12846000000000000000;
        CHARGEDBalances[0x979c9c12531ed7b65b62ce4d6822af384764de79] =  438918203798381000;
        CHARGEDBalances[0x98a18a976eb8709be06e30472e237de6b6682e98] =  24500000000000000;
        CHARGEDBalances[0x99728c02f81cc6568c26f268a988d25d245675e1] =  650147909012563000;
        CHARGEDBalances[0x9a74986afef2416cee953673bfad1aa9d55af434] =  7807044180222160000;
        CHARGEDBalances[0x9ad03d07b4dcf04e2299b22f65c26ccf2b272c71] =  108013414678400000;
        CHARGEDBalances[0x9b6613e2b3128393e581a308628dd4b5d7cb517d] =  2239040365813310000;
        CHARGEDBalances[0x9c9403d08357704030f444ce4afeb2d93dfd62ef] =  142791123932767000;
        CHARGEDBalances[0x9daaf2a014898e7382300a9926e0b4bdd8027f32] =  55261313653248200;
        CHARGEDBalances[0x9dad3e8ab4d9673ed8d325549736dd69febfa879] =  4418099530012590000;
        CHARGEDBalances[0x9dfb6d99d56bfb75eb4708d469fe37581bfb9862] =  33945132626056500;
        CHARGEDBalances[0x9e12621b6148710d3698a5d84d7883d3bc6a0094] =  586243826883189000;
        CHARGEDBalances[0xa028c17fe4c392e1f7f84144af11239dd8989d60] =  4162683607157350000;
        CHARGEDBalances[0xa0efd27acc781549d5b78e89e561aa0903932d56] =  98000000000000000;
        CHARGEDBalances[0xa12b26e34177623bdee2c2c610ad0ea567636459] =  880959433787537000;
        CHARGEDBalances[0xa50520514e7fd93592795da06e5101545e4673ce] =  24673477105672100;
        CHARGEDBalances[0xa5195263f09d74294ab9407f15347c39c31681b3] =  1239343171677260000;
        CHARGEDBalances[0xa576b26b182199bcd13c9827f4f9304e0575ff26] =  4708492922341410000;
        CHARGEDBalances[0xa708985dd9065bfb64c7dd3e941509ffdc10c0bc] =  4000000000000000000;
        CHARGEDBalances[0xa92ab8e34ce23bd1f51fe371bb054150122e52e5] =  64138360238434800;
        CHARGEDBalances[0xa9a06117297587397619fc0cbcdbdbf7de7dd643] =  5084802918231180000;
        CHARGEDBalances[0xaa4b64b7b6ef6a87207c3a5f97b0a271a111c593] =  707788202707715000;
        CHARGEDBalances[0xaace326772fc4b0a2766128da5009374f76d232c] =  41169487378906100000;
        CHARGEDBalances[0xab2ccddfcc8c18aa2c25106ba4f9929682042266] =  588000000000000000;
        CHARGEDBalances[0xaba2b9af06548efd0f0745bc8a7460f481516e82] =  653788598835853000;
        CHARGEDBalances[0xabd7c46ac4a575751e7481cc1ae97ff580dfef81] =  1000009264026580000;
        CHARGEDBalances[0xac680c7de98caf116dbe9cc167e39b8ba5b6d4e9] =  190000000000000000;
        CHARGEDBalances[0xacb2b1ebbed6702b2d25d8541a13539d485f483c] =  1328575087244540000;
        CHARGEDBalances[0xacbc078c0e2b319d4af4c09090eca5bbcbdab227] =  3183694162299;
        CHARGEDBalances[0xad015228da4b3e54791e786f6678a51a413e2afa] =  1331577057959510000;
        CHARGEDBalances[0xae57ecfce453d5162b41fbe70978c4541203d078] =  3383042337912250000;
        CHARGEDBalances[0xae6686600f0019b56b4c890225ce7526690b83c1] =  8370065973080640000;
        CHARGEDBalances[0xaef4d520430c4b8c343408f0dff4801915b8f8a4] =  2943691470205010000;
        CHARGEDBalances[0xb08dfcf4aad1ab6e65148689d79bb68833077f40] =  6563491847264420000;
        CHARGEDBalances[0xb12aa8282b00de547fda518cff984a375a61a29d] =  6826810530532230000;
        CHARGEDBalances[0xb199ea67d5352674bb3a432b5e669b8cae21ffc8] =  3152146796197820000;
        CHARGEDBalances[0xb1a16cbf43b80d808e2ade1b3e3e39402217b60f] =  1040948043606790000;
        CHARGEDBalances[0xb1bbc29997826dfc94b144126135c0aabc8175a9] =  5889445992721540;
        CHARGEDBalances[0xb2280d004e801e37c8239d72ca550ec8972ddf40] =  786333959106298000;
        CHARGEDBalances[0xb3404dc3f5cf6ddbe991c2bb47c5930a7f230312] =  57817122662417000;
        CHARGEDBalances[0xb3ea5a55797527889de125956d5e2d827d379145] =  834219852531783000;
        CHARGEDBalances[0xb40c6930db87a4f234e826d5f035029d28d36340] =  8550000000000000000;
        CHARGEDBalances[0xb549d7f751699a4d4413275955babccb539e5079] =  97925922247124500;
        CHARGEDBalances[0xb564bd0d53c4cf792631ae3f9b8393d6df9f9731] =  24135932806018;
        CHARGEDBalances[0xb59e46785d53a2029f985277041cecc3c4b905bf] =  10604991279320900;
        CHARGEDBalances[0xb5a82e0c8ac865b26bafdd4cd6a4bcafdd419c9c] =  440965230374556000;
        CHARGEDBalances[0xb7916ff3509da347b6c605346d0785d057605ca5] =  145632642974585000;
        CHARGEDBalances[0xb7ab128fffc72500df3f5891f378029802e8f1d5] =  10140112568320200000;
        CHARGEDBalances[0xb80d426a0b81d26203ccc96924086df60932d8e0] =  19000000000000000000;
        CHARGEDBalances[0xb959ae372cad79b73d76fa27fd9a8dd1567519c3] =  135763770978858;
        CHARGEDBalances[0xba325dfb78eac31097be8fb20690d695024706df] =  547486253489201000;
        CHARGEDBalances[0xbb63203fa253b667f1d8d591954f5a14ba5613e2] =  1354026083546340000;
        CHARGEDBalances[0xbbd2b501bb68035a257a34ffee50e4826be6b13c] =  100448554722835000;
        CHARGEDBalances[0xbcf3acfd422ff2b5b43c11dba41c290a2679ed85] =  98000000000000000;
        CHARGEDBalances[0xbd1971923e00d508fdc76460a8550e08dc4dadd8] =  307682290470442000;
        CHARGEDBalances[0xbd2822cc13d4c95516970d5f116902f4444bf0ce] =  256122494271;
        CHARGEDBalances[0xbe8f724b5e113f2ec8d424046540b1129c294bcb] =  616118457598804000;
        CHARGEDBalances[0xbfccf34757498e09807aa25bedd4ea8e03ae9e05] =  911927260524307000;
        CHARGEDBalances[0xc04cd534739dfc54cb3e7cf3a3da699bd195e355] =  1039843313432210000;
        CHARGEDBalances[0xc1314d34c78a643cc41f8a9b3939a31d0db1b293] =  84772615153084900;
        CHARGEDBalances[0xc16f21ed39af5b91d8d7ac8eed57d12ac1831169] =  999664668578827000;
        CHARGEDBalances[0xc19d0c4c7ef8825d3d2a1610b93f33cba0dca959] =  581431197553171000;
        CHARGEDBalances[0xc1cafd6000688c4b1e2d27d1dcc3acffb51728aa] =  294000000000000000;
        CHARGEDBalances[0xc3607fe5cc9e4ec34ea19bc2410676ef0411c209] =  4197343441539230000;
        CHARGEDBalances[0xc53fc02d1412bda659647dd0f8807404e3eeb850] =  872643288114682000;
        CHARGEDBalances[0xc6b2d10ac21184dfc2228eecb669e7f68ac65f99] =  140198541347748000;
        CHARGEDBalances[0xc72ae0cfd493af261556cb3aee68110b5cb2ae63] =  66642314828121600;
        CHARGEDBalances[0xc82896bc2d6315386b6e9cf5a82b606bcdaa7e5b] =  59099258882077000;
        CHARGEDBalances[0xc899564941f5e4c68310669d3f4f26450cbe40f0] =  4594505692338480000;
        CHARGEDBalances[0xca2fa0ee180e93ac29532b60af9b3bfad71c4a9f] =  329693393412801000;
        CHARGEDBalances[0xca85d4afe866498da5da2860fee68c3c1dac205a] =  1776648759348330000;
        CHARGEDBalances[0xcb016db66774bd5dd798fc3ac9c3bfcc06d68c84] =  3217762461374530000;
        CHARGEDBalances[0xcc5fb0b484e4ed1f3e67db5a8532fa178c2328b0] =  293690903175646000;
        CHARGEDBalances[0xcdafe450ce9bafced67a9e1d2d036daa5dd1ac37] =  16245273344522900000;
        CHARGEDBalances[0xce48bb7958253a5e8efa14b6775315adae09376b] =  40000000000000000;
        CHARGEDBalances[0xcebd7dc2cf2ba67b057b7b4ac51538e3169ff157] =  147000000000000000;
        CHARGEDBalances[0xcec096ab604d823c3fdb7136d1c8f50501591a36] =  361305521053363000;
        CHARGEDBalances[0xcf0de3dea22ff2b1ec918c13fdc31f3874fc72e9] =  200771273278116000;
        CHARGEDBalances[0xcf97b2e2eac29e7dd54acb24fd02bdcc0689425c] =  1357925933752450000;
        CHARGEDBalances[0xd05433ec8910ee00b4fd5222499ee70a5763798c] =  256207188237238000;
        CHARGEDBalances[0xd321aeef7131d986c500f3dfc220c3a67acf7bc2] =  1628176031798750000;
        CHARGEDBalances[0xd4864432e23755727b6c480d2f62bb6f5900457c] =  741920028219532000;
        CHARGEDBalances[0xd57181dc0fbfa302166f36bdcb76dc90e339157d] =  196737748061846000;
        CHARGEDBalances[0xd65bf2af940035e571285504386514d4dd88353b] =  512504272827179;
        CHARGEDBalances[0xd742478bae6783ae5d3900304d453869ed1cfcbb] =  4854853683751910000;
        CHARGEDBalances[0xd7d03fc3c1015d60ba2e85293cf4255d0ff4f5ed] =  392000000000000000;
        CHARGEDBalances[0xd93a37be59cc69098d48405eb40c978d82860704] =  126236811487763000;
        CHARGEDBalances[0xdb7c606c347195690381504f18609ac1e01c0f88] =  2098676692206450000;
        CHARGEDBalances[0xdb8235f6663689236e0407473df469608a84c65a] =  475950000000000000;
        CHARGEDBalances[0xdc79fa176038d0a400059228320f3c0a80506cbb] =  1489156872703830000;
        CHARGEDBalances[0xdc8b2b718b6f9f053d116237a0f2a611c7ee0d83] =  2158978530011610000;
        CHARGEDBalances[0xdd15c20786006de6b2f74cec62f98b51ef3a5f8f] =  328821617729926000;
        CHARGEDBalances[0xdd76e2f20d9d8ff7dea04b884933b1f23bea9f45] =  510397621691861000;
        CHARGEDBalances[0xdd84e09fee6ee82bcf2ece6e006abb1ec7c0167e] =  545694343676721000;
        CHARGEDBalances[0xde8ca49ec64ab5b9c67c7a321a7423ef2bf5b35b] =  261622243598344000;
        CHARGEDBalances[0xdf7495fc2eaf599a8105044d480ad5c97488a5f1] =  678125596378606000;
        CHARGEDBalances[0xdfbc3eef9e663ed1e809ce3aa5bdf172d5f68bda] =  1755718576374570000;
        CHARGEDBalances[0xdfc6835bd62a0004a9aeb7b03ca9c4d3c9f3c518] =  12622164186724300000;
        CHARGEDBalances[0xdff0a16fb1c7286a72f234894b9ae4d72e3f2385] =  194040000000000000;
        CHARGEDBalances[0xe0b5293626c7b73b84c4b1c0d8550d3023e53b4f] =  1592877271196030000;
        CHARGEDBalances[0xe293390d7651234c6dfb1f41a47358b9377c004f] =  67390078280301900;
        CHARGEDBalances[0xe2e457eada710ecdf9a01080f7a010d31e338553] =  2077014922253220000;
        CHARGEDBalances[0xe5e22918ce360c4e1f670c5babfc0251c074e072] =  949578007934037000;
        CHARGEDBalances[0xe6386827c99639ccbc253f70609fbb2b999b5895] =  527628777358988000;
        CHARGEDBalances[0xe6ade88281cd978600d3b244f4b4c64a91abd198] =  16;
        CHARGEDBalances[0xe6e27f75a13307c3fe4a8d45c09de9c311eea4a4] =  1;
        CHARGEDBalances[0xe707b57fc50b6c87a1fd938b22ddd31225329d67] =  22307514332770900;
        CHARGEDBalances[0xe7d272bb27cf524b5222be9e8d9eecdd7c24b50f] =  67712403260786;
        CHARGEDBalances[0xe895b86a7cbdd4e612f8bb7d393ce7b0de303f2b] =  251077625694857000;
        CHARGEDBalances[0xe8a7576601102296a1cfece08519ea8a6823d333] =  25479958623365300000;
        CHARGEDBalances[0xe8dbba8ac8411ee9f51fb4a2feba1a10243dba84] =  338661049118310000;
        CHARGEDBalances[0xeae589b28fc842b45e8f4cc0e36956b8e6383ac8] =  3490427298577;
        CHARGEDBalances[0xeb3494c3cdd86b9ce6f8b0cb92bf5bd010a8a3dc] =  1411593801410090000;
        CHARGEDBalances[0xed4855e0636265487d32257a790dc68378add575] =  108027620159372;
        CHARGEDBalances[0xee3a863e94490709848540a4b85d42ccc3ad4e82] =  284630533783937000;
        CHARGEDBalances[0xee959d060e295e0b0cd1983ff9b1c7b1cfa59272] =  793177701080679000;
        CHARGEDBalances[0xef1547c8733ee9b563f9522f77df47c271f28e07] =  2041433593471600000;
        CHARGEDBalances[0xef592f0cc7f8ba76f181ccff0c1b5754ec3b0657] =  1381284108763370000;
        CHARGEDBalances[0xf025e8c1446663bc1d91b1bd3a713eac642f86a4] =  7840000000000000;
        CHARGEDBalances[0xf0a213de38d47d2c0001a26f69b1ccdb4db15010] =  1256705318340540000;
        CHARGEDBalances[0xf0b36a8dc2e4549084f92f4f651121e0b1b15b48] =  70601772430905300;
        CHARGEDBalances[0xf0efaa3b407c18b7e251d999463fef05c8d10c5d] =  133801345083173000;
        CHARGEDBalances[0xf18c402fcd1b3706951bb4e15058101c01355acb] =  93809169413496800;
        CHARGEDBalances[0xf256bb63d41a2c1fca4250d6c9a6fb7ff69df7a7] =  543804589313965000;
        CHARGEDBalances[0xf37b4e985cd88c9e1f397e8c18a8615837a110dc] =  52711426535698200000;
        CHARGEDBalances[0xf500ca9799f962f70648079dd8d411ac985e9dc9] =  229401799342064000;
        CHARGEDBalances[0xf51450755b79bd82ed15d646ed8431fd47a54b90] =  188679249165885000;
        CHARGEDBalances[0xf5acd8b729f6fc631095534cb2ea04b17aad7c38] =  79799879336917100;
        CHARGEDBalances[0xf7365c995e0a326a70dcc3c18bdb3b407cb10b15] =  80431508084525600;
        CHARGEDBalances[0xf882e56af1c7013dc2369376efc58dc67009fd8d] =  353412131305781000;
        CHARGEDBalances[0xf8f2f851392029cc7413a1dbb425bbf086121307] =  678563721881423000;
        CHARGEDBalances[0xfa48cd469d985dcc1f1000d5ff62e633eb93e32f] =  160220442395147000;
        CHARGEDBalances[0xfb041fde8bb100121c239921524b77dd53597208] =  272447381416184000;
        CHARGEDBalances[0xfb40737791a414bdeba673c394a8980829c58d74] =  2895000000000000000;
        CHARGEDBalances[0xfb9e6480869e469e34234e2984109aee76512412] =  173273521938016000;
        CHARGEDBalances[0xfc69ab64a4af39cfac708742893eea63976f7caf] =  998454810692271000;
        CHARGEDBalances[0xfd3dc8e1bab0c665c9a03c320f0148f046885081] =  18280352770504300000;
        CHARGEDBalances[0xfe5b9092975cc34db72bc1b1ee350160dc5c292d] =  35281869632405300;
        CHARGEDBalances[0xfed6b9243748e5a5bb5c1f373fd7da9fca235334] =  2007653725174780000;


    }


}