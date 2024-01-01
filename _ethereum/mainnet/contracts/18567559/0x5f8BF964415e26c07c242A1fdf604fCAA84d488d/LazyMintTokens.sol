// SPDX-License-Identifier: MIT

pragma solidity >=0.4.23 <0.9.0;

/// @title: Legends of Cypher Lazy NFT Minter
/// @author: davoice321

//Manifold imports
import "AdminControl.sol";
import "IERC1155CreatorCore.sol";
import "ICreatorExtensionTokenURI.sol";
import "INFTRegistry.sol";
import "IWETH.sol";
import "IERC1155CreatorExtensionApproveTransfer.sol";
import "ICreatorCore.sol";
import "ERC1155CreatorExtensionApproveTransfer.sol";
import "IERC1155CreatorExtensionBurnable.sol";

//OpenZeppelin imports
import "ERC165.sol";
import "ERC165Checker.sol";
import "IERC1155MetadataURI.sol";
import "ReentrancyGuard.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//        ███████████████████████████████████████╠╬▓██████████████████████████████████████                                                                      //
//        ████████████████████████████████████▓▓╣╬╬╬╬╠╬███████████████████████████████████                                                                      //
//        ██████████████████████████████████▌╬╬▓█▓▓▓▓▓╬╬╣╬╬▀██████████████████████████████                                                                      //
//        ██████████████████████████████████▌╬╬╬╬╬╬▓█▓▓▓▓▓▓╣▓╬╬███████████████████████████                                                                      //
//        ██████████████████████████████████▌╬╠╠╩╠╠╠╬╬▓███▓▓▓▓▓▓▓╬╬███████████████████████                                                                      //
//        ██████████████████████████████████▌╬▒▒░Γ░╚╠╠╬╬╬╬██████▓▓▓▓▓╣▓███████████████████                                                                      //
//        ███████████████▓╬╬████████████████▌╬╬╠▒░_.░╚╚╚╩╠╬╬╬╬███████▓▓▓▓╣████████████████                                                                      //
//        ████████████▓▓▓▓▓▓▓▓▓█████████████▌╬╠▒░░░░░░φ∩⌡╚╚╚╠╬╬╬╬╬█████████▓▓▓████████████                                                                      //
//        ███████████╫████████╬╬╫███████████▌╠╩╠φφ░≥░╙╠ü███▄"╚╚╠╬╬╬╬╬╬████████▓███████████                                                                      //
//        ███████████╫▓████▓╬╬╬╩║███████████╦▒╠╠▒▒▒▒▒░φ≥▀█████▓▄╚╚╚╚╠╬╣▓▓████▓▌███████████                                                                      //
//        ███████████╫▓████╬╬╬▒Γ║███████╢▓╬╬╬╬╬╬╠╠╠╠╠▒▒▒▒φ░╠▀█████▄▄╚╠╬╬╣██▓▓╬╩███████████                                                                      //
//        ███████████╫▓▓███╬╬▒░░▐███╠╠╣╣╣╣╬╬╬╬╬╩╩╚╚╚▒╠╠╠╠╠╠╠▒▒≥╬██████▄╠╣█▓▓▓█████████████                                                                      //
//        ███████████╟▓▓███╬╬╠▒░▐██▌░╠╬╣▓╬╬╬╩╚ΓΓ""""Γ░╚╠╠╬╬╣▓▓╬╬██████████████████████████                                                                      //
//        ███████████║▓▓███╬╬╬▒░▐██▌░╠╠╬╬╬╬╩░'        "░╠╬╬╬▓▓╬╬██████████████████████████                                                                      //
//        ███████████║▓▓▓▓█╬╬╬▒░▐██▌░░╠╠╠╠▒░_          '░╠╬╣▓▓╬╬██████████████████████████                                                                      //
//        ███████████║▓▓▓▓█╬╬▒░░▐██▌░░▒╠╠╠░░__        _.░╠╬╬╬╬╬╬██████████████████████████                                                                      //
//        ███████████║╣▓▓▓█╬╬▒░░▐██▌\░░▒▒▒▒░░____   __.░φ╠╬╣╬╬╬╬φ╬▀███████████████████████                                                                      //
//        ███████████║╣▓▓▓█╬╬▒░░▐██▌'░░░░░▒▒░░░,....░φφ╠╠╬╬╬╬╬╬╠╠╠╠▒╬╬████████████████████                                                                      //
//        ███████████╚╣╣▓▓█╬╠▒░░▐██▌'_:░░░▒▒▒▒▒▒▒▒▒▒╠╠╬╬╣╬╬╬╬╠▒░╚╚╠╠╬╬╬▒╬▓████████████████                                                                      //
//        ███████████╞╬╣▓▓█╩Γ░" ▐████▄▄░░░░▒╠╠╠╬╣╣╬╣▓▓▓╣╬╬╬╬╬╙╠φφ░╙╚░▒╠╠╬╬╬╬╬█████████████                                                                      //
//        ███████████╞╬╣▓▓█Γ  __;┐╙▀█████▄ƒ╚╚╚╠╠╬╣▓▓▓▓╬╬╬╩▄ƒ╣╬╠╠╠╠▒▒φ▒╠╬╬╬╬▓▓█▒███████████                                                                      //
//        ███████████▐╬╣▓▓▓▄▄φφφφφφ░░│▀██████▄╚╚╠╟╬╬╬╝╠▓██████▄╚╣╬╠╠╠╠╬╬╣███▓▓▒███████████                                                                      //
//        ███████████▒╬╬╬╣▓▓▓█▓▓▒╬╬▒▒▒φ░░╠▀█████▄╠╠▓██████████████╬╚╬╬╬╬╣██▓▓╬ü███████████                                                                      //
//        █████████████▓╠╣╬╬╣▓▓▓▓██▓╬╬╬╠╠▒φφ≥╬▀██████████████████████▓╬╣╣█▓╬▓█████████████                                                                      //
//        █████████████████▓╙╣╬▓▓▓▓▓███▓╬╬╬╬╠▒▒▒░▀████████████████████████████████████████                                                                      //
//        █████████████████████╬╝╣▓▓▓▓▓███▓╬╬╬╠╠▒▒▒▒╬▀████████████████████████████████████                                                                      //
//        ████████████████████████▓╠╣▓▓▓▓▓████▓╬╣╣╬╬▓▓▓╫██████████████████████████████████                                                                      //
//        ████████████████████████████▓╟▓▓▓▓▓████████▓▓╞██████████████████████████████████                                                                      //
//        ████████████████████████████████▓▀▓▓▓█████▓▓╬╞██████████████████████████████████                                                                      //
//        ████████████████████████████████████▓▓▓██▓▀▓▓███████████████████████████████████                                                                      //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//        ████████████████████████████████████████████████████████████████████████████████                                                                      //
//                                                                                                                                                              //
//    ---                                                                                                                                                       //
//    Legends of Cypher: An immersive sci-fi universe featuring stories told across books, graphic novels, music and film. LegendsofCypher.io //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LoCLazyMintTokens is
    AdminControl,
    ICreatorExtensionTokenURI,
    IERC1155CreatorExtensionApproveTransfer,
    IERC1155CreatorExtensionBurnable,
    ReentrancyGuard
{
    /* ========== State Variables ========== */

    //Creator contract
    address private _core = 0x58E4E5C0d245Cda9D984c76D71ae23e030C7b5cf;
    string private _baseURI;
    string public extTokenURI;

    //Default mint maximum (per-transaction)
    uint256 public perWalletTxMintMaximum = 5;

    //Treasury account
    address payable immutable TREASURY =
        payable(0xa9f55E03FE7411501d06532111C92c58ebcA1D83);

    //NFT Registry
    address public NFTRegistryAddress;
    INFTRegistry private nftRegistryContract;

    //WETH interface
    address public WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH private WETH;

    /* ========== Structs and Mappings ========== */

    // Soulbound Tokens //

    //Soulbound tokens listing
    struct SoulBoundTokens {
        address tokenAddress;
        string tokenName;
    }

    //Token ID to soulbound token listing
    mapping(uint256 => SoulBoundTokens) private soulboundTokens;

    // Mint With Purchase //

    //Mint with purchase token listing
    struct MintWithTokenListing {
        bool isActive;
        uint256 tokenID;
    }

    //Token approved to be minted with a token purchase
    struct ApprovedMintWithTokenIDs {
        bool isActive;
        uint256 tokenID;
    }

    //Maps a mint with purchase ID to a tokenID of a token that can be minted with purchase
    mapping(uint256 => MintWithTokenListing) public mintWithPurchaseID;

    //Maps a token ID to the list of approved tokens that have mint with purchase status
    mapping(uint256 => ApprovedMintWithTokenIDs)
        public approvedMintWithTokenIDs;

    // Tracking Mints //

    //Max aggregate mints allowed per token ID (all wallet mints)
    mapping(uint256 => uint256) public maxAggWalletMintsAllowed;

    //Total mints per wallet, per token ID (all wallet mints)
    mapping(address => mapping(uint256 => uint256)) public mintCount;

    //Total whitelist mints per wallet, per token ID (all wallet whitelist mints)
    mapping(address => mapping(uint256 => uint256)) whitelistMintCount;

    // Whitelist Management //

    //Tokens that can only be minted via whitelist
    struct MintOnlyThroughWhiteListToken {
        bool isWhiteListActive;
        uint256 whiteListTokenID;
    }

    //Token ID to mint only through whitelist listing
    mapping(uint256 => MintOnlyThroughWhiteListToken)
        private mintOnlyThroughWhiteListToken;

    //TokenIDs that can only be minted via whitelist linked to tokens holders must own to mint whitelisted tokens
    struct LinkedWhiteListTokenIDs {
        bool isTokenLinked;
        uint256 linkedTokenID;
        uint256[] tokenIDsAuthorizedtoMintToken;
    }

    //Map tokenID of whitelist-only to listing of tokens holders must own to mint whitelisted tokens
    mapping(uint256 => LinkedWhiteListTokenIDs) private linkedWhiteListTokenIDs;

    /* ========== Constructor ========== */

    constructor(address _NFTRegistryAddress) {
        require(
            _NFTRegistryAddress != address(0),
            "NFTRegistry address must be set."
        );
        NFTRegistryAddress = _NFTRegistryAddress;
        nftRegistryContract = INFTRegistry(NFTRegistryAddress);
        WETH = IWETH(WETHAddress);
    }

    /* ========== Events ========== */
    //NFT sale
    event NFTSale(
        uint256 indexed tokenId,
        uint256 mintFee,
        address nftRecipient
    );

    //Token minted with purchase
    event TokenMintedWithPurchase(
        address owner,
        uint256 indexed mintWithTokenID,
        uint256 amount
    );

    //Treasury deposit
    event TreasuryDeposit(uint256 indexed tokenId, uint256 wethDeposited);

    //Soulbound token status
    event TokenAddedToSoulBoundList(uint256 indexed tokenId, string tokenName);
    event TokenRemovedFromSoulBoundList(uint256 tokenId);

    //Approve transfer called (for soulbound tokens)
    event ApproveTransferCalled(
        address indexed from,
        address indexed to,
        uint256[] tokenIds,
        uint256[] amounts
    );

    //Set extension as transfer approval success
    event ApproveTransferSet(address indexed creator, bool enabled);

    //Extension token burned
    event ExtensionTokenBurned(
        address owner,
        uint256[] indexed tokenIds,
        uint256[] amounts
    );

    /* ========== NFT Registry Set Address, Initialize Registry Interface ========== */

    //NFT Registry Address setter ** Admin-only function **
    function setNFTRegistryAddress(address _newAddress) public adminRequired {
        NFTRegistryAddress = _newAddress;
    }

    //Get NFT Registry address
    function getNFTRegistryAddress() public view returns (address) {
        return NFTRegistryAddress;
    }

    /* ========== WETH Contract Set Address ========== */

    //Re-set WETH address ** Admin-only function **
    function setWETHAddress(address _newAddress) public adminRequired {
        WETHAddress = _newAddress;
    }

    /* ========== Initialize Creator Core Contract Interface ========== */

    //CreatorCore contract (minting contract this contract interacts with)
    ICreatorCore core_creator_contract = ICreatorCore(_core);

    /* ========== Enable ETH Deposits ========== */

    //Receive ETH: Fallbacks
    fallback() external payable {}

    receive() external payable {}

    /* ========== Transfer Ether and ERC20s from Contract ========== */

    //Get ETH balance in contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //Transfer ETH from contract ** Admin-only function **
    function transferEther(
        address payable recipient,
        uint256 amount
    ) external adminRequired returns (bool) {
        require(
            amount <= getBalance(),
            "Insufficient contract balance for transfer."
        );
        recipient.transfer(amount);
        return true;
    }

    //Wrap ETH deposited into contract to WETH
    function _depositETHtoWETH(uint256 _amount) internal {
        WETH.deposit{value: _amount}();
    }

    //Transfer ERC20 tokens from contract (internal)
    function _transferERC20(IERC20 token, address to, uint256 amount) internal {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Balance too low to transfer token.");
        require(WETH.approve(to, type(uint256).max));
        token.transfer(to, amount);
    }

    //Transfer ERC20 tokens from contract (external) ** Admin-only function **
    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external adminRequired {
        _transferERC20(token, to, amount);
    }

    /* ========== Contract Mint/Whitelist/Mint With Purchase Status Toggle ========== */

    //Mint status options
    enum mintStatus {
        mintActive, //0
        mintInactive //1
    }

    //Default mint status: Active
    mintStatus public current_mint_status = mintStatus.mintActive;

    //Pause/unpause minting ** Admin-only function **
    function setMintStatus(uint256 _value) public adminRequired {
        current_mint_status = mintStatus(_value);
    }

    function getCurrentMintStatus() public view returns (mintStatus) {
        return current_mint_status;
    }

    //Whitelist status options
    enum whiteListStatus {
        whiteListActive, //0
        whiteListInactive //1
    }

    //Default whitelist status: Inactive
    whiteListStatus public current_whitelist_status =
        whiteListStatus.whiteListInactive;

    //Update whitelist minting status ** Admin-only function **
    function setWhiteListStatus(uint256 value) public adminRequired {
        current_whitelist_status = whiteListStatus(value);
    }

    //Mint with purchase status options
    enum mintWithPurchaseStatus {
        mintWithPurchaseActive, //0
        mintWithPurchaseInactive //1
    }

    //Default mint with purchase status: Inactive
    mintWithPurchaseStatus public current_mint_with_purchase_status =
        mintWithPurchaseStatus.mintWithPurchaseInactive;

    //Update mint with purchase status ** Admin-only function **
    function setMintWithPurchaseStatus(uint256 value) public adminRequired {
        current_mint_with_purchase_status = mintWithPurchaseStatus(value);
    }

    /* ========== Core Minting Contract Address, Per-Wallet Mint Maximum Setters ========== */

    // Reset core minting contract address for contract ** Admin-only function **
    function resetCoreMintingContractAddress(
        address _coreMintingContractAddress
    ) external adminRequired {
        _core = _coreMintingContractAddress;
    }

    // Reset NFT mint maximum per wallet (per tx) ** Admin-only function **
    function setPerWalletTxMintMaximum(
        uint256 _mintMaximum
    ) external adminRequired {
        perWalletTxMintMaximum = _mintMaximum;
    }

    // Get NFT mint maximum per wallet (per tx)
    function getPerWalletTxMintMaximum() public view returns (uint256) {
        return perWalletTxMintMaximum;
    }

    //Get token details by tokenID from NFT Registry: Token address, token name, mint fee, mint maximum
    function getNFTInformation(
        uint256 _tokenID
    ) public view returns (address, string memory, uint256, uint256) {
        require(
            NFTRegistryAddress != address(0),
            "NFTRegistry address not set."
        );

        return nftRegistryContract.getToken(_tokenID);
    }

    // Sets NFT mint maximum per wallet (in aggregate, per token ID) ** Admin-only function **
    function setAggWalletMintMaximum(
        uint256 _tokenID,
        uint256 _walletMintAggMax
    ) external adminRequired {
        maxAggWalletMintsAllowed[_tokenID] = _walletMintAggMax;
    }

    //Get mint count for the token per address, per token ID
    function getMintCount(
        address _address,
        uint256 _tokenId
    ) public view returns (uint256) {
        return mintCount[_address][_tokenId];
    }

    //Get mint count for the token per whitelisted address, per token ID
    function getWhiteListedMintCount(
        address _address,
        uint256 _tokenId
    ) public view returns (uint256) {
        return whitelistMintCount[_address][_tokenId];
    }

    /* ========== Get Total Token Supply and Individual Token Balance  ========== */

    //Get total token supply
    function getTotalTokenSupply(
        uint256 _tokenId
    ) public view returns (uint256) {
        return IERC1155CreatorCore(_core).totalSupply(_tokenId);
    }

    //Get token balance of account
    function getTokenBalance(
        address _account,
        uint256 _tokenId
    ) public view returns (uint256) {
        return core_creator_contract.balanceOf(_account, _tokenId);
    }

    /* ========== WhiteList Management  ========== */

    // Add tokenID to list of tokens that can only be minted if on token whitelist ** Admin-only function **
    function addTokenToMintOnlyThroughWhiteList(
        uint256 _tokenId
    ) public adminRequired {
        MintOnlyThroughWhiteListToken memory newWhiteListToken;
        newWhiteListToken.isWhiteListActive = true;
        newWhiteListToken.whiteListTokenID = _tokenId;
        mintOnlyThroughWhiteListToken[_tokenId] = newWhiteListToken;
    }

    // Remove tokens from list of tokens that can only be minted if on token whitelist ** Admin-only function **
    function removeFromWMintOnlyThroughWhiteList(
        uint256 _tokenId
    ) public adminRequired {
        require(
            mintOnlyThroughWhiteListToken[_tokenId].isWhiteListActive == true,
            "Token ID does not exist in whitelist!"
        );
        delete mintOnlyThroughWhiteListToken[_tokenId];
    }

    // Check if token is on list of tokens that can only be minted if on token whitelist
    function isTokenOnMintOnlyThroughWhiteList(
        uint256 _tokenId
    ) public view returns (bool) {
        return mintOnlyThroughWhiteListToken[_tokenId].isWhiteListActive;
    }

    // Link tokenID (same token that can only be minted via whitelist) to list of tokens that can be used to mint it ** Admin-only function **
    function linkTokensToAuthorizedWhiteListToken(
        uint256 _tokenId,
        uint256[] memory _tokensPermitedtoMintWhiteList
    ) public adminRequired {
        // Create AuthorizedWhiteListTokenIDs object
        LinkedWhiteListTokenIDs storage linkedToken = linkedWhiteListTokenIDs[
            _tokenId
        ];

        //Token must not already linked to other tokens
        require(!linkedToken.isTokenLinked, "Token already linked");

        // Set linked token status to true
        linkedToken.isTokenLinked = true;
        linkedToken.linkedTokenID = _tokenId;

        // Add array of token IDs authorized to mint a token
        for (uint i = 0; i < _tokensPermitedtoMintWhiteList.length; i++) {
            linkedToken.tokenIDsAuthorizedtoMintToken.push(
                _tokensPermitedtoMintWhiteList[i]
            );
        }
    }

    // Unlink tokenID from listing of tokens that can mint it (when token removed from whitelist-only minting status) ** Admin-only function **
    function unlinkTokensFromAuthorizedWhiteListToken(
        uint _tokenId
    ) public adminRequired {
        require(
            linkedWhiteListTokenIDs[_tokenId].isTokenLinked == true,
            "Token ID is not linked."
        );

        // Delete the token from the AuthorizedWhiteListTokenIDs mapping
        delete linkedWhiteListTokenIDs[_tokenId];
    }

    // Given a token ID, return list of token IDs that can be used to mint it
    function getTokenIDsAuthorizedtoMintWhiteListToken(
        uint256 _tokenId
    ) public view returns (uint256[] memory) {
        LinkedWhiteListTokenIDs storage linkedToken = linkedWhiteListTokenIDs[
            _tokenId
        ];
        require(linkedToken.isTokenLinked, "Token ID is not linked.");
        uint256[] memory associatedTokenIDs = linkedToken
            .tokenIDsAuthorizedtoMintToken;

        return associatedTokenIDs;
    }

    /* ========== Update Mint Count (Normal / Whitelist), Get Mint Fee, Set Mint With Token Status, Authorize Tokens That Can Mint Other Tokens With Purchase  ========== */

    //Update wallet mint count (normal mints)
    function _updateMintCount(
        address _address,
        uint256 _mintAmount,
        uint256 _tokenId
    ) internal {
        mintCount[_address][_tokenId] += _mintAmount;
    }

    //Update wallet mint count (whitelist mints)
    function _updateMintCountWhiteList(
        address _address,
        uint256 _mintAmount,
        uint256 _tokenId
    ) internal {
        whitelistMintCount[_address][_tokenId] += _mintAmount;
    }

    //Return MintFee for a specific tokenID
    function getMintFee(uint256 _tokenID) public view returns (uint256) {
        (, , uint256 tokenMintFee, ) = getNFTInformation(_tokenID);
        return tokenMintFee;
    }

    //Add token to list of tokens that can be minted with purchase ** Admin-only function **
    function setMintWithTokenID(
        uint256 _mintWithPurchaseId,
        bool _isActiveStatus,
        uint256 _airdroppedTokenId
    ) public adminRequired {
        MintWithTokenListing storage mint = mintWithPurchaseID[
            _mintWithPurchaseId
        ];

        mint.isActive = _isActiveStatus;
        mint.tokenID = _airdroppedTokenId;
    }

    //Remove token from list of tokens that can be minted with purchase (using mintWithPurchaseID) ** Admin-only function **
    function deactivateMintWithTokenStatus(
        uint256 _mintWithPurchaseId
    ) public adminRequired {
        MintWithTokenListing storage mint = mintWithPurchaseID[
            _mintWithPurchaseId
        ];

        // Ensure that the MintWithTokenListing exists (by checking purchaseTokenId)
        require(mint.tokenID != 0, "MintWithTokenListing does not exist");

        mint.isActive = false;
    }

    //Add a token to list of token IDs with authorized mint with token status ** Admin-only function **
    function authorizeTokenIDToMintWithToken(
        uint256 _purchaseTokenId,
        bool _isActive
    ) public adminRequired {
        ApprovedMintWithTokenIDs storage approve = approvedMintWithTokenIDs[
            _purchaseTokenId
        ];

        approve.isActive = _isActive;
        approve.tokenID = _purchaseTokenId;
    }

    //Remove token from list of tokens authorized to mint with purchase ** Admin-only function **
    function deauthorizePurchaseWithMintStatus(
        uint256 _purchaseTokenId
    ) public adminRequired {
        ApprovedMintWithTokenIDs storage approve = approvedMintWithTokenIDs[
            _purchaseTokenId
        ];

        // Ensure that the MintWithTokenListing exists
        require(
            approve.tokenID != 0,
            "Token ID not on list of tokens authorized to mint with token purchase"
        );

        approve.isActive = false;
    }

    /* ========== Mint Brand New Tokens via the Extension (First-Time Mint)  ========== */

    //Mint brand new token via the extension ** Admin-only function **
    function mintNewTokens(
        address core,
        string memory _uri
    ) public adminRequired {
        _core = core;

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        string[] memory uris = new string[](1);
        uris[0] = _uri;
        //Contract mint status must be active
        require(
            getCurrentMintStatus() == mintStatus.mintActive,
            "Minting is currently paused."
        );

        IERC1155CreatorCore(_core).mintExtensionNew(to, amounts, uris);
    }

    /* ========== Mint Copies of Tokens Generated By This Extension  ========== */

    //Mint a token with purchase
    function _mintWithPurchase(
        uint256 _purchaseTokenID,
        uint256 _mintWithTokenID,
        uint256 _mintAmount
    ) internal {
        //Check that purchase token is authorized for mint with token purchase status
        require(
            approvedMintWithTokenIDs[_purchaseTokenID].isActive == true,
            "Token not approved for mint with token purchase status"
        );

        // Retrieve mint with purchase tokenID
        uint256 tokenID = mintWithPurchaseID[_mintWithTokenID].tokenID;

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _mintAmount;

        //Mint with purchase tokenID must be on approved NFT mint list
        (address tokenAddress, , , ) = getNFTInformation(tokenID);
        require(tokenAddress != address(0), "Token not in approved mint list.");

        //Calculate total token supply after transaction
        (, , , uint256 maxAllowedTokenMintAmount) = getNFTInformation(tokenID);

        uint256 currentTokenSupply = getTotalTokenSupply(tokenID);

        uint256 tokenSupplyAfterMint = currentTokenSupply + _mintAmount;

        //Max token mint supply must not be breached
        require(
            tokenSupplyAfterMint <= maxAllowedTokenMintAmount,
            "Transaction would result in token supply above maximum mint allowance."
        );

        // Update wallet's mint count
        _updateMintCount(msg.sender, _mintAmount, tokenID);

        // Mint NFT(s)
        IERC1155CreatorCore(_core).mintExtensionExisting(to, tokenIds, amounts);
    }

    //Check whether wallet is authorized to mint whitelist-only token
    function _checkWalletWhitelistApprovalStatus(
        uint256 _tokenID,
        uint256 _mintAmount
    ) internal {
        //Determine which tokens are authorized to mint token
        uint256[]
            memory authorizedWhiteListMintTokenIDs = getTokenIDsAuthorizedtoMintWhiteListToken(
                _tokenID
            );

        //Get current mint count for whitelisted token
        uint256 current_whitelisted_wallet_mint_amount = getWhiteListedMintCount(
                msg.sender,
                _tokenID
            );

        //Calculate wallet whitelist token mint amount after transaction
        uint256 new_whitelist_wallet_mint_amount = current_whitelisted_wallet_mint_amount +
                _mintAmount;

        //Get user's total balance of tokens authorized to mint whitelisted token
        uint256 whiteListTokenBalance = 0;

        for (uint i = 0; i < authorizedWhiteListMintTokenIDs.length; i++) {
            whiteListTokenBalance += getTokenBalance(
                msg.sender,
                authorizedWhiteListMintTokenIDs[i]
            );
        }

        // Total wallet whitelisted token balance must be > 0
        require(
            whiteListTokenBalance > 0,
            "Total wallet balance for all tokens required to mint whitelisted token must be greater than 0"
        );

        // Mint count must not exceed token minter's balance of tokens that can be used to mint whitelisted token
        require(
            new_whitelist_wallet_mint_amount <= whiteListTokenBalance,
            "This transaction will exceed the whitelisted token mint allowance for this wallet."
        );

        // Update wallet's whitelisted mint count
        _updateMintCountWhiteList(msg.sender, _mintAmount, _tokenID);
    }

    //Mint multiple copies of a single token, to a single paying address
    function mintExistingToken(
        uint256 _tokenID,
        uint256 _mintAmount,
        uint256 _mintWithTokenID
    ) public payable nonReentrant {
        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _mintAmount;

        //Contract mint status must be active
        require(
            getCurrentMintStatus() == mintStatus.mintActive,
            "Minting is currently paused."
        );

        //Token to be minted must be in the approved list
        (address tokenAddress, , , ) = getNFTInformation(_tokenID);
        require(tokenAddress != address(0), "Token not in approved mint list.");

        // Per-transaction mint amount must not exceed maximum
        require(
            _mintAmount <= perWalletTxMintMaximum,
            "Mint amount exceeds transaction maximum."
        );

        //If whitelist status is active and token has mint only through whitelist status, conduct whitelist and token balance check //
        if (
            current_whitelist_status == whiteListStatus.whiteListActive &&
            isTokenOnMintOnlyThroughWhiteList(_tokenID) == true
        ) {
            _checkWalletWhitelistApprovalStatus(_tokenID, _mintAmount);
        } else if (
            //If token does not have mint only through whitelist status update non-whitelisted mint count //

            !isTokenOnMintOnlyThroughWhiteList(_tokenID)
        ) {
            // Calculate wallet mint total after transaction
            uint256 current_wallet_tx_amount = getMintCount(
                msg.sender,
                _tokenID
            );
            uint256 new_wallet_tx_amount = current_wallet_tx_amount +
                _mintAmount;

            // Wallet mint (non whitelisted token) must not exceed per-wallet maximum
            require(
                new_wallet_tx_amount <= maxAggWalletMintsAllowed[_tokenID],
                "This transaction will exceed the mint allowance for this wallet."
            );

            // Update wallet's mint count
            _updateMintCount(msg.sender, _mintAmount, _tokenID);
        }

        // Mint Token (Non-Whitelist and Whitelist) //

        //Calculate total token supply after transaction
        (, , , uint256 maxAllowedTokenMintAmount) = getNFTInformation(_tokenID);

        uint256 currentTokenSupply = getTotalTokenSupply(_tokenID);

        uint256 tokenSupplyAfterMint = currentTokenSupply + _mintAmount;

        //Max token mint supply must not be breached
        require(
            tokenSupplyAfterMint <= maxAllowedTokenMintAmount,
            "Transaction would result in token supply above maximum mint allowance."
        );

        //Calculate total mint fee for user
        (, , uint256 buyMintFee, ) = getNFTInformation(_tokenID);
        uint256 total_mint_fee = buyMintFee * _mintAmount;

        //Full mint fee must be paid
        require(
            msg.value == total_mint_fee,
            "Mint fee not paid or too low/high."
        );

        //Wrap ETH to WETH
        _depositETHtoWETH(total_mint_fee);

        // Mint NFT(s)
        IERC1155CreatorCore(_core).mintExtensionExisting(to, tokenIds, amounts);

        //Send WETH to Treasury
        _transferERC20(WETH, TREASURY, total_mint_fee);

        emit TreasuryDeposit(_tokenID, total_mint_fee);

        emit NFTSale(_tokenID, total_mint_fee, msg.sender);

        // Mint with purchase (if status is active, and ID is valid) //

        if (
            current_mint_with_purchase_status ==
            mintWithPurchaseStatus.mintWithPurchaseActive &&
            mintWithPurchaseID[_mintWithTokenID].isActive == true
        ) {
            uint256 mintWithPurchaseAmount = _mintAmount;

            _mintWithPurchase(
                _tokenID,
                _mintWithTokenID,
                mintWithPurchaseAmount
            );

            emit TokenMintedWithPurchase(
                msg.sender,
                _mintWithTokenID,
                mintWithPurchaseAmount
            );
        }
    }

    //Mint multiple copies of a single tokenID and send to multiple addresses ** Admin-only function **
    function mintExistingTokens(
        address[] memory _to,
        uint256 _tokenID,
        uint256[] memory _amounts
    ) public adminRequired {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenID;

        require(
            _to.length == _amounts.length,
            "To and amounts array lengths must match"
        );

        //Contract mint status must be active
        require(
            getCurrentMintStatus() == mintStatus.mintActive,
            "Minting is currently paused."
        );

        //Token to be minted must be in the approved list
        (address tokenAddress, , , ) = getNFTInformation(_tokenID);
        require(tokenAddress != address(0), "Token not in approved mint list.");

        // Mint NFT(s)
        IERC1155CreatorCore(_core).mintExtensionExisting(
            _to,
            tokenIds,
            _amounts
        );
    }

    /* ========== Enable/Disable Token Transfers (Soulbound Tokens)  ========== */

    //Get current soulbound token status
    function getSoulBoundTokens(
        uint256 _tokenId
    ) public view returns (address, string memory) {
        SoulBoundTokens memory token = soulboundTokens[_tokenId];
        if (token.tokenAddress == address(0)) {
            return (address(0), "NFT not on list.");
        }
        return (token.tokenAddress, token.tokenName);
    }

    //Add token to soulbound token list ** Admin-only function **
    function addSoulBoundToken(
        uint256 _tokenId,
        address _tokenAddress,
        string memory tokenName
    ) external adminRequired {
        SoulBoundTokens storage token = soulboundTokens[_tokenId];
        token.tokenAddress = _tokenAddress;
        token.tokenName = tokenName;
        emit TokenAddedToSoulBoundList(_tokenId, tokenName);
    }

    //Remove token from soulbound token list ** Admin-only function **
    function removeSoulBoundToken(uint256 _tokenId) external adminRequired {
        SoulBoundTokens storage token = soulboundTokens[_tokenId];
        if (token.tokenAddress == address(0)) {
            revert("Token not found.");
        }
        delete soulboundTokens[_tokenId];
        emit TokenRemovedFromSoulBoundList(_tokenId);
    }

    //Approve extension as token transfer approver ** Admin-only function **
    function setApproveTransfer(
        address _creator,
        bool _enabled
    ) external adminRequired {
        require(
            ERC165Checker.supportsInterface(
                _creator,
                type(IERC1155CreatorCore).interfaceId
            ),
            "creator must implement IERC1155CreatorCore"
        );
        IERC1155CreatorCore(_creator).setApproveTransferExtension(_enabled);
        emit ApproveTransferSet(_creator, _enabled);
    }

    //Called by the Creator contract to determine if a token is transferable

    function approveTransfer(
        address _from,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external returns (bool) {
        bool result = _approveTransfer(_from, _to, _tokenIds);
        emit ApproveTransferCalled(_from, _to, _tokenIds, _amounts);
        return result;
    }

    //Returns true or false if the token is/is not transferable
    function _approveTransfer(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) private view returns (bool) {
        // Iterate through the tokenIds array and determine if each token is approved for transfer
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Check the token for soulbound status. If the token is soulbound, return false
            if (!_isTokenTransferApproved(_from, _to, _tokenIds[i])) {
                return false;
            }
        }

        // If a token is approved for transfer, return true
        return true;
    }

    //Checks the soulbound tokens struct to determine if a token is soulbound
    function _isTokenTransferApproved(
        address _from,
        address _to,
        uint256 _tokenId
    ) private view returns (bool) {
        // Call the getSoulBoundToken function for the token id
        (address tokenAddress, ) = getSoulBoundTokens(_tokenId);

        // If the token is NOT on the soulbound list or is newly minted, or is to the burn address, approve the transfer
        if (
            tokenAddress == address(0) ||
            _from == address(0) ||
            _to == address(0)
        ) {
            return true;
        }
        // If the token is soulbound, not newly minted or being burned, disapprove the transfer
        return false;
    }

    /* ========== Register Token Burn Events  ========== */

    function onBurn(
        address _owner,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external {
        emit ExtensionTokenBurned(_owner, _tokenIds, _amounts);
    }

    /* ========== Interface Support  ========== */

    //Get creator extension token URI interface (needed to tell other contracts that interface is supported)
    function getICreatorExtensionTokenURIInterfaceId()
        public
        pure
        returns (bytes4)
    {
        return type(ICreatorExtensionTokenURI).interfaceId;
    }

    //Get creator extension token approval interface (needed to tell other contracts that interface is supported)
    function getIERC1155CreatorExtensionApproveTransferInterfaceId()
        public
        pure
        returns (bytes4)
    {
        return type(IERC1155CreatorExtensionApproveTransfer).interfaceId;
    }

    //Alert other contracts about what functions this contract supports
    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(AdminControl, IERC165) returns (bool) {
        return
            _interfaceId == getICreatorExtensionTokenURIInterfaceId() ||
            _interfaceId ==
            getIERC1155CreatorExtensionApproveTransferInterfaceId() ||
            AdminControl.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId);
    }

    /* ========== Token URI Set and View  ========== */

    //Set the token URI (metadata) ** Admin-only function **
    function resetTokenURI(
        uint256 _tokenId,
        string calldata _uri
    ) external adminRequired {
        core_creator_contract.setTokenURIExtension(_tokenId, _uri);
    }

    //Set token URI Prefix (Useful for Arweave) ** Admin-only function **
    function setTokenURIPrefixExtension(
        string calldata _prefix
    ) external adminRequired {
        core_creator_contract.setTokenURIPrefixExtension(_prefix);
    }

    function viewTokenURI(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (string memory) {
        IERC1155MetadataURI core = IERC1155MetadataURI(_contractAddress);
        return core.uri(_tokenId);
    }

    //Set the token Base URI ** Admin-only function **
    function setBaseURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    //View base URI of token minted by the extension
    function tokenURI(
        address core,
        uint256 tokenId
    ) external view override returns (string memory) {
        require(core == _core, "Invalid token.");

        return (_baseURI);
    }

    /* ========== Token Royalties  ========== */

    //Set royalties for tokens minted via this extension ** Admin-only function **
    function setRoyaltiesExtension(
        address _extension,
        address payable[] calldata _receivers,
        uint256[] calldata _basisPoints
    ) external adminRequired {
        core_creator_contract.setRoyaltiesExtension(
            _extension,
            _receivers,
            _basisPoints
        );
    }
}

//End of Contract
