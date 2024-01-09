// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                                                                                                                                    
//                   .-----:-`         :////++/. :+oooooossssssssyysoyyyyhhhhhhdhddddddmh/`   omNNNNNNNNs.                                           
//                  sNNNNNNNMm+`     `hNNMMMMMMNdMMMMMMMMMMMMMMNNNMMMMNmmmmmmmmddddddddMMMm/`oMMNhyyyymMMNs.                                         
//                  NMMy+++oNMMm+   .dMMh::--mMMMMMy......```````:MMMM+```````````````-MMMMMmMMN-     .mMMMN.                                        
//                  mMM+    :mMMMy`-mMMy`    mMMMMMy    .::://///oMMMMy/////`    /+ooosMMMMMMMM/       -NMMMm.                                       
//                  dMM+     .dMMMdNMMs      dMMMMMy    sMMMMMMMMMMMMMMMMMMM:    mMMMMMMMMMMMMs   /mo   :NMMMd`                                      
//                  dMMo      `sMMMMM+       hMMMMMh    /hhhhhhhdMMMMMMMMMMM:    mMMMMMMMMMMMh   .NMM/   /NMMMd`                                     
//                  hMMs    `   +NMN/  .-    hMMMMMd     ````   -MMMMMmsyMMM/    mMMMMMsoNMMm`   dMMMN-   /MMMMh`                                    
//                  hMMs   .my`  :y:  :mN`   yMMMMMd    :hhhhddddMMMMMd  mMM/    dMMMMM.+MMN.    +oo++.    +MMMMy                                    
//                  yMMy   .MMm-     /NMM.   sMMMMMm    +MMMMMMMMMMMMMd  mMM+    hMMMMMoNMM:   `........    oMMMMs                ``....`            
//                  yMMy   .MMMN+   +NMMM-   sMMMMMm    .oooo+++++hMMMMy`dMMo    hMMMMMMMM+   `dmmmmNNNNs    sMMMMo```        ./sdmmmmmmmmho-        
//                  sMMh   `MMMMMyoyMMMMM-   oMMMMMN   ```````````sMMMMM/dMMs..--hMMMMMMMd:--:yMMMMMMMMMMoosyhMMMMNmmmdy+-  -hNMdyo+/::/+hMMNy:      
//                  sMMmssssMMMMMMMMMMMMMdhhdmMMMMMMddddddmmmmmmmmNMMMMM+yMMNNNNNMMMMMMMMMNNNNMMMMMMMNNMMMMNhhyysoo++oydNNh+NMd:` `-:::-.dMMMMN      
//                  -dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs.+mMMMMMMNNmNMMMMNysso+//:---+MMMMm    `.--.  `-dMMMM.   dNMMMNNMMMMMo      
//                   `+dMMMMMMMMMm/o+++//mMMMMMMMMMMMMMMMMMMMMNNNMMmddhNMdo-+dMMMy-..sMMMMN    --://+oyMMMMM`   dNNNms   .MMMM-   :osyyhdmMMMN`      
//                     `:++shNMMMNdddyo:.`-:::sNMMmhs+//+ohmMMmooMM+`  /mMMm:/MMh`   :MMMMM.   mMMMMMMMMMMMM-   hMMMMm   `NMMMmo:-..``  `./mMMd/     
// `-://+ossyhhhhys/.    :ymMmdyooooydmMmy-``yMNy:` `...`  `:hMMmMMs    .yNMMNMd`    .MMMMM/   /o++/::hMMMMM+   :yss+.  .sMMMMMMMNmmmdh:   +MMMM/    
// yMMmmmmddhhyyyhmMNy:.yMMh/.  `..`  ./dMMhdMN/   /hmNNmy.   oMMMMd      /mMMd` ``   NMMMMo   `-://+odMMMMMy    ...   -mMMMMMMmydmmmmh/  `yMMMMd    
// hMM-.```....`  `/MMMmMN/   :hmmmdo`  `sMMMMo   /MMMMMMMm`   dMMMN   `+. .yd. -my   hMMMMh   :MMMMMMMMMMMMm   `mNm+`  :dMMMMM/` ``````-+dMMMMMy    
// oMM-   ymNNNd`  `mMMMMo   /MMMMMMMd`   dMMM:   sMMMMmdMM-   yMMMM-  -Mm/    .mMN   oMMMMN   `ssoo+//:mMMMM` ``NMMMd:--/dMMMMmdhhyhhdmMMMMMMMh`    
// /MM+   smmmds` -hMMMMM:   sMMMMNdMM-   yMMMs   .mMMMmNMd`  `NMMMM/  `MMMy.`.dMMM.  :MMMMM.```....-://dMMMMhhhdNMMMMMMMMMMMMMMMMMMMMMMMMMMNh/`     
// .MMy   `-....` -odMMMMo   -NMMMmNMd`  `mMMMMo`  .+hddy/`  -dMMMMMs   mMMMmhmMMMMs++sMMMMMddmmNNMMMMMMMMMMMMMMMMMMMMhmNNNNNNmd++syyhhyys+:.        
//  NMm   .dmNNNm/   oMMMN/`  .sdmmh+`  .hMMMMMMd+.``   ``./yNMMMMMMmyyhNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNmdohhyysoo/ `::--.``                      
//  hMM`   NNNNNd:   +MMMMMh/``     ``-sNMMMMMysmMMmhyyyhdNMMMMMMNsdMMMMMMMMMhyyso+yNNNNNmds:syso++/::--..``                                         
//  oMM-   .-..```.:yNMMMMNNMNdysssydNMMMMMMNs` `/hNMMMMMMMMMMNdo.  :ymdhhys+`      `.``                                                             
//  :MMy+osyyhhdmNMMMMMMMN:.+mNMMMMMMMMMMNms.      .:+syyyyso/.                                                                                      
//  `hNMMMMMMMMMMMMMMMNms.    -/syhddhys/-                                                                                                           
//    -sNNNNmdhhysso/:.                                                                                                                              
//       `                                                                                                                                           

/// @creator:         Meta Boomers
/// @author:          peker.eth - twitter.com/peker_eth

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./YieldingBoomer.sol";

contract MetaBoomers is YieldingBoomer {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    bytes32 public root;
    
    address proxyRegistryAddress;

    string BASE_URI = "https://api.metaboomersnft.com/metadata/";
    
    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;
    
    uint constant TOTAL_SUPPLY = 8888;
    uint constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;
    uint constant PRESALE_MINT_PRICE = 0.020 ether; 
    uint constant MINT_PRICE = 0.045 ether; 

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 10;
    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;
    
    mapping (address => uint) addressToMintCount;
    mapping (address => bool) isTeamMember;
    
    address COMMUNITY_WALLET = 0xb07996B2dAB2E70D867EEA20F6b80F2Eb9DA15aD;
    address TEAM_1 = 0x936152245B8e47cCde665C228868F403a45c035b;
    address TEAM_2 = 0xA800F34505e8b340cf3Ab8793cB40Bf09042B28F;
    address TEAM_3 = 0xCF06446c0372Bf1BB771d0E9AD9c16fD0d3cdD7B;
    address TEAM_4 = 0xbDf3EA86444E2C19fc170D89438eE02868F85706;
    address TEAM_5 = 0x808FD8816c71AeD45071dfce57e2929af507f033;
    address TEAM_6 = 0xBDE8236C535B86be55F8a3c0af862d316Ce0A6FC;
    address TEAM_7 = 0x0eD45B6e251d59c7f5A0aa162238D73E96cc61f6;
    address TEAM_8 = 0xd536cDDf1aDEB9d805efe265A1278302BAA1e988;
    address TEAM_9 = 0x433AA2913eFc08042899aB9b6fCFC7B7E901Fa8a;
    address TEAM_10 = 0xa80f0bA14407Ae078B7dE5cbEBcd2367a5e1576E;
    address TEAM_11 = 0x2a92e1d6614c3e6817E7E9bfA004525814118a82;
    address TEAM_12 = 0x0F0Fb9aFD70CfF14C9e5E443f11b4f5585297c0D;

    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
        _tokenIdCounter.increment();

        isTeamMember[TEAM_1] = true;
        isTeamMember[TEAM_2] = true;
        isTeamMember[TEAM_3] = true;
        isTeamMember[TEAM_4] = true;
        isTeamMember[TEAM_5] = true;
        isTeamMember[TEAM_6] = true;
        isTeamMember[TEAM_7] = true;
        isTeamMember[TEAM_8] = true;
        isTeamMember[TEAM_9] = true;
        isTeamMember[TEAM_10] = true;
        isTeamMember[TEAM_11] = true;
        isTeamMember[TEAM_12] = true;
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function togglePublicSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function togglePreSale() public 
    onlyOwner 
    {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier onlyTeam () {
        require(isTeamMember[msg.sender] == true, "Caller must be a team member");
        _;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function teamMint(uint numberOfTokens) 
    public 
    onlyTeam {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        require(addressToMintCount[msg.sender] + numberOfTokens <= 25, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function presaleMint(address account, uint numberOfTokens, uint256 allowance, string memory key, bytes32[] calldata proof)
    public
    payable
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        require(msg.value >= numberOfTokens * PRESALE_MINT_PRICE, "Not enough ethers sent");

        string memory payload = string(abi.encodePacked(Strings.toString(allowance), ":", key));

        require(_verify(_leaf(msg.sender, payload), proof), "Invalid merkle proof");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= allowance, "Exceeds allowance");

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint numberOfTokens) 
    public 
    payable
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX, "Too many requested");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function getCurrentMintCount(address _account) public view returns (uint) {
        return addressToMintCount[_account];
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        yieldToken.updateRewardOnMint(msg.sender, 1);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(COMMUNITY_WALLET, (balance * 240) / 1000);
        _withdraw(TEAM_1, (balance * 250) / 1000);
        _withdraw(TEAM_2, (balance * 130) / 1000);
        _withdraw(TEAM_3, (balance * 80) / 1000);
        _withdraw(TEAM_4, (balance * 75) / 1000);
        _withdraw(TEAM_5, (balance * 55) / 1000);
        _withdraw(TEAM_6, (balance * 35) / 1000);
        _withdraw(TEAM_7, (balance * 35) / 1000);
        _withdraw(TEAM_8, (balance * 30) / 1000);
        _withdraw(TEAM_9, (balance * 30) / 1000);
        _withdraw(TEAM_10, (balance * 15) / 1000);
        _withdraw(TEAM_11, (balance * 10) / 1000);
        _withdraw(TEAM_12, (balance * 15) / 1000);
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    function _leaf(address account, string memory payload)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}