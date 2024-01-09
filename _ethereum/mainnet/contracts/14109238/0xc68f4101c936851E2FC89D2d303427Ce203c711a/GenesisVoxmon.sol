//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

/**
*   @title Genesis Voxmon Contract
*/

/*
██╗   ██╗ ██████╗ ██╗  ██╗███╗   ███╗ ██████╗ ███╗   ██╗
██║   ██║██╔═══██╗╚██╗██╔╝████╗ ████║██╔═══██╗████╗  ██║
██║   ██║██║   ██║ ╚███╔╝ ██╔████╔██║██║   ██║██╔██╗ ██║
╚██╗ ██╔╝██║   ██║ ██╔██╗ ██║╚██╔╝██║██║   ██║██║╚██╗██║
 ╚████╔╝ ╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║╚██████╔╝██║ ╚████║
  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

// 
contract Genesis_Voxmon is ERC721, Ownable {
    using Counters for Counters.Counter;

    /*
    *   Global Data space
    */

    // This is live supply for clarity because our re-roll mechanism causes one token to be burned
    // and a new one to be generated. So some tokens may have a higher tokenId than 10,000
    uint16 public constant MAX_SUPPLY = 10000;
    Counters.Counter private _tokensMinted;

    // count the number of rerolls so we can add to tokensMinted and get new global metadata ID during reroll 
    Counters.Counter private _tokensRerolled;
    
    uint public constant MINT_COST = 70000000 gwei; // 0.07 ether 
    uint public constant REROLL_COST = 30000000 gwei; // 0.03 ether

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo public defaultRoyaltyInfo;

    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;
    

    // to avoid rarity sniping this will initially be a centralized domain
    // and later updated to IPFS
    string public __baseURI = "https://voxmon.io/token/";

    // this will let us differentiate that a token has been locked for 3D art visually
    string public __lockedBaseURI = "https://voxmon.io/locked/";

    // time delay for public minting
    // unix epoch time
    uint256 public startingTime;
    uint256 public artStartTime;

    mapping (uint256 => address) internal tokenIdToOwner;

    // As a reward to the early community, some members will get a number of free re-rolls 
    mapping (address => uint16) internal remainingRerolls; 

    // As a reward to the early community, some members will get free Voxmon
    mapping (address => uint16) internal remainingPreReleaseMints;

    // keep track of Voxmon which are currently undergoing transformation (staked)
    mapping (uint256 => bool) internal tokenIdToFrozenForArt;

    // since people can reroll their and we don't want to change the tokenId each time
    // we need a mapping to know what metadata to pull from the global set 
    mapping (uint256 => uint256) internal tokenIdToMetadataId;

    event artRequestedEvent(address indexed requestor, uint256 tokenId);
    event rerollEvent(address indexed requestor, uint256 tokenId, uint256 newMetadataId);
    event mintEvent(address indexed recipient, uint256 tokenId, uint256 metadataId);

    // replace these test addresses with real addresses before mint
    address[] votedWL = [
        0x12C209cFb63bcaEe0E31b76a345FB01E25026c2b,
        0x23b65a3239a08365C91f13D1ef7D339Ecd256b2F,
        0x306bA4E024B9C36b225e7eb12a26dd80A4b49e77,
        0x3Ec23503D26878F364aDD35651f81fe10450e33f,
        0x3d8c9E263C24De09C7868E1ABA151cAEe3E77219,
        0x4Ba73641d4FC515370A099D6346C295033553485,
        0x4DCA116cF962e497BecAe7d441687320b6c66118,
        0x50B0595CbA0A8a637E9C6c039b8327211721e686,
        0x5161581E963A9463AFd483AcCC710541d5bEe6D0,
        0x5A44e7863945A72c32C3C2288a955f4B5BE42F22,
        0x5CeDFAE9629fdD41AE7dD25ff64656165526262A,
        0x633e6a774F72AfBa0C06b4165EE8cbf18EA0FAe8,
        0x6bcD919c30e9FDf3e2b6bB62630e2075185C77C1,
        0x6ce3F8a0677D5F758977518f7873D60218C9d7Ef,
        0x7c4D0a5FC1AeA24d2Bd0285Dd37a352b6795b78B,
        0x82b332fdd56d480a33B4Da58D83d5E0E432f1032,
        0x83728593e7C362A995b4c51147afeCa5819bbdA1,
        0x85eCCd73B4603a960ee84c1ce5bba45e189d2612,
        0x87deEE357F9A188aEEbbd666AE11c15031A81cEc,
        0x8C8f71d182d2F92794Ea2fCbF357814d09D222C3,
        0x8e1ba6ABf60FB207A046B883B36797a9E8882F81,
        0x8fC4EC6Aff0D79aCffdC6430987fc299D34959a3,
        0x929D99600BB36DDE6385884b857C4B0F05AedE35,
        0x94f36E68b33F5542deA92a7cF66478255a769652,
        0x9680a866399A49e7E96ACdC3a4dfB8EF492eFE41,
        0xA71C24E271394989D61Ac13749683d926A6AB81d,
        0xB03BF3Ad1c850F815925767dF20c7e359cd3D033,
        0xBDF5678D32631BDC09E412F1c317786e7C6BE5f1,
        0xC23735de9dAC1116fb52745B48b8515Aa6955179,
        0xF6bD73C1bF387568e2097A813Aa1e833Ca8e7e8C,
        0xFC6dcAcA25362a7dD039932e151D21836b8CAB51,
        0xa83b5371a3562DD31Fa28f90daE7acF4453Ae126,
        0xaE416E324029AcB10367349234c13EDf44b0ddFD,
        0xc2A77cdEd0bE8366c0972552B2B9ED9036cb666E,
        0xcA7982f1A4d4439211221c3c4e2548298B3D7098,
        0xdACc8Ab430B1249F1caa672b412Ac60AfcbFDf66,
        0xe64B416c651A02f68566c7C2E38c19FaE820E105,
        0x7c4D0a5FC1AeA24d2Bd0285Dd37a352b6795b78B,
        0xBe18dECE562dC6Ec1ff5d7eda7FdA4f755964481
    ];

    address[] earlyDiscordWL = [
        0xfB28A0B0BA53Ccc3F9945af7d7645F6503199e73,
        0xFedeA86Ebec8DDE40a2ddD1d156350C62C6697E4,
        0x5d6fd8a0D36Bb7E746b19cffBC856724952D1E6e,
        0x15E7078D661CbdaC184B696AAC7F666D63490aF6,
        0xE4330Acd7bB7777440a9250C7Cf65045052a6640,
        0x6278E4FE0e4670eac88014D6326f079B4D02d73c,
        0xFAd6EACaf5e3b8eC9E21397AA3b13aDaa138Cc80,
        0x5586d438BE5920143c0f9B179835778fa81a544a,
        0xcA7982f1A4d4439211221c3c4e2548298B3D7098,
        0xdACc8Ab430B1249F1caa672b412Ac60AfcbFDf66,
        0x82b332fdd56d480a33B4Da58D83d5E0E432f1032,
        0x6bcD919c30e9FDf3e2b6bB62630e2075185C77C1,
        0x4DCA116cF962e497BecAe7d441687320b6c66118,
        0xaE416E324029AcB10367349234c13EDf44b0ddFD,
        0xc2A77cdEd0bE8366c0972552B2B9ED9036cb666E,
        0x23b65a3239a08365C91f13D1ef7D339Ecd256b2F,
        0xE6E63B3225a3D4B2B6c13F0591DE9452C23242B8,
        0xE90D7E0843410A0c4Ff24112D20e7883BF02839b,
        0x9680a866399A49e7E96ACdC3a4dfB8EF492eFE41,
        0xe64B416c651A02f68566c7C2E38c19FaE820E105,
        0x83728593e7C362A995b4c51147afeCa5819bbdA1,
        0x7b80B01E4a2b939E1E6AE0D51212b13062352Faa,
        0x50B0595CbA0A8a637E9C6c039b8327211721e686,
        0x31c979544BAfC22AFCe127FD708CD52838CFEB58,
        0xE6ff1989f68b6Fd95b3B9f966d32c9E7d96e6255,
        0x72C575aFa7878Bc25A3548E5dC9D1758DB74FD54,
        0x5C95a4c6f66964DF324Cc95418f8cC9eD6D25D7c,
        0xc96039D0f01724e9C98245ca4B65B235788Ca916,
        0x44a3CCddccae339D05200a8f4347F83A58847E52,
        0x6e65772Af2F0815b4676483f862e7C116feA195E,
        0x4eee5183e2E4b670A7b5851F04255BfD8a4dB230,
        0xa950319939098C67176FFEbE9F989aEF11a82DF4,
        0x71A0496F59C0e2Bb91E48BEDD97dC233Fe76319F,
        0x1B0767772dc52C0d4E031fF0e177cE9d32D25aDB,
        0xa9f15D180FA3A8bFD15fbe4D5C956e005AF13D90
    ];

    address[] foundingMemberWL = [
        0x4f4EE78b653f0cd2df05a1Fb9c6c2cB2B632d7AA,
        0x5CeDFAE9629fdD41AE7dD25ff64656165526262A,
        0x0b83B35F90F46d3435D492D7189e179839743770,
        0xF6bD73C1bF387568e2097A813Aa1e833Ca8e7e8C,
        0x5A44e7863945A72c32C3C2288a955f4B5BE42F22,
        0x3d8c9E263C24De09C7868E1ABA151cAEe3E77219,
        0x7c4D0a5FC1AeA24d2Bd0285Dd37a352b6795b78B,
        0xBe18dECE562dC6Ec1ff5d7eda7FdA4f755964481,
        0x2f8c1346082Edcaf1f3B9310560B3D38CA225be8
    ];

    constructor(address payable addr) ERC721("Genesis Voxmon", "VOXMN") {
        // setup freebies for people who voted on site
        for(uint i = 0; i < votedWL.length; i++) {
            remainingRerolls[votedWL[i]] = 10;
        }

        // setup freebies for people who were active in discord
        for(uint i = 0; i < earlyDiscordWL.length; i++) {
            remainingRerolls[earlyDiscordWL[i]] = 10;
            remainingPreReleaseMints[earlyDiscordWL[i]] = 1;
        }

        // setup freebies for people who were founding members
        for(uint i = 0; i < foundingMemberWL.length; i++) {
            remainingRerolls[foundingMemberWL[i]] = 25;
            remainingPreReleaseMints[foundingMemberWL[i]] = 5;
        }


        // setup starting blocknumber (mint date) 
        // Friday Feb 4th 6pm pst 
        startingTime = 1644177600;
        artStartTime = 1649228400;

        // setup royalty address
        defaultRoyaltyInfo = RoyaltyInfo(addr, 1000);
    }
    
    /*
    *   Priviledged functions
    */

    // update the baseURI of all tokens
    // initially to prevent rarity sniping all tokens metadata will come from a cnetralized domain
    // and we'll upddate this to IPFS once the mint finishes
    function setBaseURI(string calldata uri) external onlyOwner {
        __baseURI = uri;
    }

    // upcate the locked baseURI just like the other one
    function setLockedBaseURI(string calldata uri) external onlyOwner {
        __lockedBaseURI = uri;
    }

    // allow us to change the mint date for testing and incase of error 
    function setStartingTime(uint256 newStartTime) external onlyOwner {       
        startingTime = newStartTime;
    }

    // allow us to change the mint date for testing and incase of error 
    function setArtStartingTime(uint256 newArtStartTime) external onlyOwner {       
        artStartTime = newArtStartTime;
    }

    // Withdraw funds in contract
    function withdraw(uint _amount) external onlyOwner {
        // for security, can only be sent to owner (or should we allow anyone to withdraw?)
        address payable receiver = payable(owner());
        receiver.transfer(_amount);
    }

    // value / 10000 (basis points)
    function updateDefaultRoyalty(address newAddr, uint96 newPerc) external onlyOwner {
        defaultRoyaltyInfo.receiver = newAddr;
        defaultRoyaltyInfo.royaltyFraction = newPerc;
    }

    function updateRoyaltyInfoForToken(uint256 _tokenId, address _receiver, uint96 _amountBasis) external onlyOwner {
        require(_amountBasis <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(_receiver != address(0), "ERC2981: invalid parameters");

        _tokenRoyaltyInfo[_tokenId] = RoyaltyInfo(_receiver, _amountBasis);
    }

    /*
    *   Helper Functions
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function _lockedBaseURI() internal view returns (string memory) {
        return __lockedBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }

    // see if minting is still possible
    function _isTokenAvailable() internal view returns (bool) {
        return _tokensMinted.current() < MAX_SUPPLY;
    }

    // used for royalty fraction
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    } 

    /*
    *   Public View Function
    */
    
    // concatenate the baseURI with the tokenId
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "token does not exist");

        if (tokenIdToFrozenForArt[tokenId]) {
            string memory lockedBaseURI = _lockedBaseURI();
            return bytes(lockedBaseURI).length > 0 ? string(abi.encodePacked(lockedBaseURI, Strings.toString(tokenIdToMetadataId[tokenId]))) : "";
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenIdToMetadataId[tokenId]))) : "";
    }

    function getTotalMinted() external view returns (uint256) {
        return _tokensMinted.current();
    }

    function getTotalRerolls() external view returns (uint256) {
        return _tokensRerolled.current();
    }

    // tokenURIs increment with both mints and rerolls
    // we use this function in our backend api to avoid trait sniping
    function getTotalTokenURIs() external view returns (uint256) {
        return _tokensRerolled.current() + _tokensMinted.current();
    }

    function tokenHasRequested3DArt(uint256 tokenId) external view returns (bool) {
        return tokenIdToFrozenForArt[tokenId];
    }

    function getRemainingRerollsForAddress(address addr) external view returns (uint16) {
        return remainingRerolls[addr];
    }

    function getRemainingPreReleaseMintsForAddress(address addr) external view returns (uint16) {
        return remainingPreReleaseMints[addr];
    }

    function getMetadataIdForTokenId(uint256 tokenId) external view returns (uint256) {
        return tokenIdToMetadataId[tokenId];
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
            RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

            if (royalty.receiver == address(0)) {
                royalty = defaultRoyaltyInfo;
            }

            uint256 _royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();
            return (royalty.receiver, _royaltyAmount);
    }

    /*
    *   Public Functions
    */

    // Used to request a 3D body for your voxmon
    // Freezes transfers re-rolling a voxmon
    function request3DArt(uint256 tokenId) external {
        require(block.timestamp >= artStartTime, "you cannot freeze your Voxmon yet");
        require(ownerOf(tokenId) == msg.sender, "you must own this token to request Art");
        require(tokenIdToFrozenForArt[tokenId] == false, "art has already been requested for that Voxmon");
        tokenIdToFrozenForArt[tokenId] = true;

        emit artRequestedEvent(msg.sender, tokenId);
    }

    /*
    *   Payable Functions 
    */  
    
    // Mint a Voxmon
    // Cost is 0.07 ether
    function mint(address recipient) payable public returns (uint256) {
        require(_isTokenAvailable(), "max live supply reached, to get a new Voxmon you\'ll need to reroll an old one");
        require(msg.value >= MINT_COST, "not enough ether, minting costs 0.07 ether");
        require(block.timestamp >= startingTime, "public mint hasn\'t started yet");

        _tokensMinted.increment();
        
        uint256 newTokenId = _tokensMinted.current();
        uint256 metadataId = _tokensMinted.current() + _tokensRerolled.current();
        
        _mint(recipient, newTokenId);
        tokenIdToMetadataId[newTokenId] = metadataId;

        emit mintEvent(recipient, newTokenId, metadataId);

        return newTokenId;
    }

    // Mint multiple Voxmon
    // Cost is 0.07 ether per Voxmon
    function mint(address recipient, uint256 numberToMint) payable public returns (uint256[] memory) {
        require(numberToMint > 0);
        require(numberToMint <= 10, "max 10 voxmons per transaction");
        require(msg.value >= MINT_COST * numberToMint);

        uint256[] memory tokenIdsMinted = new uint256[](numberToMint);

        for(uint i = 0; i < numberToMint; i++) {
            tokenIdsMinted[i] = mint(recipient);
        }

        return tokenIdsMinted;
    }

    // Mint a free Voxmon
    function preReleaseMint(address recipient) public returns (uint256) {
        require(remainingPreReleaseMints[msg.sender] > 0, "you have 0 remaining pre-release mints");
        remainingPreReleaseMints[msg.sender] = remainingPreReleaseMints[msg.sender] - 1;

        require(_isTokenAvailable(), "max live supply reached, to get a new Voxmon you\'ll need to reroll an old one");

        _tokensMinted.increment();
        
        uint256 newTokenId = _tokensMinted.current();
        uint256 metadataId = _tokensMinted.current() + _tokensRerolled.current();
        
        _mint(recipient, newTokenId);
        tokenIdToMetadataId[newTokenId] = metadataId;

        emit mintEvent(recipient, newTokenId, metadataId);

        return newTokenId;
    }

    // Mint multiple free Voxmon
    function preReleaseMint(address recipient, uint256 numberToMint) public returns (uint256[] memory) {
        require(remainingPreReleaseMints[msg.sender] >= numberToMint, "You don\'t have enough remaining pre-release mints");

        uint256[] memory tokenIdsMinted = new uint256[](numberToMint);

        for(uint i = 0; i < numberToMint; i++) {
            tokenIdsMinted[i] = preReleaseMint(recipient);
        }

        return tokenIdsMinted;
    }

    // Re-Roll a Voxmon
    // Cost is 0.01 ether 
    function reroll(uint256 tokenId) payable public returns (uint256) {
        require(ownerOf(tokenId) == msg.sender, "you must own this token to reroll");
        require(msg.value >= REROLL_COST, "not enough ether, rerolling costs 0.03 ether");
        require(tokenIdToFrozenForArt[tokenId] == false, "this token is frozen");
        
        _tokensRerolled.increment();
        uint256 newMetadataId = _tokensMinted.current() + _tokensRerolled.current();

        tokenIdToMetadataId[tokenId] = newMetadataId;
        
        emit rerollEvent(msg.sender, tokenId, newMetadataId);

        return newMetadataId;
    }

    // Re-Roll a Voxmon
    // Cost is 0.01 ether 
    function freeReroll(uint256 tokenId) public returns (uint256) {
        require(remainingRerolls[msg.sender] > 0, "you have 0 remaining free rerolls");
        remainingRerolls[msg.sender] = remainingRerolls[msg.sender] - 1;

        require(ownerOf(tokenId) == msg.sender, "you must own the token to reroll");
        require(tokenIdToFrozenForArt[tokenId] == false, "this token is frozen");
        
        _tokensRerolled.increment();
        uint256 newMetadataId = _tokensMinted.current() + _tokensRerolled.current();

        tokenIdToMetadataId[tokenId] = newMetadataId;
        
        emit rerollEvent(msg.sender, tokenId, newMetadataId);

        return newMetadataId;
    }
}