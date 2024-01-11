// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract ERC721Royalties is ERC721Royalty, ERC721Enumerable, ERC721Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    //configuration
    string baseURI;
    string public baseExtension = ".json";

    //whitelist
    mapping(address => bool) public isWhiteListed;

    //set max mint at time
    uint public maxPerMint = 10;

    // set address of royalty reciver
    address payable constant royaltyReciver = payable(0x4CBFd0CC1a9ae15630eE01334e94b0703a94A2b3);

    // Akoin address to get mint share
    address payable constant anftAddress = payable(0x20EE65db06bb63761519B79CB874963A728F52fC);

    // Mad dawgs address to get mint share
    address payable constant madDawgsAddress = payable(0x4CBFd0CC1a9ae15630eE01334e94b0703a94A2b3);


    //set the cost to mint each NFT
    uint public cost = 0.06 ether;

    // Akoin share of each mint
    uint public akoinShare = 0.015 ether;

    // Mad Dawgs share of each mint
    uint public madDawgsShare = 0.045 ether;

    //set the max supply of NFT's
    uint public maxSupply = 5250;

    //set percentage that original owner will get after any future transfer 1000 == 10%
    uint96 public royaltyPercentage = 750;

    //are the NFT's revealed (viewable)? If true users can see the NFTs.
    //if false everyone sees a reveal picture
    bool public revealed = false;

    bool public inPreSale = true;

    //the uri of the not revealed picture
    string public notRevealedUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setRoyalties();
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);

        // increment to start ids from 1 not 0
        _tokenIds.increment();

        // whitelist
        isWhiteListed[0x30a21ECE1AEEFcd4b5fd4C9369e9b3183ee1d00b] = true;
        isWhiteListed[0x7EE46558a4471C14D6AFe213213dB019549a318e] = true;
        isWhiteListed[0x1d9a6Bc9036F8B9F78AFC50080a30F47458528Cc] = true;
        isWhiteListed[0x7B1Ff45F74bEf1be71cC2532316Ab08f0CB03048] = true;
        isWhiteListed[0x7a661E2BaB47Df6f9772f9dd568b7895726aAeE4] = true;
        isWhiteListed[0xbED3D741f7Ad0fF979EB85a1f293898dF7778882] = true;
        isWhiteListed[0xDd0ea1914743f0D3617b54Ac4653BF82fbcfFE18] = true;
        isWhiteListed[0x24acb63DAb51ff479F212DB80B114fA4e6629D8b] = true;
        isWhiteListed[0xAd6dee4c62ed936F6FFAAd6fC0ef7FAB7502F725] = true;
        isWhiteListed[0x01e6b318307134A28CF31379470b58C84926d0FD] = true;
        isWhiteListed[0x2Fb8a0110B182395C8da8a7123b9038AbC128751] = true;
        isWhiteListed[0x0962fd025ef05Fb60A194DE87A236d61d05eaF71] = true;
        isWhiteListed[0x74DFE88878b99FD82c47e0B07C13d5C193ba5524] = true;
        isWhiteListed[0x07e15F43D4EAAce2DADC9117Fe55d39B5B87f87F] = true;
        isWhiteListed[0x1737C9D4496f1C0dcc933bB290d0AA9c5E485d90] = true;
        isWhiteListed[0xdD2f3cfC6310F0365E83Dd964D38a06e10Cca69E] = true;
        isWhiteListed[0x6c00d03988f6cf738fF3c31D7cb1B5134Ba94c24] = true;
        isWhiteListed[0xDec7ECCA3Bf30e917C7765671FceCCAe62E5C564] = true;
        isWhiteListed[0x52BA15A2efbbBeF74B259329D82585DaA170dafB] = true;
        isWhiteListed[0x5a477EfE9cA467233E9B21a9586156864B2E60e6] = true;
        isWhiteListed[0x14E844d570a7de9E19305EC25c590927ca847a00] = true;
        isWhiteListed[0x984Fbd7d961B1aa7FBD59b381f11bbC9B84534E9] = true;
        isWhiteListed[0x6Cd0Cbcc65FA109A0739ae198d587136140cC433] = true;
        isWhiteListed[0x9e853937Ab5D8AC116dda0Ca15715bfb7C26557d] = true;
        isWhiteListed[0x8EE47185210c219EF679008Cf3EC8942119B9280] = true;
        isWhiteListed[0xF1F015589acAd584221736D67796279B7b3f05d7] = true;
        isWhiteListed[0x38A4A35791BDAD0568D0e1CAa29fFC5c75088CA3] = true;
        isWhiteListed[0x7c5C510796ccD1EA08d8902c617D315935df7cb3] = true;
        isWhiteListed[0x6AbA6a02ca1E019F15bd2a7E0f5200F0FBeb0bEf] = true;
        isWhiteListed[0x37e3710F35C414d3b9D8c6Fd716D1F890A27ABB6] = true;
        isWhiteListed[0x361A58532a16a660E6312B50E9066b6828531081] = true;
        isWhiteListed[0xe2F902Fc5Fe96A735089a5A3F67A8106D8Fb5369] = true;
        isWhiteListed[0xE67b404e1e2a28D032A3280377eC94E2CDF36443] = true;
        isWhiteListed[0x9f0D4E1D0CdE119fCAD35b566cAE5b7539962A03] = true;
        isWhiteListed[0x426431af5562E7957DbCd29830c103D03131477D] = true;
        isWhiteListed[0x5D5D3204a7be5DbD1Cc47B16E312c54ff1598bb0] = true;
        isWhiteListed[0xe92cF783D2906A0cf6355634144115aA52F7fD0a] = true;
        isWhiteListed[0xFBC8e9BA88F833A89c6320160Df4032B47919D77] = true;
        isWhiteListed[0x7F25aD399e4B7f10d2791b94Abf17045D249Aa5F] = true;
        isWhiteListed[0x411D1f5341426E4813C84bCE04D93c24C1B303FD] = true;
        isWhiteListed[0x4c0df90a1807F4AAabA4FD7055b3F3B0B0FC069a] = true;
        isWhiteListed[0xEb123c595118F710E2c88436772E68A08c345550] = true;
        isWhiteListed[0xcE353748B2B8e8592e2D72718A86c8BcC7be0c6d] = true;
        isWhiteListed[0x47fA7bC9692f51ED1398DF9Ef177B62805D386b0] = true;
        isWhiteListed[0x2958766219B27a94e2F0713409A888780d07Ca55] = true;
        isWhiteListed[0x1942B91C8b8Ec2a940Ed6908Ecba638d75eD32eb] = true;
        isWhiteListed[0xD2b4306F401843C3087F50228C7e9CE5B3e9f9C9] = true;
        isWhiteListed[0xE2E981D5FB8037236AD8eE1D29B5b13fd7C4249F] = true;
        isWhiteListed[0x4b05E2448D99E01330a28c5E445e2a3Cf2D8bCee] = true;
        isWhiteListed[0x6e232d251471bb7F6Ed59B45c2117d3850dE1258] = true;
        isWhiteListed[0xe2E4F0F20D8d20a5Bc9375e45E510A54B9918215] = true;
        isWhiteListed[0x26554BCe99C80b8a4bDbc2611a0A2eC261a32918] = true;
        isWhiteListed[0x98279EFfa5D1D8B86Ac9D1DA8b5C58F911107F9E] = true;
        isWhiteListed[0x9FE5B15279A6B46EF63c7aEdb22e6e82ff79E597] = true;
        isWhiteListed[0x3914D4F1FbEc7b9BD04840BdD3F0D83E59788eb8] = true;
        isWhiteListed[0x8cA8cc263e0DCd76F5d43AB8eea4D49CB976D181] = true;
        isWhiteListed[0x3Bc6D2F5fC3e42ADC952450483eA9186F76c1BA1] = true;
        isWhiteListed[0x4E1e7Fb94C30c89D4E9C3e303710d8Da563b18FC] = true;
        isWhiteListed[0xc90a6F79514080E2eC1dA17E5DCf8290f3C3Eab3] = true;
        isWhiteListed[0xb9d3318D6cd911cE62540DEbAec691Bc76C471F5] = true;
        isWhiteListed[0xa25745aDA04468A397B485690568AE0C4c201f6D] = true;
        isWhiteListed[0xD76174B3E02A836DD6e4E5569C9e95d51604244c] = true;
        isWhiteListed[0x2D0038e9a2384C66bF787b22019c52a71BacB4F0] = true;
        isWhiteListed[0x777950AA5b783259A2Cb647DFdcBD8D55ef83F8D] = true;
        isWhiteListed[0x728e738b191bcCb03AaC2FE06f723311111ca2b4] = true;
        isWhiteListed[0xFf0FAFB54823806eCcA746a9dF5Be8B14bb9AF72] = true;
        isWhiteListed[0x6614806AC1e75b37fF284E04EAF59840b26008E1] = true;
        isWhiteListed[0x6D0Fa545D186612558ef2310Db71b87b25d72ee7] = true;
        isWhiteListed[0x0C28e099Ee51CF51c863383b762d35602E8Db108] = true;
        isWhiteListed[0x6b16aC71c09a55ea975f945650670282FAA3F809] = true;
        isWhiteListed[0x98Ae4340bf78957A401C5b19c38ec4bE20dcA245] = true;
        isWhiteListed[0xa9AAd3FF98991b89b49BaBf6Cd387C44a0A31515] = true;
        isWhiteListed[0xEA7995ffc54D6616fa1d121c86310f4442860073] = true;
        isWhiteListed[0x8B0729b15C8044971e049e623590bEb35C329805] = true;
        isWhiteListed[0x42DC09B6438bC8365242c53AD606879973C71B15] = true;
        isWhiteListed[0x10224c19e7Ce6464F68E1FD317Ab2b7bfb119EA2] = true;
        isWhiteListed[0x960C4CBA0a9dCBa913F52053cB487DC76C756165] = true;
        isWhiteListed[0x73306b851A2d65C8fc8C4Fc01e5106F81EADBe27] = true;
        isWhiteListed[0x113807353c8Fd966fA9C873Ba90A0A0822A721CD] = true;
        isWhiteListed[0x1f48c9342541e7166D33fb5Dc8886362F33Fe4e9] = true;
        isWhiteListed[0xD2135db128baAcF6d5C53D068893531D73202381] = true;
        isWhiteListed[0x00d35B5D764A5e96859F24AF7337DE981F01A41d] = true;
        isWhiteListed[0x197D1109285f48984DA2c7efd237C41e28c6517e] = true;
        isWhiteListed[0x1802c0fC10B34C81411D7667FFF52771ffBCCb66] = true;
        isWhiteListed[0x323681cccEd4c6445fa8754ae80e749793c4f7E8] = true;
        isWhiteListed[0xD91cb032a762e542e2a62106BD4bf9927f183323] = true;
        isWhiteListed[0xcB8F53942Ae4631DEf0dBa89BaA69414729Faf75] = true;
        isWhiteListed[0xcDB0d203BA6ef53312C56e3651430fBd46CAFd51] = true;
        isWhiteListed[0x73B8b3e78beAACdBf4018A2acD22D0eE663aCC01] = true;
        isWhiteListed[0x96340FE1A8aC1EC298413F54456860F9a93bd4d1] = true;
        isWhiteListed[0x3a98E58Fd77C66f3a5bdE49F7947317dF9B68830] = true;
        isWhiteListed[0x0579Fb3398C9877B9878f07AFf7b4Aa911CA9388] = true;
        isWhiteListed[0xD91cb032a762e542e2a62106BD4bf9927f183323] = true;
        isWhiteListed[0xC1330Fe484DFE393ce5611e2f49fC1547a5253ED] = true;
        isWhiteListed[0x9Af74024AC2c0d111007422D105A079B3076097f] = true;
        isWhiteListed[0x1F0512de1856662b3B621E910d6B102b117A53E5] = true;
        isWhiteListed[0xAa884ac9BB63d810baEdA6a4A5E8406FEE088D51] = true;
        isWhiteListed[0xcB8F53942Ae4631DEf0dBa89BaA69414729Faf75] = true;
        isWhiteListed[0xBd17e9f63C7025cB92de7bEdd4100F77498f70fB] = true;
        isWhiteListed[0x8d4003E339fF4Bd0679439aA4eFacA798B201166] = true;
        isWhiteListed[0x517409743B4C0E0b6B44F892082B5263Ac8Fe495] = true;
        isWhiteListed[0x0fBdFD11c14633f04B0D367687d7854e4D784C4D] = true;
        isWhiteListed[0x37e14657BDD1A67C43572D84E221E4c7b70B8c19] = true;
        isWhiteListed[0xaD79452d5215737DFBc1880f0C4CB47362DBDF30] = true;
        isWhiteListed[0x4253c8A1138EDC1E7C6b4eb03417A3551492B26E] = true;
        isWhiteListed[0x6BB1320662605Be5016324aAEF9B6120451FC1D0] = true;
        isWhiteListed[0x70fe9a4a10862ef0e69E1c78aE0579cc8aebDcB5] = true;
        isWhiteListed[0xa82975b47b6Acf6Db85C9ADaE2436FB7ED0d8D35] = true;
        isWhiteListed[0x5e177FaB565931636cC32C52f9543Fd05131166A] = true;
        isWhiteListed[0xe8285C02719914b49290C36404278604779D8b7f] = true;
        isWhiteListed[0x777480ff6351D131E4999c9Aaa2C1aFaBf0BE76d] = true;
        isWhiteListed[0x308eEa5B27EaD5f2111cF7c4e586cEec75083200] = true;
        isWhiteListed[0xd10751e125f7A0d195Db4a4afE6DCd8bC2Dbf7c5] = true;
        isWhiteListed[0x0Dde66F5759202c25A4676eF6F5A27D2e5DC93C4] = true;
        isWhiteListed[0x870B901DE303326e34214B54FF0aA5564B912739] = true;
        isWhiteListed[0xFE35e15bE885750D9b2363cbB6aBDd57AC9C4c40] = true;
        isWhiteListed[0xB9E7F01174024529474776D8c6ac64Afe2956f33] = true;
        isWhiteListed[0xc52A34cD5d352aAb3f662ff48CF2ccB9Cd407bBc] = true;
        isWhiteListed[0x3E27d0CEE58273fFF8053043963d0c49bf5DFeE7] = true;
        isWhiteListed[0x92a9a2db96C8128b2111705137d29F90755cbCBd] = true;
        isWhiteListed[0x0895b1093406e38b79c1785Fb3FCD98490D28DE2] = true;
        isWhiteListed[0x257c1f63DE91C638Fb8fb9875884Aebf2955dfd3] = true;
        isWhiteListed[0xbF13f81360AC29d8E3eC6Ffa1025423ab782345F] = true;
        isWhiteListed[0x53Dbb835A87030B4d868786dd8777eDfE4f7673E] = true;
        isWhiteListed[0xe291842F91Da71c183Ad2Ec170D648a69f407302] = true;
        isWhiteListed[0xd94dC3cA428c09aE95bC6b3ee7CC543230554958] = true;
    }

    //internal function for base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Presale mints
    function preSaleMint(uint _count) public payable whenNotPaused {
        uint totalMinted = _tokenIds.current();

        require(inPreSale, "Presale Ended");
        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count >0 && _count <= maxPerMint, "Cannot mint specified number of NFTs.");
        require(msg.value >= cost.mul(_count), "Not enough ether to purchase NFTs.");
        require(isWhiteListed[msg.sender], "Address is not whitelisted");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

        isWhiteListed[msg.sender] = false;
        
        (bool akoinSuccess, ) = payable(anftAddress).call{
            value: akoinShare
        }("");
        require(akoinSuccess);

        (bool madDawgsSuccess, ) = payable(madDawgsAddress).call{
            value: madDawgsShare
        }("");
        require(madDawgsSuccess);
    }

    //function allows you to mint an NFT token
    function mint(uint _count) public payable whenNotPaused {
        uint totalMinted = _tokenIds.current();

        require(!inPreSale, "Presale in progress");
        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count >0 && _count <= maxPerMint, "Cannot mint specified number of NFTs.");
        require(msg.value >= cost.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

        (bool akoinSuccess, ) = payable(anftAddress).call{
            value: akoinShare
        }("");
        require(akoinSuccess);

        (bool madDawgsSuccess, ) = payable(madDawgsAddress).call{
            value: madDawgsShare
        }("");
        require(madDawgsSuccess);
    }

    //actual minting 
    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    //reserve nfts
    function reserveNFTs(uint _count) public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) < maxSupply, "Not enough NFTs left to reserve");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    //function returns the owner
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //input a NFT token ID and get the IPFS URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function endPresale() public onlyOwner {
        inPreSale = false;
    }

    //set the cost of an NFT
    function setCost(uint _newCost) public onlyOwner {
        cost = _newCost;
    }

    //set the percentage of royalty
    function setRoyaltyPercentage(uint96 _royaltyPercentage) public onlyOwner {
        royaltyPercentage = _royaltyPercentage;
    }

    //set the not revealed URI on IPFS
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    //set the base URI on IPFS
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //configure royalties for Rariable
    function setRoyalties() public onlyOwner {
        _setDefaultRoyalty(royaltyReciver, royaltyPercentage);
    }

    
    function totalNTFSMinted() public view returns (uint) {
      return _tokenIds.current();
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Royalty, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
