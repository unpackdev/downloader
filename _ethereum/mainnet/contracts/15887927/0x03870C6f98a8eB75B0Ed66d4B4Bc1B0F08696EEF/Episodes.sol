// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************

        ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
        ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
        ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
        ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
        ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
        ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
  
                                 ██╗  ██╗
                                 ╚██╗██╔╝
                                  ╚███╔╝
                                  ██╔██╗
                                 ██╔╝ ██╗
                                 ╚═╝  ╚═╝

___/\/\/\/\____/\/\/\/\/\__________/\/\/\/\/\/\______/\/\/\/\/\/\__/\/\______/\/\_
_/\/\____/\/\__________/\/\______________/\/\________/\/\__________/\/\/\__/\/\/\_
___/\/\/\/\/\____/\/\/\/\______________/\/\__________/\/\/\/\/\____/\/\/\/\/\/\/\_
_________/\/\__/\/\__________/\/\____/\/\____________/\/\__________/\/\__/\__/\/\_
___/\/\/\/\____/\/\/\/\/\/\__/\/\__/\/\______________/\/\__________/\/\______/\/\_
__________________________________________________________________________________    

       ______  ______  _____  _______ ______  ______ _ ______  _______ 
      (____  \(_____ \(_____)(_______|______)/ _____) (______)(_______)
       ____)  )_____) )  __ _ _______ _     ( (____ | |_     _ _____   
      |  __  (|  __  / |/ /| |  ___  | |   | \____ \| | |   | |  ___)  
      | |__)  ) |  \ \   /_| | |   | | |__/ /_____) ) | |__/ /| |_____ 
      |______/|_|   |_\_____/|_|   |_|_____/(______/|_|_____/ |_______)
           

  nervous.net :: dylan@nervous.net // steve@nervous.net
  mono-koto.com :: brent@mono-koto.com
******************************************************************************/

import "./Bones.sol";
import "./IEpisodes.sol";
import "./IOwnedToken.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

/// @title BROADSIDE Phase 1: Episodes
/// @author nervous.net / mono-koto.com
contract Episodes is
    IEpisodes,
    ERC1155Upgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    struct Episode {
        string uri;
        uint256 totalSupply;
        uint256 __gap;
    }

    struct WalletMeta {
        uint8 forewordMints;
        bool isCreator;
        uint240 __gap;
    }

    event SetWarHe4d(address indexed warHe4d);
    event SetBurner(address indexed burner);
    event Pause();
    event Unpause();
    event SetEpisodeCreator(address indexed creator, bool isCreator);
    event SetContractURI(string uri);
    event ConfigureForeword(uint40 startDate, uint40 endDate, uint8 limit);

    // --- Constants ---

    /// Private
    uint256 private constant FOREWORD_ID = 0;
    uint40 private constant DEFAULT_FOREWORD_MINT_START_DATE = 1667577600;
    uint40 private constant DEFAULT_FOREWORD_MINT_DURATION = 72 hours;
    uint40 private constant DEFAULT_FOREWORD_MINT_END_DATE =
        DEFAULT_FOREWORD_MINT_START_DATE + DEFAULT_FOREWORD_MINT_DURATION;
    uint8 private constant DEFAULT_FOREWORD_WALLET_MINT_LIMIT = 3;

    string public constant _NERVOUS_ =
        "We are Nervous. Are you? Let us help you with your next NFT project -> dylan@nervous.net";
    string public constant name = "BROADSIDE Phase 1: Episodes";
    string public constant symbol = "BSIDE1-EPS";

    // --- Storage ---

    /// Private
    mapping(address => WalletMeta) private _walletMeta;
    mapping(uint256 => Episode) private _episodes;
    mapping(uint256 => uint256) private _pfpMeta;

    /// Public
    string public contractURI;
    IOwnedToken public warHe4d;
    uint40 public forewordMintStartDate;
    uint40 public forewordMintEndDate;
    uint8 public forewordWalletMintLimit;
    address public burner;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC1155_init_unchained("");
        __ERC2981_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        forewordMintStartDate = DEFAULT_FOREWORD_MINT_START_DATE;
        forewordMintEndDate = DEFAULT_FOREWORD_MINT_END_DATE;
        forewordWalletMintLimit = DEFAULT_FOREWORD_WALLET_MINT_LIMIT;
    }

    //// STANDARD ERC1155 + EXTENSION FUNCTIONS

    function uri(uint256 id) public view override returns (string memory) {
        return _episodes[id].uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //// MINTING

    /// @notice Free mint of the foreword episode.
    /// @param quantity The number of foreword episodes to mint.
    ///                 Limited to `forewordWalletMintLimit` per wallet.
    ///                 Only available during mint window.
    function mintForeword(uint8 quantity) external whenNotPaused {
        require(
            block.timestamp >= forewordMintStartDate,
            "Foreword mint not started"
        );
        require(block.timestamp <= forewordMintEndDate, "Foreword mint ended");

        WalletMeta storage meta = _walletMeta[_msgSender()];
        require(
            meta.forewordMints + quantity <= forewordWalletMintLimit,
            "Exceeds max mint per wallet"
        );
        _episodes[FOREWORD_ID].totalSupply += quantity;
        meta.forewordMints += quantity;

        _mint(_msgSender(), FOREWORD_ID, quantity, "");
    }

    /// @notice WAR HE4D claim of episodes
    /// @param episodeId Episode ID to claim. Must have a URL set and cannot be foreword.
    /// @param tokenId   The WAR HE4D token ID to claim with. Can only be used once.
    function claim(uint8 episodeId, uint256 tokenId) external whenNotPaused {
        Episode storage episode = _episodes[episodeId];
        require(episodeId != FOREWORD_ID, "Invalid episode");
        require(bytes(episode.uri).length > 0, "Episode not found");
        require(address(warHe4d) != address(0), "No WAR HE4D");
        require(
            _msgSender() == warHe4d.ownerOf(tokenId),
            "Only WAR HE4D owner"
        );
        require(!warHe4dHasClaimed(episodeId, tokenId), "Already claimed");

        _markClaimed(episodeId, tokenId);
        ++episode.totalSupply;
        _mint(_msgSender(), episodeId, 1, "");
    }

    //// GETTERS

    /// @notice Check whether the given account is a creator
    /// @param account The wallet address
    /// @return Whether the account is a creator
    function isEpisodeCreator(address account) external view returns (bool) {
        return _walletMeta[account].isCreator;
    }

    /// @notice Get the number of forewords a wallet has minted
    /// @param wallet The wallet address
    /// @return The number of forewords minted
    function mintedForewords(address wallet) external view returns (uint256) {
        return _walletMeta[wallet].forewordMints;
    }

    /// @notice Total quantity of episode minted
    /// @dev Returns 0 if the episode does not exist
    /// @param episodeId The episode ID
    /// @return Quantity of episode minted
    function episodeSupply(uint8 episodeId) public view returns (uint256) {
        return _episodes[episodeId].totalSupply;
    }

    /// @notice Whether WAR HE4D has claimed a episode
    /// @dev Returns false if the episode does not exist
    /// @param episodeId The episode ID
    /// @param tokenId The WAR HE4D token ID
    /// @return Whether the WAR HE4D has claimed the episode
    function warHe4dHasClaimed(uint8 episodeId, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _pfpMeta[tokenId] & (1 << episodeId) != 0;
    }

    //// ADMIN OPERATIONS

    function setWarHe4d(IOwnedToken owned) external onlyOwner {
        warHe4d = owned;
        emit SetWarHe4d(address(owned));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBurner(address _burner) external onlyOwner {
        burner = _burner;
        emit SetBurner(_burner);
    }

    function setEpisodeCreator(address creator, bool isCreator)
        external
        onlyOwner
    {
        _walletMeta[creator].isCreator = isCreator;
        emit SetEpisodeCreator(creator, isCreator);
    }

    /// @notice Sets the URI for contract-level metadata
    /// @param _contractURI The contract URI
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(_contractURI);
    }

    /// @notice Set the default EIP-2981 royalty
    /// @dev Can only be called by the owner
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Delete the default EIP-2981 royalty
    /// @dev Can only be called by the owner
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Set the royalty for a specific token
    /// @dev Can only be called by the owner
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Reset the royalty for a specific token
    /// @dev Can only be called by the owner
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /// @notice Configure the foreword mint
    /// @dev Only the owner role can call this function
    /// @param _forewordMintStartDate The start date of the foreword mint
    /// @param _forewordMintDuration The duration of the foreword mint in seconds
    /// @param _forewordWalletMintLimit The max number of foreword tokens that can be minted per wallet
    function configureForewordMint(
        uint40 _forewordMintStartDate,
        uint40 _forewordMintDuration,
        uint8 _forewordWalletMintLimit
    ) external onlyOwner {
        require(
            type(uint40).max - _forewordMintDuration >= _forewordMintStartDate,
            "Invalid duration"
        );
        forewordMintStartDate = _forewordMintStartDate;
        forewordMintEndDate = _forewordMintStartDate + _forewordMintDuration;
        forewordWalletMintLimit = _forewordWalletMintLimit;
        emit ConfigureForeword(
            _forewordMintStartDate,
            forewordMintEndDate,
            _forewordWalletMintLimit
        );
    }

    /// @notice Configure a new episode URI
    /// @dev Only the owner role can call this function
    /// @param id The episode ID
    /// @param _uri The episode URI
    function setURI(uint256 id, string memory _uri) external {
        require(
            _msgSender() == owner() || _walletMeta[_msgSender()].isCreator,
            "Not authorized"
        );
        Episode storage episode = _episodes[id];
        episode.uri = _uri;
        emit URI(_uri, id);
    }

    //// COLLECTION BURNER OPS

    /// @notice Burn a sequence of episodes.
    ///         Reverts if any episode is not owned by the caller.
    /// @dev Only callable by the burner role.
    /// @param ownerId The owner of the episodes to burn
    function burnEpisodes(address ownerId, uint256[] calldata episodeIds)
        external
    {
        require(_msgSender() == burner, "Only burner");
        uint256[] memory amounts = new uint256[](episodeIds.length);
        for (uint256 i = 0; i < episodeIds.length; ++i) {
            --_episodes[i].totalSupply;
            amounts[i] = 1;
        }
        _burnBatch(ownerId, episodeIds, amounts);
    }

    //// PRIVATE

    function _markClaimed(uint256 episodeId, uint256 tokenId) private {
        _pfpMeta[tokenId] |= (1 << episodeId);
    }
}
