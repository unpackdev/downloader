/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Pandamonium is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    uint256 public constant MINT_PRICE = 60000000000000000; //0.06 ETH
    
    address public pandaOwner = 0xa929c6573744901ad5143cC8338BeD6954AA0F17;
    address public genDeveloper = 0x95e9A96e8226ea899BBf7E5DDD4aBEEf87265fA4;
    address public developer = 0x23241Aa35579312f2694DfDe5E9180Bd84268EB8;
    address public charity1 = 0x2fCDcDC2f746E90696bae4688301923eF2bb99dD; // Code to Inspire
    address public charity2 = 0xaAd70f80E4D9d1a22058EAe42c4830978F91bEc2; // Tuna Panda Institute
    address public charity3 = 0xFA1Bd6F6F807b6327B9a4d4ce57A7916dB29c991; // Thousand Dreams Fund
    address public charity4 = 0xf22351dA9442aE96f6231c3178a686a6C64E7E90; // Wolf Conservation Center

    uint256 public constant MAX_SUPPLY = 8848;
    uint256 public maxMintPerTransaction = 15;

    // address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; //testnet
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; //mainnet

    bool private _isPresaleActive;
    bool private _isSaleActive;

    mapping (address => bool) private presaleAddresses;
    address[] private addressses;

    string private _uri;
    string public provenanceUri = 'http://';

    event MintPanda(address indexed to, uint256 indexed tokenId);
    
    constructor() ERC721("Pandamonium", "PANDA") {
        _isSaleActive = false;
        _isPresaleActive = false;
        initPresaleAddresses();
    }

    function initPresaleAddresses() internal {
        addressses = [
            0x8f09cab21E32219618Ce302fC60abB9F4dfbb86D,
0xA4E6D415ceaB712B083DCC15a7Eb0D057D3c2D1B,
0x39a8c599E4a48910663543665d3095614EC2412E,
0x96EE4C272B6f8268b4fEF70Bb2983e4C6Ea8DF25,
0xa84544D65685a56590bE81DbdBcC9ADfdf0246cB,
0xD2707eC031B458B162fCa296aBC494433cdAFEA0,
0x638144eEe0ca1A5E38A1D8770C1b6C8A852C86fC,
0xF2c519b1633241cDdfE21CeCaE1A5B0FA4C776b3,
0x57C4EA109B8633066a01b676Dcc8216461fce588,
0x0Bc53A5225417682Cf22EDAC420E9D17b32EcC08,
0x08E9174944e6c611d24c7875C5Fa4D2C2F23C51C,
0x9b5146a53FA189102c17D711FbC222AAe72E0B60,
0x3a454148aF9667C8ffeefC0D9ff475d1bfdDd69B,
0x6750dAbfC98381f19Ce36eF8bF378C48e746F4c0,
0x30B8fB500C8501aCEC103DEd22E59eEAc83220d5,
0xFE8201Ce69A82DEa64e633eC37b0b719eD316402,
0x7E4a82326dCb5f40851Dcf67b145a3ee68Fb1d19,
0xF813E0de2293b487F75CaCA607290F3161944F3C,
0x8C8DC4132888B33fc1E7Eb99977b9d3596D7184a,
0x6141e46C7F82443438EC42cD68BDba0c5a6Fd4cF,
0xdEb6019B785AEFD31769b1Ac1f0081810fdE0faF,
0x2ee52488e2192FEd2B5474590A1CC8C95B2Bd6F6,
0x2BEa720a5fe5e7738d775e8BfD3a37Fa072Cd46c,
0x1001F890b3eafAF2CD2a982B0e3f33DabCe78fCD,
0xC81d405b17E3787F67BCF9fAe18Fd5920c1F2Ac0,
0x7E4a82326dCb5f40851Dcf67b145a3ee68Fb1d19,
0x579a28f0DC9800400234516499DEaA4DE5be0e25,
0xF6296a5adf7a0590D4E52Ac3d1977f6A3811E77e,
0xF13CCD4013DA3dc7b2dfbB2397dc9F5db8C1A44D,
0x30B8fB500C8501aCEC103DEd22E59eEAc83220d5,
0xEb4DD8F8ed49456a3dC3614bf38438E5DC49fdA3,
0x946F3dBEFB64a4D43987d06C3c7F2cb1E0ddB035,
0x2F7C2681d68F68f8A30015FC227B85e3189A6614,
0x6189717673E1ed5DA55080D0898C70F91d2784d0,
0x734F4229539926068952fbEff7A2B82b7a6ebC4E,
0xDB216E118c27f9809d38D4A51DE9A6Ecfbb55015,
0x1C90d76468176a0Caa4BaF141677f253F73c83C2,
0x0934e8E0310CC440F16B2543b2e22068d849a145,
0x4F234aE48179a51E02b0566E885fcc8a1487dB02,
0x9a837c9233BB02B44f60BF99bc14Bbf6223069B8,
0x561061001a697b58fA2b68602f15eAF2d903eecE,
0xE0661747d581f98B24f10b7C4dD271104965Ad1A,
0x5AE7cDf0f8d3e18600F0C3E0927391440e3014D8,
0x9751491718a5E029F47C2272A7f93Cb9AE233cb5,
0xDDE1B9F12e6FF68f35eC164Dc4A269beca33679b,
0x5C34E725CcA657F02C1D81fb16142F6F0067689b,
0x73A933ea8F818B2438627f220a5fc1b3D51c9dEc,
0x80040312D5B96eF9C459BDC68451aBA61eBFb7EF,
0xc9dF577d0b5d895b4304676c64fac66B41838FEF,
0x8dBAF8fce10Ac7B9cea9057bdec512d90b4BBF80,
0x630ce0e70B9A0e9d45d155b97CA974F96621df75,
0x5AE7cDf0f8d3e18600F0C3E0927391440e3014D8,
0xcfBc3F4675100801affE464281f08783946eD450,
0x9a837c9233BB02B44f60BF99bc14Bbf6223069B8,
0xB887A81683ed3cD4a5C0414C5456B6D7F0E11b00,
0x20a7854A37D095cffc69c075Bf133015FC5493Cb,
0x5AE7cDf0f8d3e18600F0C3E0927391440e3014D8,
0xB3bce45dc1B47D1733A08Bf040289eDbb1710ba8,
0x430f3b4D073111E170ebf06644208a57e048d2bc,
0xCDfB8A347211c95364Cca2177d82C18950A21c4b,
0xAf616d09D5eC4e1e1B094c16a2915370B9D16c1a,
0xb352668Ba98256C9e843c7A3Ba72e67164488678,
0x6b803123c5fb72b772f1326D3b80E4CC5b992A24,
0x5BBDA405FEB53fb457C086eD8A941e7535F6130C,
0x9BB53570a65D2AcF2D9D1A5fA7D26A38eCd3C3da,
0xD4F743AA0Ea73cf1b52aE27e17A653BE1370518F,
0xf1b4a98bcace7f362015c2bD245cC4bC6F3f7BF2,
0xe74a12e1bEFb0d65a399db1A6e231abD8Cf4E746,
0xbE6391E0aBb200c942eecFb24EB7910663aA7EdC,
0x0454C1bE4F5254c96cB124A75A6247a553BB58e1,
0xbFe8d5aBf248081FE03236E31EFdfdFE1562F9a2,
0x343f43F69b26F44CfC1206e5B11bC0BfB3a1188a,
0xed969ACA2BDc511798FB360a7bfBdfCB5B8BD915,
0x1d5C7762b24D6926276dBFC272883a9Fc0eCa8F7,
0x656e13f0B221232eF31a1b3d9F6C18a44A619f49,
0x2Fd0C9620B1c13Ffe6E4eAC4C3628e965aA71690,
0xbaEa9d7C1a93F05F075AC9fCc95b5Fe22103b77e,
0xB4B1F87A6C2C95726ca3aaF9E3a06142D78E3Ac4,
0x0C4311b49D33a74C9f50cD42796eFDcEe4468510,
0x9cBFC9Cda35D51f370a6148849b107Aa3cc5f745,
0x3359CaF7070784ccE146985E0fd4f54008C888FE,
0x217d83bbe3693365b6BD40f4Dd2019b4aA7C681B,
0x27eE8FA6a70a8F156008EDe28C7B8ea5F72fFdF3,
0xA7E3c6c2cB4C78C510Da6C84933CE021a9B18b0A,
0x06d0BDAEB64e50FB5068173E000e32599Ae6673B,
0xa0e1A25976Be2b9ea5Ec305dC332325311b0124c,
0x20Ee31efB8e96d346CeB065b993494D136368E96,
0x9Ee4Be040cB8D8cFe13753166D6d836B84A0d6cc,
0x1a7ef4089Fc9630299Ac3d54c478e365d3876650,
0x8011F9Bb55e6BEeC05BcE1e64Ff669eAC33afDa4,
0x1563Df6Ba2E1b577c27183e6fad8684890d35392,
0xA2fcc8CA6b9eA87ba805c739B73cB17B0FB45547,
0xDb21ee947CbA24dFF405ed5Ee33913af4C5f7C0b,
0x30645a0F9b93633453493cB4029Fa9f2a4e9460B,
0xF0bF1C59ee9b78A2Ce5763165e1B6B24Cb35fD8A,
0xe336647d97414E5613c31b321306708bE29B6E0c,
0x9A8b253C304b897AF8147143c5D0db4635E8c9C6,
0x048914A24912004ecaA6a99B7A4fb99A9d3931A0,
0x10325676aD2701cDE23bf33a2a1aa00c4811Be7c,
0x207f17204c721e0D5E4C390d0662d68e282556D1,
0xB8EF48e839E0D9c73bc2171618C1430a5Aa3F4Ce,
0x97143caB6EA99d22BdA159a12D126c30b0cFa354,
0x0b9c75E3786Fbe0c7c795C4fEe19111693b529C8,
0x279A3fdbD6d6252Afc5C422439C7D7859a51a05E,
0x773B5337c547CE517653D35783A4f0e404AC872F,
0xB7Ab0049084eb7022f1Dbfe74038d396c418d105,
0xf30B7aE9dC4AA57D81c06fc25FaB75ff5fab3c98,
0x8Cc8d899AA7334f530560fC0C053fB5C6CF5f443,
0xf30B7aE9dC4AA57D81c06fc25FaB75ff5fab3c98,
0x20Eb74972C7bb0b0a13b53e1b1b7A4203D001459,
0x6839d234CF9E308bbE63423D1BEC2Fe2465ceF9B,
0x93c22236CEc86c4451bf266218f8aB6216D7866f,
0x143E690D34d71c805c5443c5273ca921E5f47d61,
0xd8F3AE96340Ff800F687E001347A010b847643BF,
0x722b6b32E54Eb32108d838eb77D45322e3bD762e,
0x74Daf8b664a5769C6bb490965E97b22B5B216fD3,
0x3Fa3b6e00CFA24f5d37C03b37fcd2Fa5a0f700D0,
0xFa0990C4752F064f06B089272FB24B067dd5828E,
0xB89D16BEaC18E513743baa6a6E09F60460367aC8,
0xD2Dd52e3674E15fEC188345B1a090b887c25A25C,
0x4CE39Bd7b90194e43A379A35cd6d4ac0a4b965C5,
0x773B5337c547CE517653D35783A4f0e404AC872F,
0x1A86C1B2727cB9F5f077b47314312bb036F1A0cB,
0x616ed054e0e0fdbfCAd3fA2F42daeD3d7d4eE448,
0xDB216E118c27f9809d38D4A51DE9A6Ecfbb55015,
0xaD65B2126a56875A6107F7ebDEabC6a12Fd9ffAC,
0x94bf2eca7F8D4Bd7c85d5096Fb83C72CE6D3C08e,
0xfb82F8C838Ba2de8C8FABE225485656afce1Ed94,
0xbe017be2D41f3965Aab034d71316F7662F50E9fB,
0x8B83aA53DC74e3b54E9C4DE8349CdBB6d9D9C652,
0x5Ee076E6C335c191f26C95A15311de925069F46c,
0xC42066767ed03DB6d0A9A9436a2D34Ef6b07FA00,
0xC81d405b17E3787F67BCF9fAe18Fd5920c1F2Ac0,
0xdF269915Bc019A4305237007F1b418351252B43c,
0x170Fa4320CEd15ceadb2567c1f8Fe254A974Bf19,
0xfb1C7C10f8464AC675C071202bf2D1A4D5eECE24,
0x41285De3f6BeAEB89427421A5B71c4fe26604c6B,
0x5B5CCD33Def76122875B164D2AcD1D4e60dDF4Cd,
0x41DcfB129Bd1cB4215c18a3219698744Afb10F72
            ];

        for (uint i = 0; i < addressses.length; i++) {
            presaleAddresses[addressses[i]] = true;
        }
    }

    // @dev Returns the enabled/disabled status for presale
    function getPreSaleState() external view returns (bool) {
        return _isPresaleActive;
    }

    // @dev Returns the enabled/disabled status for minting
    function getSaleState() external view returns (bool) {
        return _isSaleActive;
    }

    // @dev Adds an address to presale whitelist
    // @param address: whitelisted address
    function addToPresale(address addr) external onlyOwner {
        presaleAddresses[addr] = true;
    }

    // @dev Adds an address to presale whitelist
    // @param address: whitelisted address
    function removeFromPresale(address addr) external onlyOwner {
        presaleAddresses[addr] = false;
    }

    // @dev Allows to set the baseURI dynamically
    // @param uri The base uri for the metadata store
    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    // @dev Update charity addresses
    // @param addr The address for the charity
    function setCharityAddress1(address addr) external onlyOwner {
        charity1 = addr;
    }

    function setCharityAddress2(address addr) external onlyOwner {
        charity2 = addr;
    }

    function setCharityAddress3(address addr) external onlyOwner {
        charity3 = addr;
    }

    function setCharityAddress4(address addr) external onlyOwner {
        charity4 = addr;
    }

    function setOwnerAddress4(address addr) external onlyOwner {
        pandaOwner = addr;
    }

    function setDeveloperAddress(address addr) external onlyOwner {
        developer = addr;
    }

    function setGenDeveloperAddress(address addr) external onlyOwner {
        genDeveloper = addr;
    }

    // @dev Allows to enable/disable minting of main sale
    function flipSaleState() external onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipPreSaleState() external onlyOwner {
        _isPresaleActive = !_isPresaleActive;
    }

    // @dev Dynamically set the max mints a user can do in the main sale
    function setMaxMintPerTransaction(uint256 maxMint) external onlyOwner {
        maxMintPerTransaction = maxMint;
    }
    
    // @dev Presale Mint
    // @param tokenCount The tokens a user wants to purchase
    function mintPresale(
        uint256 tokenCount
    ) external nonReentrant payable {
        require(_isPresaleActive, "Presale not active");
        require(!_isSaleActive, "Cannot mint while main sale is active");
        require(totalSupply() + tokenCount <= MAX_SUPPLY);
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= maxMintPerTransaction, "Token count exceeds limit");
        require((MINT_PRICE * tokenCount) <= msg.value, "ETH sent does not match required payment");
        require(presaleAddresses[msg.sender], "Address not whitelisted");

        _premint(msg.sender, tokenCount);
    }

    // @dev Main sale mint
    // @param tokenCount The tokens a user wants to purchase
    function mint(uint256 tokenCount) external nonReentrant payable {
        require(totalSupply() + tokenCount <= MAX_SUPPLY);
        require(_isSaleActive, "Sale not active");
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= maxMintPerTransaction, "Token count exceeds limit");
        require((MINT_PRICE * tokenCount) <= msg.value, "ETH sent does not match required payment");

        _premint(msg.sender, tokenCount);
    }

    function _premint(address recipient, uint256 tokenCount) private {
        uint256 totalSupply = totalSupply();
        for (uint256 i = 1; i <= tokenCount; i++) {
            uint256 tokenId = totalSupply + i;
            emit MintPanda(msg.sender, tokenId);
            _safeMint(recipient, tokenId);
        }
    }

    function mintOwner(uint256 tokenCount) public nonReentrant onlyOwner {
        require(totalSupply() + tokenCount <= MAX_SUPPLY);
        require(tokenCount > 0, "Must mint at least 1 token");

        _premint(msg.sender, tokenCount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(developer).transfer(balance * 10 / 100); // 10%
        payable(genDeveloper).transfer(balance * 3 / 100); // 3%
        payable(charity1).transfer(balance * 75 / 1000); // 7.5%
        payable(charity2).transfer(balance * 75 / 1000);
        payable(charity3).transfer(balance * 75 / 1000);
        payable(charity4).transfer(balance * 75 / 1000);
        payable(pandaOwner).transfer(balance * 57 / 100); 
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
