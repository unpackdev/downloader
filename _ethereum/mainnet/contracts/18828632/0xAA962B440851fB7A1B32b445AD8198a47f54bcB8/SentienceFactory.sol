// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.#.#.#,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*###*%##*#.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   % .#,#(# *%   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%*#%%/#%%,%%#,%#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ .#..%,# *%,.#*%  #  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#####*%%###,%%%#(#%%/##@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%.#.(##/.%#,*#./%*.##%,.#.&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%/%%,#%%%/*##%%%,%%%##.%%,%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,.%#  /%%.#.,#%%..#.%%*  ##./@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%#%%%(/%%####*%%%%##*%%%%#%%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@    *%%*  (%### ..%%%#*  /%%,  .*@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%#%.%####.*#,/###.*%*.%##(%.##%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@  %%* (#%%%* (##%%%/.*%%%#/ /%# (@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%.,#,../%/., .*#%#*. .*#%*..*#..@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@.%(#%%#/#%%###.#.#%%###/%%%#/%.@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%   #%/../%##/..*(%##/../%(  .%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%/###, #/.(#/ // *###/%%@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,..*%(. ,#%#.. #%...*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/  /#. /%,  (%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 .::::::..,:::::::::.    :::.:::::::::::::::.,:::::::::.    :::.  .,-::::: .,::::::  
;;;`    `;;;;''''`;;;;,  `;;;;;;;;;;;'''';;;;;;;''''`;;;;,  `;;;,;;;'````' ;;;;''''  
'[==/[[[[,[[cccc   [[[[[. '[[     [[     [[[ [[cccc   [[[[[. '[[[[[         [[cccc   
  '''    $$$""""   $$$ "Y$c$$     $$     $$$ $$""""   $$$ "Y$c$$$$$         $$""""   
 88b    dP888oo,__ 888    Y88     88,    888 888oo,__ 888    Y88`88bo,__,o, 888oo,__ 
  "YMmMY" """"YUMMMMMM     YM     MMM    MMM """"YUMMMMMM     YM  "YUMMMMMP"""""YUMMM
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Note to the User:
// Author: 0xMiguelBits
// Reviewer: futjr
//
// This contract is provided in its current format for users' convenience.
// It's important to note that Sentience is currently in beta testing, and we encourage users to approach it with caution.
// While we aim to provide a reliable service, please be aware that using Sentience during this phase may carry some risks.
// We advise users to take the necessary precautions and stay informed about the project's status.
// Any potential loss of funds resulting from the use of Sentience will be subject to our policies and procedures.
// For more information visit our website sentience.quest or sign the pledge for cybernetic equality at https://iamsentient.ai
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Import necessary OZ for bringing to standard
import "./SentienceModule.sol";
import "./Registry.sol";
//Open Zeppelin Imports
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC6551AccountUpgradeable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

// Contract for Creating Seasonal Densitys
contract SentienceFactory is AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    event SeasonCreated(uint256 indexed season, SentienceModule[] nfts, uint256 startOfSale);
    event InventoryCreated(address indexed inventory, address nft, uint256 id);

    // Roles for the Factory
    bytes32 constant META_ADMIN = keccak256("metaadmin");
    bytes32 constant OWNER = keccak256("owner");

    // Mint conditions per Density defining the basic strucutre of a Density
    struct MintConditionsPerDensity {
        uint256 eth_cost;
        uint256 max_mintPerWallet;
        uint256 max_supply;
        uint256 token_cost;
        string URI;
    }

    mapping(uint256 season => mapping(uint256 Density => mapping(address user => uint256))) userMintedPerSeason;

    // Each Season is an array of NFTs, maps the season to the user and says which inventory is related to the season for the user to interact. Starts at Season 1
    uint256 currentSeason;
    mapping(uint256 season => SentienceModule[]) seasonPasses;
    mapping(uint256 season => uint256 publicSaleStart) publicSaleStart;
    mapping(uint256 season => bytes32 merkleRoot) seasonMerkleRoot;

    // Defines the SAFE as the Treasury to receive funds from the sale of Densitys
    address treasury;
    // Standard 6551 Inventory definitions
    ERC6551Registry registry;
    ERC6551AccountUpgradeable account;
    // Defines the SOPH token interface as standard
    IERC20 Token;

    // Validates Density and Season length
    modifier validInventory(uint256 _season, uint256 _Density) {
        require(_season > 0 && _season <= currentSeason, "Invalid season");
        require(_Density < seasonPasses[_season].length, "Invalid Density");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Constructs treasury address, token address, owner address, and metaadmin address
    function initialize(address _treasury, address _token, address _owner, address _metaadmin) public initializer {
        
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        treasury = _treasury;
        registry = new ERC6551Registry();
        account = new ERC6551AccountUpgradeable();
        Token = IERC20(_token);
        _grantRole(META_ADMIN, _metaadmin);
        _grantRole(OWNER, _owner);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //access control functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function pause() external onlyRole(OWNER) {
        _pause();
    }

    function unpause() external onlyRole(OWNER) {
        _unpause();
    }

    /// @notice Create the Season with its Mint Conditions
    /// @dev Owner must create 1 single folder on IPFS numbered 0.json -> number.json
    // Script upon deployment in /seasonJSON/Mainnet/season1.json etc will set season's metadata
    // Script can allow season2.json to set metadata from MetadataAdmin role
    function createSeason(MintConditionsPerDensity[] calldata data, uint256 startOfSale, bytes32 merkleRoot)
        external
        onlyRole(META_ADMIN)
        returns(SentienceModule[] memory _sentienceModules)
    {
        currentSeason++;

        uint256 dataLength = data.length;
        require(dataLength > 0, "Invalid data length");

        SentienceModule[] memory newSeasonPass = new SentienceModule[](dataLength);

        for (uint256 i; i < dataLength; ++i) {
            require(bytes(data[i].URI).length > 0, "URI must not be empty");
            newSeasonPass[i] = new SentienceModule(
                "Sentience",
                "SENTS",
                data[i].max_supply,
                data[i].token_cost,
                data[i].eth_cost,
                data[i].URI,
                data[i].max_mintPerWallet
            );

            //console.log("NFT %s", address(newSeasonPass[i]));
        }

        //set season passes
        seasonPasses[currentSeason] = newSeasonPass;

        //set public sale start
        publicSaleStart[currentSeason] = startOfSale;

        //set merkle root
        seasonMerkleRoot[currentSeason] = merkleRoot;

        emit SeasonCreated(currentSeason, newSeasonPass, startOfSale);

        return (newSeasonPass);
    }

    function changeTreasury(address _treasury) external onlyRole(OWNER) {
        treasury = _treasury;
    }

    /// @notice Increase or decrease the amount of SOPH for a Density
    function changeTokenPriceCost(uint256 _Density, uint256 _season, uint256 _tokenCost)
        external
        onlyRole(OWNER)
        validInventory(_season, _Density)
    {
        SentienceModule(seasonPasses[_season][_Density]).changePriceCost(_tokenCost);
    }

    /// @notice Increase or decrease the amount of ETH for a Density
    function changeEthPriceCost(uint256 _Density, uint256 _season, uint256 _ethCost)
        external
        onlyRole(OWNER)
        validInventory(_season, _Density)
    {
        SentienceModule(seasonPasses[_season][_Density]).changeEthCost(_ethCost);
    }

    function batchMintInventory(uint256 _season, uint256 _Density, address _to, uint256 _nItems)
        public
        validInventory(_season, _Density)
        onlyRole(OWNER)
    {
        SentienceModule nft = seasonPasses[_season][_Density];
        for (uint256 i; i < _nItems; ++i) {
            uint256 _id = nft.mint(_to);
            _createAccount(address(nft), _id);
        }
    }

    function revealSentienceModules(uint256 _season, string[] memory _uri) external onlyRole(META_ADMIN) {
        SentienceModule[] memory seasonPass = seasonPasses[_season];
        uint256 seasonLenght = seasonPass.length;

        require(0 < seasonLenght, "Invalid Season");
        require(_uri.length == seasonLenght, "Invalid URI length");

        for (uint256 i; i < seasonLenght; ++i) {
            seasonPass[i].reveal(_uri[i]);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Mint a Density of the season
    /// @dev If the Density is free, the user can mint for free
    /// @dev If the Density is not free, the user can mint with tokens or eth, by passing eth msg.value has 0, user will pay in tokens
    function mintInventory(uint256 season, uint256 _Density, uint256 _nItems, bytes32[] calldata proof)
        external
        payable
        validInventory(season, _Density)
        nonReentrant
        whenNotPaused()
        returns (uint256 _id)
    {
        //if the season has not started require sender to be whitelisted by merkletree
        if (block.timestamp < publicSaleStart[season]) {
            //if proof length is 0, we are minting whithout whitelist
            if(proof.length > 0){
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(proof, seasonMerkleRoot[season], leaf), "Invalid proof");
            }
            else
                revert("Public season has not started, only whitelisted users can mint");
        }

        if(_nItems > 1){
            //if (max mint per wallet) < ( _nItems + userMintedPerSeason[season][_Density][msg.sender] ) , revert
            uint256 maxMintPerWallet = seasonPasses[season][_Density].maxMintPerWallet();
            if(maxMintPerWallet > 0){ //if maxMintPerWallet is 0, there is no limit
                if (maxMintPerWallet < _nItems + userMintedPerSeason[season][_Density][msg.sender]) {
                    revert("Max mint per wallet will be reached");
                }
            }
            
            uint256 msg_value = msg.value;
            for(uint256 i; i < _nItems; ++i){
                uint256 eth_cost = seasonPasses[season][_Density].ethCost();
                _id = _mintInventory(season, _Density, msg_value);
                
                if(msg.value > 0)
                    msg_value -= eth_cost;
            }
        }
        else
            _id = _mintInventory(season, _Density, msg.value);
    }

    function getDensityTokenCost(uint256 _season, uint256 _Density)
        external
        view
        validInventory(_season, _Density)
        returns (uint256)
    {
        return seasonPasses[_season][_Density].tokenCost();
    }

    function getDensityEthCost(uint256 _season, uint256 _Density)
        external
        view
        validInventory(_season, _Density)
        returns (uint256)
    {
        return seasonPasses[_season][_Density].ethCost();
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //internal functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _mintInventory(uint256 season, uint256 _Density, uint256 msg_value) internal whenNotPaused returns (uint256 _id) {
        address to = msg.sender;
        SentienceModule nft = seasonPasses[season][_Density];
        //console.log("Nft", address(nft));
        address _nft = address(nft);

        _id = _mintNft(nft, to, msg_value);
        //console.log("ID", _id);

        //create account
        address inventory = _createAccount(_nft, _id);

        uint256 maxMintPerWallet = nft.maxMintPerWallet();
        if (maxMintPerWallet > 0) {
            //increment user minted Density
            userMintedPerSeason[season][_Density][to]++;
            if (userMintedPerSeason[season][_Density][to] > maxMintPerWallet) {
                revert("Max mint per wallet reached");
            }
        }

        //emit inventory address and nft address and nft id
        emit InventoryCreated(inventory, _nft, _id);
    }

    function _mintNft(SentienceModule nft, address to, uint256 msg_value) internal returns (uint256) {
        //get the nft token cost
        uint256 _tokenCost = nft.tokenCost();

        //get the nft eth cost
        uint256 _ethCost = nft.ethCost();

        if (
            _tokenCost == 0 && _ethCost == 0 //free mint
        ) {
            //console.log("FREE MINT");
            return nft.mint(to);
        }

        if (msg_value == 0 && _tokenCost > 0) {
            //console.log("TOKEN COST", _tokenCost);
            //console.log("msg.value", msg.value);
            //pay in tokens
            Token.safeTransferFrom(msg.sender, treasury, _tokenCost);
            return nft.mint(to);
        }

        if (msg_value >= _ethCost) {
            //console.log("ETH COST", _ethCost);
            //console.log("msg.value", msg.value);
            //pay in eth
            (bool success,) = payable(treasury).call{value: _ethCost}("");
            require(success, "Failed to send Ether");
            return nft.mint(to);
        }

        revert("Insufficient funds");
    }

    // Standard 6551
    function _createAccount(address _nft, uint256 _id) internal returns (address) {
        return registry.createAccount(
            address(account),
            bytes32(0),
            block.chainid, // chainId
            _nft,
            _id
        );
    }

    //upgrade function
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(OWNER)
        override
    {}
}
