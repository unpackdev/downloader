// SPDX-License-Identifier: MIT
/*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
            .. ..........................................................................           
                                                                                                    
              .                                                                       .             
   ..         .............................                ............................         ..  
              ..    ....  ....  ......                         ....... ....   ...    ..             
     ..                         ..                                 ..                         ..    
      .. .                               ...              ..                               .. .     
 .  . .  .               .           ..          .Y555557     ...          .               .  . .  .
 .  . .  .                        ..           .YGPGBGGJYG!.     ...                       .  . .  .
 .  . .  .            .        .             ^?#P5PP555PY~G#.        .         .           .  . .  .
 .  . .  .           .       .              .&#PGG7^   ~JGJ!           .       .           .  . .  .
 .  . .  .           .     ..               .##BPP5?... .~.             ..     .           .. . .  .
 .  . .  .           .     ..                 ^GGG5PBGG~.               ..     .           .. . .  .
 .  . .  .           .     ..              ^7777#&YJY?7JJ77777?.        ..     .           .  . .  .
 .  . .  .           .     ..         7YYYY5P##BBGYY55Y!75555Y?JYY~     ..     .           .. . .  .
 .  . .  .           .      .     :PGB5YBBG5Y555555555YYYYYYYJJ!~~?PP5:. .     .           .. . .  .
 .  . .  .           . :~~~!.  .~YGY5G5555YYYJJJJJJJJ77~7J55555YJY7^~!YJ!. ^~~..           .  . .  .
 .  . .  .           :JG##B#5??JBP5PPPPPYJJJJJJJJJJJJJJ777JYYYYJJJJJYY~7JJJBGJJJ           .  . .  .
 .  . .  .         .YPBP5JJJG#&#GBPPGBBBGJJJJJYPPPPPPYJJJJ77JJJJJPPPPPGJ.G&PY~!75!         .  . .  .
 .  . .  .         .&#5J?^^^JP##BG5GGGGB#YY5PPY~^::::JPYYJ???JYPP^:::::~5^^#B!..&5         .. . .  .
 .  . ....         :&#5~:^::~!#BGBPGGBBGB5Y!^^^:::::^::?YPYJP5Y!^^^^::^::..&#~~~&P         .... .  .
 .  . ..           .&#5~:^^^~!&P^?PBBP?77~....      ... .!~~!~......  ... .JJ~JP&5            . .  .
 .  .  ........... :&#Y!^~~~~!&5   7!        :~~~~~~~            .~~~~~~~:   ~YP#Y ............ .  .
 .  . ..           .PPYPP?77PBBY:::::::.    ?77!7?77!?!         ~?~!!~!!??? .P#&:            .. .  .
 .  . .............. !@PYY5G&&7JBP5YYJP.   .57~!!!~~!Y7   ...   7J^^^~!77?Y :@PJ. ............. .  .
 .  . .              .~5BGB#PY55P55JYG?:.   J?7!!!777J! ..7Y7^. !?~!7?????J  !J5.             . .  .
 .  . .              . ...!&Y!PG5YYG5~^^:.   ^7777777.  :^?PGP^  .!!!!!!7^    P&.             . .  .
 .  . .              .    :@Y!PG5JJB5:^^^^........::~..::::^&G::. .~.......~^ P&.             . .  .
 .  . .              .    .75GYYP55B5:^^^^^^^^^^^^:7&G55555P&#555P5Y!^^^^~~:~5?7              . .  .
 .  . .              .      P&?JG55B5^^:^^^^^^^^^^^7&Y777777777777~::^^^^~~.~&~               . .  .
 .  . .     :YBGGGGP5J^     ..Y55YYY5B?~^^^^^^^^^^PY~^:::::::::::::^::^^~~!5?...              . .  .
 .  . .   ~?#GPGGBGP~757~      .JB&GB###YYYYJ^^^^^^^^^^^^^^^^^^^^^!Y?77?55J    .              .    .
      . ~5#BP##!~~~7#G75G57 .  .JY5Y5GBB####BGGGGGGGGGGGGGGGGGGGGGGBBB&5 .     .              .     
.       5&GB&!.     .?&5J&G   5PJ55PPP555555PGGGGGGGGGGGGGGGGGGGGP5Y5Y~75~.    .           ..     . 
        Y&PG&:    .^:?&P5&G ::BG75G5555YYYYYYYYYPGGGGGGGGGGGGGG5Y7!~7??7^YP^.  .                    
        Y&7J#5? :JGBBGPGG?~ P&7JGP555YJJJJJJJ?YBYJJJJJJJJJJJJJJPGJ?777JJJ:.&G            .          
        .~BBP&&..^YBBBB7: .5YY55P55YJJJJJJJY5BGY~^77^^^^^^^^?!:!7GPYJJ77J7!!75.                     
          BGY5PB?..  ..   :@Y!PG555JJJJJ55PBB7!~^^~~^^^^^^^^~~^^^:7BG5JJJJ?.^@^                     
           :YG#PGB?~~:    :&Y7PP555JJJJY5G&Y!J7^^^::^^^^^:~~^:^^^?!.5&PYJJ?.~&^                     
             ^7BBPB#BGJ.  :&Y7PP555JJJ555G&Y!J7:^^^^^^^^^^^^^^^^^?~ 5&PYJJ?.~&~                     
               .?&&#PG#BP :&Y7PP555JJJY55G&Y~!~^^^^^^^^^^^^^^^^^^::.5&PYJJ?.~&^                     
*/

pragma solidity ^0.8.12;
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./IBananaToken.sol";

contract TempleExploration is ReentrancyGuard {
    function explore(uint256 _bananaQuantity) external nonReentrant {} 

    function worship(uint256 _tokenId, uint256 _bananaQuantity) external {}

    function gearUp(uint256 _bananaQuantity) external nonReentrant {}

    function expeditionLevel(address _address) public pure returns (uint256) {}
}

contract SpacecraftFactory is ReentrancyGuard {
    function chargeSpacecraft(uint256 _bananaToken) external nonReentrant{}
}

contract OhoohAhaah is Ownable, ERC721A {
    using Strings for uint256;
    
    TempleExploration templeAddress;
    SpacecraftFactory spacecraftAddress;
    address public bananaToken = address(0);

    enum AdventurePhase {
        LANDING,
        BANANA_HARVEST,
        TEMPLE_EXPLORATION,
        SPACE_TRAVEL
    }

    enum MintStage {
        NONE,
        WHITELISTSALE,
        PUBLICSALE,
        SOLDOUT,
        REVEAL
    }

    MintStage public mintState;

    AdventurePhase public monkeAdventurePhase;

    string public monkeVoyagerBase;
    string public notRevealURI;

    uint256 public constant MAX_SUPPLY = 6666; 
    uint256 public constant MAX_WHITELIST = 2222; 
    uint256 public constant WL_SALES_PRICE = 0 ether;
    uint256 public constant MAX_TEAM_RESERVE = 88;

    uint256 public constant MAX_PER_WL = 2;
    uint256 public constant MAX_PER_WALLET = 5;


    uint256 public  MAX_PER_TXN = 5;
    uint256 public  PUBLIC_SALES_PRICE = 0.0088 ether;


    address public teamAddress;
    bytes32 public whitelistMerkleRoot;
    bytes32 public allowlistMerkleRoot;

    mapping(address => uint256) public wlMintClaimed;
 

    constructor(
        address _team,
        bytes32 _whitelistMerkleRoot,
        bytes32 _allowlistMerkleRoot,
        string memory _monkeVoyagerBase,
        string memory _notRevealURI
    ) ERC721A("Monke Voyager", "MonkeVoyager") {
        teamAddress = _team;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        allowlistMerkleRoot = _allowlistMerkleRoot;
        monkeVoyagerBase = _monkeVoyagerBase;
        notRevealURI = _notRevealURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract. Oh ooh gotcha ah Aah.");
        _;
    }

    modifier atState(MintStage state) {
        require(mintState == state, "Not your turn Monke. Hold tight!");
        _;
    }

    modifier validateWLAddress(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "You are not a whitelisted Monke"
        );
        _;
    }

    modifier validateALAddress(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "You are not a allowlisted Monke"
        );
        _;
    }

    modifier validateSupply(uint256 _maxSupply, uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= _maxSupply,
            "The current stage has all its Monke Voyagers out!"
        );
        _;
    }

    modifier validateMintPerWallet(uint256 _quantity) {
        require(_quantity <= MAX_PER_TXN, "Too many Monkes in one transaction!");
        require(_numberMinted(msg.sender) - wlMintClaimed[msg.sender] + _quantity <= MAX_PER_WALLET, "You are recuiting too many Monke Voyagers my friend");
        _;
    }

    modifier validateWLStatus(uint256 _quantity) {
        require(wlMintClaimed[msg.sender] + _quantity <= MAX_PER_WL, "Ah aah, no more WL Monkes for u");
        require(_numberMinted(msg.sender) - wlMintClaimed[msg.sender] + _quantity <= MAX_PER_WALLET, "You are recuiting too many Monke Voyagers my friend");
        _;
    }

    modifier atPhase(AdventurePhase phase) {
        require(monkeAdventurePhase == phase, "Galaxy map not initialize. Hold tight for the next chapter!");
        _;
    }

    /*==============================================================
    ==          Functions for LANDING (Minting) Phase             ==
    ==============================================================*/

    /**

    /**
     * @notice Welcome to the world of Monke Voyager, Whitelist holders. 1WL = 2 Monkes. Enjoy the ride!
     */
    function WLMonkeLanding(uint256 _quantity, bytes32[] calldata _proof)
        external
        callerIsUser
        atState(MintStage.WHITELISTSALE)
        validateWLStatus(_quantity)
        validateSupply(MAX_WHITELIST, _quantity)
        validateWLAddress(_proof, whitelistMerkleRoot)
     
    {
        wlMintClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Welcome to the world of Monke Voyager, Allowlist holders. 1WL = 1 Monke. Enjoy the ride!
     */
    function ALMonkeLanding(bytes32[] calldata _proof)
        external
        callerIsUser
        atState(MintStage.WHITELISTSALE)
        validateSupply(MAX_WHITELIST, 1)
        validateALAddress(_proof, allowlistMerkleRoot)
     
    {
        wlMintClaimed[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice Welcome to the world of Monke Voyager! Oh Ooh Ah Aah Aaah!
     */
    function AllMonkeLanding(uint256 _quantity)
        external
        payable
        callerIsUser
        atState(MintStage.PUBLICSALE)
        validateSupply(MAX_SUPPLY, _quantity)
        validateMintPerWallet(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }
    /**
     * @notice Crew members will also ride with ya, Monkes! Oh Ooh Ah Aah Aaah!
     */
    function CrewMonkeLanding() 
        external 
        payable 
        validateSupply(MAX_SUPPLY, MAX_TEAM_RESERVE)
        onlyOwner 
    {
        _safeMint(teamAddress, MAX_TEAM_RESERVE);
    }


    /*=====================================================================
    ==              Functions for BANANA HARVEST Phase                   ==
    =====================================================================*/
    function InitBananaHarvest(address _bananaTokenAddress) 
    external 
    onlyOwner {
        monkeAdventurePhase = AdventurePhase.BANANA_HARVEST;
        bananaToken = _bananaTokenAddress;
    }

    /**
     * @dev override to add/remove banana harvest on transfers/burns
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 _quantity
    ) internal override {
        /**  @dev Always set Banana Token Address first,
         *   Otherwise mint will fail
        */
        if (from != address(0)) {
            IBananaToken(bananaToken).stopHarvest(from, _quantity);
        }

        if (to != address(0)) {
            IBananaToken(bananaToken).startHarvest(to, _quantity);
        }
        
        super._beforeTokenTransfers(from, to, tokenId, _quantity);
    }


    /*=====================================================================
    ==              Functions for TEMPLE_EXPLORATION Phase               ==
    =====================================================================*/
    
    /// @notice Temple Exploration is about to begin! Oh Ooh Ah Aah Aaah!
    function InitTempleExploration(address _templeAddress) 
    external 
    onlyOwner {
        monkeAdventurePhase = AdventurePhase.TEMPLE_EXPLORATION;
        templeAddress = TempleExploration(_templeAddress);
    }

    /// @notice Yas, Explore, yaaas! Oh Ooh Ah Aah Aaah!
    function templeExplore(uint256 _bananaQuantity) external {
        templeAddress.explore(_bananaQuantity);
    }

    function relicWorship(uint256 _tokenId, uint256 _bananaQuantity) external {
        templeAddress.worship(_tokenId, _bananaQuantity);
    }

    function expeditionLevel(address _address) public view returns (uint256) {
       return templeAddress.expeditionLevel(_address);
    }

    /// @notice Trade relic fragments for gears
    function gearUp(uint256 _bananaQuantity) external {
        templeAddress.gearUp(_bananaQuantity);
    } 

    function ChargeSpacecraft(uint256 _bananaToken) external {
        spacecraftAddress.chargeSpacecraft(_bananaToken);
    }


    /*=====================================================================
    ==                        Generic Control Functions                  ==
    =====================================================================*/
    
    /**
     * @notice new chapters! Oh Ooh Ah Aah Aaah!
     */
    function setAdventurePhase(uint256 _phase) external onlyOwner {
        monkeAdventurePhase = AdventurePhase(_phase);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function setTeamAddress(address _team) external onlyOwner {
        teamAddress = _team;
    }

    function setMonkeVoyagerBase(string memory _monkeVoyagerBase) external onlyOwner {
        monkeVoyagerBase = _monkeVoyagerBase;
    }

    function setMintStage(uint256 _step) external onlyOwner {
        mintState = MintStage(_step);
    }

    function setNotRevealURI(string memory _uri) external onlyOwner {
        notRevealURI = _uri;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }
    /**
     * @dev override IERC721Metadata
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {

         require(_exists(_tokenId), "URI query for unclaimed Monke Voyager");

        if (mintState != MintStage.REVEAL) {
            return string(notRevealURI);
        }
        return string(abi.encodePacked(monkeVoyagerBase, _tokenId.toString(), ".json"));
    }

}