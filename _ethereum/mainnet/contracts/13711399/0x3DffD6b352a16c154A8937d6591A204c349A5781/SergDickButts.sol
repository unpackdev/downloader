pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract SergDickButts is ERC721, Ownable {
		
     
    using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY = 555;

    uint256 public price = 0.03 ether;

    uint256 public MAX_PURCHASE = 5;

    bool public saleIsActive = false;

    string private baseURI;

    uint256 private _currentTokenId = 0;
    
    address[] private whitelistArrSergs = [
        0xa8c534413F2C4663c166B435dA1BdFfb7680d29A, //1
        0x7dD65658F6480A2911F4A7f6c7C193B66E318EC7, //2
        0xC956B82CFbc9C85f33aE1755E948AfEc47451f9A, //3
        0x41441cF87Cba68A1b92C7a8f31D9Aa161fC513ea, //4
        0x68b5c96c27071A079aeF666ebf55023C9DbB7f60, //5
        0xd60bEbf712e72c500C45DC7e479261F7d258B5a7, //6
        0xDFaE6c45233c9DA3F8Ae1309925Fe93bCAbC0a77, //7
        0x417bc68aC3d65FE9f0DBb76f20aD765f42e0717f, //8
        0xE6Bcc30C79e7D53FDe06B2a195B960f60ca4DC3d, //9
        0xA65a39e1aA15390ab2ad4D3E75a184401DaCDcc6, //10
        0x85BaEC1be8C448E7c7B2ffd0C97e883781C6A702, //11
        0xA749B058ee2a54e98342f4865Cd3062eaC14B451, //12
        0x208BA77C17d62A418B0A34A54143E9375FfEa633, //13
        0x81c1aA4bF93ECA02292cB0dfa8d6d86d2FB3bA35, //14
        0xe8c57B1260501d2cB59dB51AA069679D5a6e3720, //15
        0xCb9BbC9Da5e28D3939c1045962f48883C573a913, //16
        0xfAf3106bCbC512cE0f4026Ce1CcfcfF833b77cb3, //17
        0x9fCaA7bCa3B8C8dd0e1Baa8014870fF6c08b3b84, //18
        0x2D26b69ab582765752b1591958394aCA21A9949B, //19
        0xAe0C3d6aA3636A77372da7772f6469f47b6893F4, //20
        0x7DC3D31bDE30C104D8A3Eb61B62D6260e2BD7155, //21
        0x9d80eDefb33F7Fa40DcFF768E15A173F0498d183, //22
        0x061D529363a13bBfeDA3de3fED4b213F38D0b48e, //23
        0x9B4B7282e4838273C79CcA63c6c03a2dF5ee4286, //24
        0xF5Eb2293bB18199fdf58f4F85Fc9D4FbFea0638b, //25
        0xbDA4377A9455d877e4347545b4454F1fE59f5c10, //26
        0x43c7C3943A181774FD1791742EF6b42d671E30c3, //27
        0x000f85721CbAC4f00694eaC29c3F6586e0Cc7Ce6, //28
        0x34b5f399cc5A1dD491666c9866941FB8E8D09746, //29
        0x8d7c9AE01050a31972ADAaFaE1A4D682F0f5a5Ca, //30
        0x44aD7128ff5bEe58eC58A386Cad2e3405252645b, //31
        0xA3C277b8f35881CBdb017E52bcC376B3ce8F21dA, //32
        0xb7b78C45036D5a089Ff85d39a0e0836037D1Dc52, //33
        0xE464d012805F23705091eeE10CA3856d6E4bff3b, //34
        0xbd16b6cf36301Bb279798aA39Bd0E19C5faa7BB6, //35
        0x17357B1002AB1804657885a60a3d9B114C79019e, //36
        0x16Aeb36CeEBA2BEAfAC0D74e87FD31d36182a2BA, //37
        0x40deB7ab338083c92A83F02f45dA928Ae09101E8, //38
        0xA7BD745215fA1cee3E93Ef2De195C5A53B6C75bB, //39
        0x8346d0DbDBfa393fDe4652194B3f8715Cc51F665, //40
        0x6244Ed50fDCbA955274cF6af9741FB8584843A15, //41
        0x538D4D20450aA13212f73Cf320f4707841961feB, //42
        0x66B333423409d3Ae4008d6fCC84aAdAA8d31A0C1, //43
        0xeaC7aD031e005B5FeA4e3045c7Faa3Cc733bDa27, //44
        0xA02d693Ac305FeB183a8af283f8382fE95d37408, //45
        0x25E4b241D4ca338b49D429178d55E6118090aFcc, //46
        0x31E04750dd87396eCf4AE8F976CBe4cc69224Eda, //47
        0xaFF0A88bB6D6Fbe6619c2592d56515c06E78D061, //48
        0x14c9ec0e3022871cb56bA0fFAE119Fd6419d4e0E, //49
        0xB88f65Bd2493BA8e4fc15d9D0C3905d16874e9Bc, //50
        0xAF912a4aaFEbA1F1E459A3F827E0d3b52ce034C5, //51
        0xaB14023979A34b4Abb17ABD099A1De1dc452011a, //52
        0xA54A24f7aA6538EC46c8Cc5EE9AED158C0624eC1, //53
        0x3461DE456478f03986bd6518AD332f5b6CF4dFf7, //54
        0x06B8461b79955e8291c48d7De6d12718373ef1B0, //55
        0xD8f35EF085D202FA7CAd0E0C61da737b60E1F855, //56
        0x3AbB7fa06b64Ee2059fD53244242F0baA90FD0a6, //57
        0x31D24CF68031336517526dfe4a662f9c04A65296, //58
        0x947Caf5AdA865ACE0c8de0ffD55de0C02E5F6B54, //59
        0x18e6C263eCD40aD31D9079b20730f04a59Dd73B0, //60
        0x112762e444d00DB72b851E711783B392df6A1F60, //61
        0x445BA5093698E59D81dC4137C85779a99ec13177, //62
        0x881a960440153CFF2e60aFEddFa05296239240a3, //63
        0x7b533aaeEE588F839E3B63D8aD8Be467e872EDdB, //64
        0x1E4aB43d5D283cb3bf809a46C4eed47C7283e6EC, //65
        0xA88e16DDA11147fE07a97c630cf64e94d42434Ca, //66
        0xAC28a07CbE596e66B67004dd6f87e858410B09EA, //67
        0x6546D667d9de6A5085b2727c7Dd46335F16aA198, //68
        0x0eeFa9732dc7d2eB781DD7dD58041A24DFbF4019, //69
        0x050e8c6e7D2566348bf2a2eE9ea1440889743E30, //70
        0xb6164AF04291D3AA4051Ee78943618318E3F5cef, //71
        0xC8b1F17000C85B56ea663A92cc17049D5419C5C4, //72
        0x46F67bA8629F70A9c6099F9f0cA1Fe98e5047397, //73
        0x9F9D26Ee6084Efa855436E4A25E3aAd48D32cA25, //74
        0x46E8518eb63AC88AC61F9b00A234f2d31eEabe93, //75
        0x05C985db49d9E29aa66b465F18c7c6dD244E9774, //76
        0xD342f616a504Cbd471B0405b70bF991c1D6fE72B, //77
        0xA487b579Cf197AB4f7D3a1b2b59195862Da15A7B, //78
        0x7768FBc67afecF2b4Caee9D1841ad14637D13652, //79
        0xc8fDBBA9dB5868e2d5Fb854B8cF473Ca69D8498F, //80
        0xd0Db424747326FA0d336C6C7389BD1BB919c7c0D, //81
        0xdC133816529CB58177d9bc8b55E4b523673b84FB, //82
        0x29f4B3DF64F412239a21696D589115BE212Bc640, //83
        0x994Cf01f34c51426bCB12bD30Ff7079E280E1140, //84
        0x38A4D889a1979133FbC1D58F970f0953E3715c26, //85
        0x80078C884C69a081E3CFB62BFb828155DaefeEcb, //86
        0xD41a5311C20cCEcECd6198640997714421349d6B, //87
        0x89e749662BB6EE7cC0a9dFDeC95119401d7264Bb, //88
        0x3A49309413793b32F6A308769220147feDbFfa5f, //89
        0x5eA12341d073Ec5a1226b85f0478413A19081535, //90
        0xF9dCeB45b278484AFE2544272DB78f560b910aCC, //91
        0xaa8Ce0c99C2c71D371C98a2a7a18D8B22775D2f4, //92
        0x1Cf8B7c59560C7142085a8Da527A79871872544A, //93
        0x4231b7DB2CC23EE7C466375a0A10c719Aab0Fe91, //94
        0x6D0998e0513A739d1Af438e35Fe33b4DAD258920, //95
        0x77B4b939866272E279F8D7DEDa9b91C48eacD257, //96
        0xB5b53dF4B8cfaDCCC80b24D5a554154FE86cdE18, //97
        0xD8B5Ec978d3009CF1dFE07f51d02001550dc7706, //98
        0x17FCceE77eA267079a3E3D83BF1AbCca104D4eDB, //99
        0x971c723D74723335742FEA1814F0da22e813C9F0, //100
        0x8b3347FD0B8C3a619d1f1FDc90CAF4F335c03742, //101
        0xbF38346e4AEbcC844c253Ce715263fB4a03552a8, //102
        0x8b69D13BB8A852c90486AC7b577f0069dA04Ae95, //103
        0x71E52196aD26f585EdFf14180C20d0ba92579559, //104
        0xC46Db2d89327D4C41Eb81c43ED5e3dfF111f9A8f //105
    ];

    address[] private whitelistArrCDB = [
        0x1e8E749b2B578E181Ca01962e9448006772b24a2,
        0x15756a5FBE237e5D8644aA862b86501C4C6F242b, 
        0x401CC1B6620e30ade449BB8f593a0d0799FbAC93,
        0xFeF1B2dc9F48dCc68bf69020a563118e1563Ab9a,
        0xe8c8dDa5BE69e623A45536081716De00de789034,
        0x1C2b721fbFA0CAf514C79f953bbcbaD3c464ecA7,
        0x3d97Ad12D40EA711D88B53680b3ae19Aa5eC870d,
        0xD651E2c626eE210Fc38676124D5007Ac822AD749,
        0xCfd648EB66b736351f48DBD5a1752708371c10F4,
        0x02C1ca960532947A45d40A752944cd9648cCF900,
        0x455d7Eb74860d0937423b9184f9e8461aa354Ebb,
        0x3d11c06d80d9b4C365Af5d699bCf721daA67E6D8,
        0xBf9277d14A0839527998f304E9480d53f9c17543,
        0x55Cf34223929A9D893C1EA402735a3a6FC6e5F74,
        0xb1E079854268985431935ce53AA54C8e1722fA0D,
        0x75B772F2Bb4F47FBb31B14d6e034B81CB0a03730,
        0x42E250824bDf98F3E450784b0C1CDC3ac2f157E2,
        0x4897D38b0974051D8Fa34364E37a5993f4A966a5,
        0x4baAD838e29aDde3076d64478b408B63d5a53FC1,
        0x5dc4561125fcaC2030d07301c50153cFe624391B,
        0x38A4D889a1979133FbC1D58F970f0953E3715c26,
        0x3B409b10e803C3f58B61B90b7f60Efb9D4a02A90,
        0x93D020b0C5158939274235EE9E670eDb9612726e,
        0xc6B89634f0afb34b59c05A0B7cD132141778aDDd,
        0x06cF49AfC70B8EF256dfb41F58d89c19FC6460F4,
        0x7b15428169f5C5579Ea2159c4079Ab189c16bCeF,
        0x0Fc030447c326df2F67F3A9d5F011E03313729A7,
        0x60c3b507482dD50d368995E6dC53B37e3c7ECE23,
        0x251216Dd3473EA5fCdBaFFd0dD0826017F8E1B24,
        0x7012757512bbc05ee7935c8424899336C8F0a590,
        0xDf39b59a52D78f69db4e28eB03F64bE98328ddB2,
        0x34dF5e2952DeD2C258B1E7861F972B4Ab4f9056E,
        0x414826bEb718F2b204Bca67b949604bdC739fCBA,
        0x4777531CBB610962570c507d642501A422aFDf5E,
        0xAD4D70479Cf926122Ee41Eca5DB4e2775554dEA0,
        0xe797a10beF5C6658F9a9Ef7Ac5c00eb4739e9077,
        0x3110cbaAd657Bab2F5c5a8Dc6c5e276e5a4C6e32,
        0x2fa510caf46f88Ae7Cab8DaEc696aBBc299f8D20,
        0xc4464Dc30eb53437a1e84f380f813F61ae7E174d,
        0xF533A9a5bDdF9D79801468d7078584d94eB316cd,
        0x210046F6FfcC515d14F5bE80FD5B11A086a12249,
        0x57F02141F2D91a024032536EC61c974bE76eB7c9,
        0x3a4E75EFd6866904D1101Ab378169aa445C736c4,
        0xE1fd4DB76bb22cc5ae03616b6b748313a92aA9B7,
        0xAaD424dCefC467ff77e2605C3a2ae0Eb8a11B01E,
        0xE7A3Faef2f56efFDeedbC26f95Dcb06E6E8b7859,
        0xb1b91C2163F8FE8593541d9DaF0B1B0c7c95bC15,
        0xd1a5B120724C3d52c49dCb4638BC57E1a69323A1,
        0x5c41720DB062301479e0483cB9b6721a931DC327,
        0x6278E4FE0e4670eac88014D6326f079B4D02d73c,
        0xA89d714e8b3f736C1ae8C8b142F6a7FB3f4d77F7,
        0x73E4a2B60Cf48E8BaF2B777E175a5B1E4D0C2d8f,
        0x1d801047B51B5e2f970F80897901de022EAFCCba,
        0x871d6d1267FF6cA915D8C91801194eAfb76d34B6,
        0x8BF2B644C73133899AcEb3039EA79107db52cB62,
        0xeFd743d7141d1751fa5E765C02447688C830d6c0,
        0xCF60948Da18AA27E727bDb2d18638b5DD6CA8239,
        0x7dC5bE46B79689D3ac1fdA8BcA197f2bE4e111f3,
        0x6D0998e0513A739d1Af438e35Fe33b4DAD258920,
        0x8756Da913378b865Cc6e5bbD8d403995A0b37567,
        0x9BD69d51526fC9dB09Bb831f5069A48cbE4D3421,
        0xb19810efBef1fAfDe517f0794246a973a5568166,
        0x0c2E9A64c9382BC2f99b092B3D0c3164375536D3,
        0xB2A2a6a69E7A0aD66943F4c2869d45A9919CF740,
        0x98D0AFD7505811a59042Ce445C41C85DD918B6be,
        0xC665A60F22dDa926B920DEB8FFAC0EF9D8a17460,
        0x34BE775b18201B6B836c3b8972062F74ecA84d2e,
        0x6278E4FE0e4670eac88014D6326f079B4D02d73c,
        0x36A82b407bDebdDaf673C08a5CF8F7B19E5cf2B5,
        0xa5a6e243201d6F7316E7a67Ec2fA584353F66101,
        0x892857D3A0E6ca504dA54470A0d71593525Ebc22,
        0x30B5a6e6f54507E0DEE280923234204B6A82664A,
        0x6b1c6E17A7C073253BDE2F3AAB0a767D4c9a2107,
        0x6396EF1C07949476Aabae95c926872Ba2dACDCaf,
        0x078ad2Aa3B4527e4996D087906B2a3DA51BbA122,
        0x3fd74Bf96450638C70041753d7933Aa4fBBb1ca7,
        0x7a24113eF17F916ec4A035980a1A9b0cA3E343B8,
        0xF7c454Feb83b0886f21C2A1FEd78ecD246529789,
        0x0B186C1D6dBc9e1b0bd3eb2D294c894e5aC61cb5,
        0xcadF27617c932594d840b220e39DB61b46bC4720,
        0xa2DF601D3CA31B8484d8B862Ae61eEfc91c3dd2F,
        0x7049871039097E61b1Ae827e77aBb1C9a0B14061,
        0x17CFBA9989489967663353C778bC266F482E291C,
        0x416C9f987be51072E2d5194d360BE544d402838b,
        0xb0866655ffBE8b55A3b1C8CAAAFf2143998FeDf7,
        0x869568D4fD6cEdeBd5478488900eedAeaD0586C7,
        0x3D9Fe7337F067dD52D1DC8cB45490b1ad6C2f65b,
        0x12d964f702DB7b301765c0066a04eC4FBdb59e3a,
        0xA5f09C6f40Aa9b8f7AD70d64c42e20df1aD1F0F4,
        0xfbDefB587455dBc22a6DFAe3fBe58146e2906c74,
        0x6d389587eac3DBDE0c625D616B6546Cc4dCbA6E6,
        0xc06057acf5c722e961184d3Eb751D93baDa7d72c,
        0xf4fF19C30c98533fd6D3cEcF09b3d6802e470dD0,
        0x151F444d27D865B7c732386c26ABf735e47A9333,
        0xd338C18e4dC5A1011E324a5334Ac0f62D11F67d5,
        0xD62748E6e8540644c2E8f2Cf221Cd894Cb945563,
        0x6Ac5bB295075944e9ABfF59230f72f9ee97d12EC,
        0x4791bc59e8bF9a12095C5A83612932adfEad3809,
        0xC082Cb0df2c0E97eCB8B72302Eaf9776223Fc707,
        0x903fcEBD7461c9849cEe84d51Ff3e963d3E74013,
        0x6cecA7911c1A4dd84451716B698995324609aD48,
        0x14fcc168e99cCccF6436C9eD8339Ce287d7d41c7,
        0x5d2e25D22262F927c0DA8f1aEce7e3075356316E,
        0xbA178AE12DAa78dE6592847cF8bb26508aE5D5Db,
        0x2E09B3D76ca30B672Ca2d59249f59CA4535C6e1a,
        0x29912021D3f9A824aa4F49595DdadFEB7C5f30E6,
        0x83241bc3e780691623D083a8DfF02F81E3A404f4,
        0x96F6a61a562f9c5194e3Ba25e45Db796a026e7cC,
        0xA132FC954338Ec0D92bb5a7805e56908Fb8DAE8A,
        0x43c7C3943A181774FD1791742EF6b42d671E30c3,
        0x7Fd6C3844264cd50aD2183afD058e3983DcEA1aF
    ];
    
    mapping(address => uint256) whitelistSergs;
    mapping(address => uint256) whitelistCDB;


    event SergDickButtMinted(uint tokenId, address sender);

    constructor(string memory _baseURI) ERC721("SergDickButts","SDB") {
		setBaseURI(_baseURI);
		setupWhitelist();

        for(uint256 i = 106; i <= 111; i++){
            _safeMint(msg.sender, i);
        }
	}
	
	function setupWhitelist() private{
	    for(uint256 i = 0; i < whitelistArrSergs.length; i++){
		    addToWhitelistSerg(whitelistArrSergs[i], i + 1);
		}

        for(uint256 i = 0; i < whitelistArrCDB.length; i++){
		    addToWhitelistCDB(whitelistArrCDB[i], i + 112);
		}
		
		_currentTokenId = 222;
	}


	function mintSergDickButtsTo(address _to, uint numberOfTokens) public payable {
        require(saleIsActive, "Wait for sales to start!");
        require(numberOfTokens <= MAX_PURCHASE, "Too many SergDickButts to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All SergDickButts has been minted!");
        require(msg.value >= price, "insufficient ETH");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergDickButtMinted(newTokenId, msg.sender);
                _incrementTokenId();
            }
        }
    }

    function mintTo(address _to, uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergDickButtMinted(newTokenId, msg.sender);
                _incrementTokenId();
               
            }
        }
    }
    
    function claimSerg() public onlyWhitelistedSerg {
        require(saleIsActive, "Wait for sales to start!");
        _safeMint(msg.sender, whitelistSergs[msg.sender]);
        removeFromWhitelistSerg(msg.sender);
    }

    function claimCDB() public onlyWhitelistedCDB {
        require(saleIsActive, "Wait for sales to start!");
        _safeMint(msg.sender, whitelistCDB[msg.sender]);
        removeFromWhitelistCDB(msg.sender);
    }
    
    // whitelist functions
    modifier onlyWhitelistedSerg() {
        require(isWhitelistedSerg(msg.sender));
        _;
    }

    modifier onlyWhitelistedCDB() {
        require(isWhitelistedCDB(msg.sender));
        _;
    }

    function addToWhitelistSerg(address _address, uint256 index) private {
        whitelistSergs[_address] = index;
    }

    function addToWhitelistCDB(address _address, uint256 index) private {
        whitelistCDB[_address] = index;
    }
    
    function removeFromWhitelistSerg(address _address) private{
        whitelistSergs[_address] = 0;
    }

    function removeFromWhitelistCDB(address _address) private{
        whitelistCDB[_address] = 0;
    }

    function isWhitelistedSerg(address _address) public view returns(bool) {
        return whitelistSergs[_address] != 0;
    }

    function isWhitelistedCDB(address _address) public view returns(bool) {
        return whitelistCDB[_address] != 0;
    }
    

    // contract functions
    function assetsLeft() public view returns (uint256) {
        if (supplyReached()) {
            return 0;
        }

        return TOTAL_SUPPLY - _currentTokenId;
    }

    function _nextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function supplyReached() public view returns (bool) {
        return _currentTokenId > TOTAL_SUPPLY;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function switchSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

	function setBaseURI(string memory _newUri) public onlyOwner {
		baseURI = _newUri;
	}

	function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		TOTAL_SUPPLY = _newTotalSupply;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
	}

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

}