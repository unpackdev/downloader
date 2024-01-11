// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "BeerCoinOrigContract.sol";
import "BeerCoinHolder.sol";


contract WrappedBeerCoin is ERC721, ERC721Enumerable, Ownable {

    event Wrapped(uint256 indexed pairId, address indexed owner);
    event Unwrapped(uint256 indexed pairId, address indexed owner);

    BeerCoinOrigContract bcContract = BeerCoinOrigContract(0x74C1E4b8caE59269ec1D85D3D4F324396048F4ac);

    uint256 constant numPairs = 77;
    struct bcPair {
        address debtor;
        address creditor;
        uint256 numBeers;
        address holderAddr;
        bool wrapped;
    }
    mapping(uint256 => bcPair) public pairs;
    mapping(address => mapping(address => uint256)) public indexes;
    
    constructor() ERC721("WrappedBeerCoin", "WBC") {

        // set up list of debtor-creditor pairs
        pairs[1] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[2] = bcPair(0x503CAcaA36b1e8FC97b8Dee5e07E2f29B17b3265, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[3] = bcPair(0x3530e43fCE4A27698DeCeCBff673A1D26f6068d1, 0xc97BE818F5191C83395CF360b7fb3F8054f31106, 1, address(0), false);
        pairs[4] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0xB4Bc91a35BB1D0346554F7baa29d6e87A630b2cE, 1, address(0), false);
        pairs[5] = bcPair(0x16B5bd98D638888FC92876cd6D6C446b6d307863, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[6] = bcPair(0xC86e32838e72E728c93296B0Ef11303B3D97a7A7, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[7] = bcPair(0x831CFfd303252765BA1FE15038C354D12ceBABd1, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[8] = bcPair(0x09239490B80dB265fE3120DF19967CfaAcF4463E, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[9] = bcPair(0x0a58b1C9aaF19693813c11b8a20D20C2a8Fe8883, 0xDFAEf2eeE901dde3f2f790b3D81c491D2EeEaeB4, 2, address(0), false);
        pairs[10] = bcPair(0x0EFE4959b1F91A6B60186726284D6F4d068816D5, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[11] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0xe25D09A11f351C5c4E5250A95bb023448eCbC04C, 1, address(0), false);
        pairs[12] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0xA529402B3E58b955EE7BA49FE853CfCF1bbD75fA, 1, address(0), false);
        pairs[13] = bcPair(0x3e782b7cd96e968B7F17d26F96d1577B3501F76F, 0x9C3C1F05DC5d1205C1824cfaD15307f9BF1fd72D, 1, address(0), false);
        pairs[14] = bcPair(0x5E44E1cb6F4991BEAe7C22f0177dF752169841F0, 0xC7B4F9e4932a4beb7402e20D9fb89326f0884626, 12, address(0), false);
        pairs[15] = bcPair(0x5E44E1cb6F4991BEAe7C22f0177dF752169841F0, 0x1e0F81E81Befb5Ae5B975cB0A80A48E86B9364cc, 1, address(0), false);
        pairs[16] = bcPair(0xFbDe24Ac8A2051d874a70CB18344dda8F2b54E33, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[17] = bcPair(0x63E6B51E290beEA1B6404F9D893110A6498a601E, 0xD6d5A0C02bBfFf176cCB4B3CFE12115A0ae46bde, 1, address(0), false);
        pairs[18] = bcPair(0xE8dF9A7C34736a482A861a49b51fbc1C4C031456, 0x35314B63867b3A201c838c6417c4E72EE9946F8E, 1, address(0), false);
        pairs[19] = bcPair(0x98B1658701bB6179a8Ec191f5F83fA776730Df15, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[20] = bcPair(0x98B1658701bB6179a8Ec191f5F83fA776730Df15, 0x712951253C9a5519ed199EA6F4D1a744535ec72F, 1, address(0), false);
        pairs[21] = bcPair(0x145Bc20c2Eb66aEfa7D5D49da74daAbb63c32D76, 0xD6d5A0C02bBfFf176cCB4B3CFE12115A0ae46bde, 2, address(0), false);
        pairs[22] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0xa34e7A26578BD3DF4411f45AF09E019dAd9F27c2, 1, address(0), false);
        pairs[23] = bcPair(0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 0x1daE0CEE62035444A159dd9cA3911A6A4baD77BF, 1, address(0), false);
        pairs[24] = bcPair(0x0AE14271999B68a35eEcb2Da492486e354ef672e, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[25] = bcPair(0xF7Bc5d229374470e3aDB671505c2C8a716810dC5, 0xd04e62191b27Fe60632C6999077000dAecA12881, 2, address(0), false);
        pairs[26] = bcPair(0xd674822D41520D95383e3015D3C0EE8C60f7719C, 0xd04e62191b27Fe60632C6999077000dAecA12881, 2, address(0), false);
        pairs[27] = bcPair(0x176D7673fDcB275BC3186412A922D2901068aaCA, 0x2a089726C072F5A00057373F697257CE6C492A35, 1, address(0), false);
        pairs[28] = bcPair(0xBfB21f5F2069eC2f0a3c5049DB7856a26fa5003d, 0x4bF54f201D1361833B3a2f8A1dbB702Ae0483c63, 1, address(0), false);
        pairs[29] = bcPair(0xFa6A0944543bC0536B18D05d740AF1C1d3381728, 0x607Aa83060A9B104849c643Bc305b93D757C931b, 1, address(0), false);
        pairs[30] = bcPair(0x6905CB6c44b37E13DdFE0C21643a3F4121428236, 0xABafA36e5907AD7DE32d7959877f6B68B9088847, 1, address(0), false);
        pairs[31] = bcPair(0x808aa6300acb9Dd0108e4b3E989C7523809983b4, 0x66C4F74E3EF54294ffa9e8237CC8D11d83FE497a, 1, address(0), false);
        pairs[32] = bcPair(0x58bbBeEa89189839cBBa3c1F96e43a581A5e2535, 0xa3c9a229b9749171D3ED23d790DF8AEBFE901C8e, 2, address(0), false);
        pairs[33] = bcPair(0xCEeD47cA5B899fd1623F21e9bd4DB65A10E5B09D, 0x38c7C05f8E37Eb97dDE95093f0c903C079A45fa0, 1, address(0), false);
        pairs[34] = bcPair(0x513644F3C7cC1100c7111Af894f136D0D47287D2, 0x153028dc4d8bc96aC873032843BA52Ace5E59e53, 2, address(0), false);
        pairs[35] = bcPair(0xaA5ba45127268b7E4B59058a952Ab1E926De2075, 0x4db6eEEc53885F2d66c070CC9aBB59a2DA1Ed39F, 1, address(0), false);
        pairs[36] = bcPair(0x1A2D543EA30fFb007072d2a75D7Cf9bF7e8DA616, 0x2e6DD331CF358430bcbf12306B41016AEe7781ee, 1, address(0), false);
        pairs[37] = bcPair(0xfaf3e7b0b878c9a98c023FEbebAe298eF3a9c245, 0x4dA2bF342C531407616f2bb100Daa6D6dBC54375, 1, address(0), false);
        pairs[38] = bcPair(0x167FFD913347aF05116F873C19a3fE14494aFD7b, 0x56c03A07433B771E73C19ca625232ED0d585E263, 1, address(0), false);
        pairs[39] = bcPair(0x3682Ae583f8C542ede42A9CA41105E5740B80D55, 0x49B3Bd416c1c41024d6141ACd0f366B0498cA5C8, 1, address(0), false);
        pairs[40] = bcPair(0x64b2D331b1a63846978f25070855aAFC50084ef1, 0x500e9FCee39A071c476C749BCB988C617381b8c5, 1, address(0), false);
        pairs[41] = bcPair(0xed889281648F618dd1cA9E07359BEd624B4A8790, 0xDBC1573bD5c31655b55C702406A2655BbD9dFA89, 1, address(0), false);
        pairs[42] = bcPair(0x3FF047E5E803e20f5eF55eA1029aDB89618047Db, 0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 1, address(0), false);
        pairs[43] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0x0037A6B811ffeB6e072DA21179d11B1406371C63, 1, address(0), false);
        pairs[44] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 1, address(0), false);
        pairs[45] = bcPair(0x63Cf90D3f0410092FC0fca41846f596223979195, 0x51d8782D82258441078E57141Daa8FFdDAf8f57D, 1, address(0), false);
        pairs[46] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xacbb6e2b07cdABa10dbD9A484865DE69cAF5e064, 1, address(0), false);
        pairs[47] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0x5E58Caeb958e67C89ADC9e5e6bcaa79795E8d3f1, 1, address(0), false);
        pairs[48] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xfEA7499bdEf1d8a66E8C5e3aD8014b837ceE239c, 1, address(0), false);
        pairs[49] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0x484Aa92Fa68031774140Ab9833b1615c07359b9d, 1, address(0), false);
        pairs[50] = bcPair(0xacbb6e2b07cdABa10dbD9A484865DE69cAF5e064, 0xf3946c397dbef1356e24ca6584D798d5150F521E, 1, address(0), false);
        pairs[51] = bcPair(0xF6ABb80F11f269e4500A05721680E0a3AB075Ecf, 0xDbADdbaE610da85FA15A9F7e279d9A9d68B05c01, 1, address(0), false);
        pairs[52] = bcPair(0x3906842E00abf96cc58300BeC49124e6A36a46DB, 0x7632b6E235201Ec2CD8A6547ba836229101f5711, 1, address(0), false);
        pairs[53] = bcPair(0x260F180cFaa31e8A615545767461D4A0d72902E4, 0x3a7dB224aCaE17de7798797D82cdF8253017DFa8, 1, address(0), false);
        pairs[54] = bcPair(0xBe00b986EaE90D5c65e31A3C0B6136d51236d7B5, 0x4C82a81aE95A5E79750ad617CdE4beBdEe2d0536, 1, address(0), false);
        pairs[55] = bcPair(0xbfaA871Cc61533679fB74e583e2E023a920fB565, 0x244E9b38FC1c655de53A8ba5A4760F6E8001403b, 1, address(0), false);
        pairs[56] = bcPair(0x0003E8f7a763277D10AA6b6683a97C7e7890bda9, 0xD4FA839eDE2723d0F6394Fd1BE42b7A0Fd63e7c4, 1, address(0), false);
        pairs[57] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0xD0944Aa185A1337061AE20dC9dD96c83b2bA4602, 1, address(0), false);
        pairs[58] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0x7cB57B5A97eAbe94205C07890BE4c1aD31E486A8, 1, address(0), false);
        pairs[59] = bcPair(0xd1324aDA7e026211D0CacD90CAe5777E340dE948, 0x65DDc3a1f2762f3d0669bbEeA44E16B2b38090A5, 1, address(0), false);
        pairs[60] = bcPair(0xd1324aDA7e026211D0CacD90CAe5777E340dE948, 0x677748842FC14d7f4a3f6fB533ab16613C50a9B9, 1, address(0), false);
        pairs[61] = bcPair(0x00dFf2030dF1cC59Df5305597eD02F4cDF1AEdA9, 0xF4ED444467E7726741287cD8E2c97C112D17Cc36, 1, address(0), false);
        pairs[62] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x6A3468B46eF13A96A9319C304be711aCb5dC20BE, 1, address(0), false);
        pairs[63] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x5Dc6Fb59078789d4D185e4c1CEc9984807DB46Dd, 1, address(0), false);
        pairs[64] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x8E46e5E47418487e6B47057249e81B1BfAda0450, 1, address(0), false);
        pairs[65] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0xF9F3beB1D3C581469b73cbEA560Aa605cA27d618, 1, address(0), false);
        pairs[66] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x92D017aE54748f1f60dAdCCD98C3D8C24E2Bf465, 1, address(0), false);
        pairs[67] = bcPair(0xC5510DD4D6dde2f144034b63ad6556149f5684D1, 0x071DA95DA643FE9CBdCA939D054B5bEc9cB68543, 1, address(0), false);
        pairs[68] = bcPair(0x7777777d56309Ea59568e5EC24c1705bDD5EcA28, 0xc0fFee3BD37d408910eCab316a07269FC49a20EE, 1, address(0), false);
        pairs[69] = bcPair(0xCC3d8656166d738a2B3C96Cd475405c668352989, 0x5171d344E2381424C408Ab4037C92a65F185618b, 1, address(0), false);
        pairs[70] = bcPair(0xCC3d8656166d738a2B3C96Cd475405c668352989, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[71] = bcPair(0xc0ffeebCe16ECBbb28Fc8568dB679b48e1C975F9, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);
        pairs[72] = bcPair(0xD0944Aa185A1337061AE20dC9dD96c83b2bA4602, 0xc0FFeEcE5397F30E18A8dd7A92644178675FBBbE, 1, address(0), false);
        pairs[73] = bcPair(0xc0fFee3BD37d408910eCab316a07269FC49a20EE, 0x88Fd7a2e9e0E616a5610B8BE5d5090DC6Bd55c25, 1, address(0), false);
        pairs[74] = bcPair(0x09aDDe38e55e4Db60A048c11e1de4f11Cc14e97b, 0x879B12C310B5C6596618B777512eaBFca98f18C3, 1, address(0), false);
        pairs[75] = bcPair(0x22F3BA469d0F91A173b1aCCeb7f211CDbde8C27B, 0xB8fc8C2f69f5C02FbdeF062f12C4875D8647A3b1, 1, address(0), false);
        pairs[76] = bcPair(0x22F3BA469d0F91A173b1aCCeb7f211CDbde8C27B, 0x00353dC8b8425298b8B6bDf587c4f5631601715C, 1, address(0), false);
        pairs[77] = bcPair(0xD88e34c9894a69b7302e2B09ac9b9c30Aa2751fC, 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9, 1, address(0), false);

        // establish mapping from debtor-creditor pair to ID
        for (uint256 i = 1; i <= numPairs; i++) {
            indexes[pairs[i].debtor][pairs[i].creditor] = i;
        }
    }

    function Wrap(address debtor) public {
        uint256 pairId = indexes[debtor][msg.sender];  

        require(pairId != 0, "Invalid debtor-creditor pair.");
        require(!_exists(pairId), "Token already exists.");

        bcPair storage pair = pairs[pairId]; 
 
        require(!pair.wrapped, "Cannot wrap more than once.");        
        require(bcContract.allowance(msg.sender, address(this)) >= pair.numBeers, "You did not give wrapper transfer permission.");
        require(bcContract.balanceOf(msg.sender, debtor) >= pair.numBeers, "Original IOU no longer exists.");
        
        // create holder for the IOU
        BeerCoinHolder bcHolder = new BeerCoinHolder(address(this), pair.numBeers);
        pair.holderAddr = address(bcHolder);

        require(bcContract.allowance(pair.holderAddr, address(this)) >= pair.numBeers, "Holder did not give wrapper transfer permission.");
        require(bcContract.maximumCredit(pair.holderAddr) >= pair.numBeers, "Holder does not have enough credit.");
        
        // transfer IOU to the holder
        if (bcContract.transferOtherFrom(msg.sender, pair.holderAddr, debtor, pair.numBeers)) {
            _mint(msg.sender, pairId);
            pairs[pairId].wrapped = true;
            emit Wrapped(pairId, msg.sender);
        }
    }

    function Unwrap(uint256 pairId) public {
        require(_exists(pairId), "Token does not exist.");
        require(msg.sender == ownerOf(pairId), "You are not the owner.");
        
        bcPair storage pair = pairs[pairId];

        require(bcContract.maximumCredit(msg.sender) >= pair.numBeers, "You do not have enough credit.");
        
        // transfer IOU from the holder
        if (bcContract.transferOtherFrom(pair.holderAddr, msg.sender, pair.debtor, pair.numBeers)) {
            _burn(pairId);
            emit Unwrapped(pairId, msg.sender);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://spaces.beerious.io/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}