// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

/// @title Anime Metaverse Reward Smart Contract
/// @author LiquidX
/// @notice This smart contract is used for reward on Gachapon event

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./AmvUtils.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();

/// @notice Thrown when airdrop less than 1 item
error InvalidAirdropAmount();

/// @notice Thrown when address is not included in Burner list
error InvalidBurner();

/// @notice Thrown when address is not included in Minter list
/// @dev Use this custom error on revert function whenever checking minter address
error InvalidMinter();

/// @notice Thrown when token ID is not matched with the existing one
error InvalidTokenId();

/// @notice Thrown when token type is not matched with the existing one
error InvalidTokenType();

/// @notice Thrown when airdrop beyond the maximum limit
/// @param amount The amount of item that would be airdropped
error MaxAirdropLimitExceeded(uint256 amount);

/// @notice Thrown when token supply already reaches its maximum limit
/// @param range  Amount of token that would be minted
error MintAmountForTokenTypeExceeded(uint256 range);

/// @notice Thrown when address is not allowed to burn the token
error NotAllowedToBurn();

/// @notice Thrown when is not able to mint digital merchandise
error ClaimingMerchandiseDeactivated();

contract AnimeMetaverseReward is
    ERC1155,
    Ownable,
    AmvUtils,
    IAnimeMetaverseReward
{
    uint256 public constant MERCH_TOKEN_TYPE = 1;
    uint256 public constant GIFT_BOX_TOKEN_TYPE = 2;
    uint256 public constant AM_ITEM_TOKEN_TYPE = 3;
    uint256 public constant COMPONENT_TOKEN_TYPE = 4;
    uint256 public constant BOOSTER_TOKEN_TYPE = 5;
    uint256 public constant DIGITAL_MERCH_TOKEN_TYPE = 6;

    /// @notice Information related to token
    /// @dev Every token must have these informations to
    ///      track down their distribution easily
    /// @param startIndex The index represents token ID so startIndex would tell
    ///                   that a particular token type has token ID within specific
    ///                   range starting from this index
    /// @param maxSupply Maximum supply for specific token type
    /// @param totalSupply Total amount of token that has been minted. It should not
    ///                    exceeds the maximum supply.
    struct TokenInfo {
        uint256 startIndex;
        uint256 maxSupply;
        uint256 totalSupply;
    }

    /// @dev A list of available token
    /// @custom:key The token type represented as number
    /// @custom:value The token information derived from TokenInfo struct
    mapping(uint256 => TokenInfo) tokenCollection;

    /// @dev This would be used to tell the start index of specified token
    ///      and would be overridden in the setTokenInfo function
    uint256 collectionStartIndex = 1;

    /// @dev Track down how many token type exists in this contract.
    ///      The number would increase everytime setTokenInfo function
    ///      is called
    uint256 totalTokenType = 0;

    /// @notice List of address that could mint the token
    /// @dev Use this mapping to set permission on who could mint the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public minterList;

    /// @notice List of address that could burn the token
    /// @dev Use this mapping to set permission on who could force burn the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(uint256 => mapping(address => bool)) public burnerList;

    /// @notice How many items are supplied per token ID
    /// @dev This supply represents neither total supply nor maximum supply.
    ///      It's telling how many item could be owned per token ID. Let's
    ///      say item with token ID 233 has supply 1, that means there is
    ///      only 1 item with token ID 233 and someone could only own
    ///      1 item with token ID 233, not more.
    uint256 public constant SUPPLY_PER_TOKENID = 1;

    bool public claimMerchandiseActive = false;

    /// @notice Maximum limit for airdropping token in one transaction
    uint256 public MAX_AIRDROP_LIMIT = 100;

    /// @notice Base URL to store off-chain information
    /// @dev This variable could be used to store URL for the token metadata
    string public baseURI = "";

    /// @notice Check whether address is valid
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check the token type
    /// @param tokenType The token type that is represented in unsigned integer
    modifier validTokenType(uint256 tokenType) {
        if (tokenType < 1 || tokenType > totalTokenType) {
            revert InvalidTokenType();
        }
        _;
    }

    /// @notice Check the airdrop amount
    /// @param amount Amount of token that would be airdropped
    modifier validAirdropAmount(uint256 amount) {
        if (amount > MAX_AIRDROP_LIMIT) {
            revert MaxAirdropLimitExceeded(amount);
        }
        if (amount == 0) {
            revert InvalidAirdropAmount();
        }
        _;
    }

    /// @notice Check whether an address has permission to mint
    modifier onlyMinter() {
        if (
            !minterList[msg.sender] &&
            msg.sender != owner() &&
            msg.sender != address(this)
        ) {
            revert InvalidMinter();
        }
        _;
    }

    /// @notice Check whether an address has permission to force burn
    modifier onlyBurner(uint256 id) {
        if (!isValidBurner(id)) {
            revert InvalidBurner();
        }
        _;
    }

    /// @notice There's a mint transaction happen
    /// @dev Emit event when calling mintBatch function
    /// @param activityId Gachapon activity ID
    /// @param minter Address who calls the function
    /// @param to Address who receives the token
    /// @param ids Item token ID
    /// @param amounts Amount of item that is minted
    event MintBatch(
        uint256 activityId,
        address minter,
        address to,
        uint256[] ids,
        uint256[] amounts
    );

    /// @notice There's a token being burned
    /// @dev Emits event when forceBurn function is called
    /// @param burner Burner address
    /// @param Owner Token owner
    /// @param tokenId Token ID that is being burned
    /// @param amount Amount of token that is being burned

    event ForceBurn(
        address burner,
        address Owner,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice There's a digital merchandise
    /// @dev Emit event when digital merch is minted
    /// @param minter Address who mints digital merchandise
    /// @param to Address who receiveses digital merchandise
    /// @param id Token ID of the digital merchandise
    /// @param amount Amount of the digital merchandise that is minted
    event MintDigitalMerch(
        address minter,
        address to,
        uint256 id,
        uint256 amount
    );

    /// @notice Sets maximum supply and token ID for all tokens
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    constructor() ERC1155("") {
        setTokenInfo(100000);
        setTokenInfo(100000);
        setTokenInfo(100000);
        setTokenInfo(100000);
        setTokenInfo(100000);
        setTokenInfo(100000);
    }

    /// @notice Sets information about specific token
    /// @dev It will set maximum supply, start index, and initial total supply
    /// @param maximumSupply The maximum supply for the token
    function setTokenInfo(uint256 maximumSupply) private {
        totalTokenType++;
        tokenCollection[totalTokenType] = TokenInfo({
            startIndex: collectionStartIndex,
            maxSupply: maximumSupply,
            totalSupply: 0
        });
        collectionStartIndex += maximumSupply;
    }

    /// @notice Set maximum airdrop limit
    /// @dev This function can only be executed by the contract owner
    /// @param _airdropLimit A new maximum limit in unsigned integer
    function setMaxAirdropLimit(uint256 _airdropLimit) external onlyOwner {
        require(_airdropLimit >= 1, "Can not set airdropLimit less than 1.");
        require(
            _airdropLimit <= 10000,
            "Can not set airdropLimit more than the total supply."
        );
        MAX_AIRDROP_LIMIT = _airdropLimit;
    }

    /// @notice Registers an address and sets a permission to mint
    /// @dev This function can only be executed by the contract owner
    /// @param minter A valid ethereum address
    /// @param _flag The permission to mint. 'true' means allowed
    function setMinterAddress(address minter, bool _flag)
        external
        onlyOwner
        validAddress(minter)
    {
        minterList[minter] = _flag;
    }

    function toggleMerchandiseClaim(bool _flag) external onlyOwner {
        claimMerchandiseActive = _flag;
    }

    /// @notice Registers an address and sets a permission to force burn specific token
    /// @dev This function can only be executed by the contract owner
    /// @param tokenType The token type that can be burned by this address
    /// @param burner A valid ethereum address
    /// @param _flag The permission to force burn. 'true' means allowed
    function setBurnerAddress(
        uint256 tokenType,
        address burner,
        bool _flag
    ) external onlyOwner validAddress(burner) validTokenType(tokenType) {
        burnerList[tokenType][burner] = _flag;
    }

    /// @notice Mints token in batch
    /// @dev This function will increase total supply for the token type that
    ///      is minted. To check the token balance that user own, it will need
    ///      to iterate the token ID since each token ID only has either 1 or 0
    ///      balance for every token type.
    ///      Only allowed minter address that could run this function
    /// @param _activityId Gachapon activity ID
    /// @param _to The address that will receive the token
    /// @param _tokenType The token type that will be minted
    /// @param _amount Amount of token that will be minted
    /// @param _data _
    function mintBatch(
        uint256 _activityId,
        address _to,
        uint256 _tokenType,
        uint256 _amount,
        bytes memory _data
    )
        external
        onlyMinter
        validAddress(_to)
        validTokenType(_tokenType)
        validAirdropAmount(_amount)
    {
        if (_tokenType == DIGITAL_MERCH_TOKEN_TYPE) {
            revert InvalidTokenType();
        }
        uint256[] memory ids = new uint256[](_amount);
        uint256[] memory amounts = new uint256[](_amount);

        uint256 tokenIdStartIndex = tokenCollection[_tokenType].startIndex +
            tokenCollection[_tokenType].totalSupply;
        if (
            tokenCollection[_tokenType].totalSupply + _amount >
            tokenCollection[_tokenType].maxSupply
        ) {
            revert MintAmountForTokenTypeExceeded(_amount);
        }
        tokenCollection[_tokenType].totalSupply += _amount;

        for (uint256 j = 0; j < _amount; j++) {
            ids[j] = tokenIdStartIndex + j;
            amounts[j] = SUPPLY_PER_TOKENID;
        }

        _mintBatch(_to, ids, amounts, _data);
        emit MintBatch(_activityId, msg.sender, _to, ids, amounts);
    }

    /// @notice Mints digital merch
    /// @dev This internal function is only called when someone burns a merchandise NFT.
    ///      Then this function will mint a digital merchandise NFT to the holder of
    ///      that merchandise NFT
    /// @param to Address who will receive the Digital Merchandise
    /// @param merchTokenId The token ID for Digital Merchandise
    function mintDigitalMerch(address to, uint256 merchTokenId) internal {
        uint256 digitalMerchTokenId = merchTokenId +
            tokenCollection[DIGITAL_MERCH_TOKEN_TYPE].startIndex -
            1;
        _mint(to, digitalMerchTokenId, SUPPLY_PER_TOKENID, "");
        tokenCollection[DIGITAL_MERCH_TOKEN_TYPE].totalSupply++;
        emit MintDigitalMerch(msg.sender, to, merchTokenId, SUPPLY_PER_TOKENID);
    }

    /// @notice Burns token
    /// @dev Only the owner of the token can burn his/her own token
    /// @param account The address for the caller function
    /// @param id The token ID to burn
    function claimMerchandise(
        address account,
        uint256 id
    ) external validAddress(account) {
        if (!claimMerchandiseActive) {
            revert ClaimingMerchandiseDeactivated();
        }
        if (
            id >= tokenCollection[MERCH_TOKEN_TYPE].startIndex &&
            id <
            tokenCollection[MERCH_TOKEN_TYPE].startIndex +
                tokenCollection[MERCH_TOKEN_TYPE].maxSupply
        ) {
            require(
                account == _msgSender() ||
                    isApprovedForAll(account, _msgSender()),
                "ERC1155: caller is not token owner nor approved"
            );

            _burn(account, id, SUPPLY_PER_TOKENID);
            mintDigitalMerch(account, id);
        } else {
            revert NotAllowedToBurn();
        }
    }

    /// @notice Burns specific token from other address
    /// @dev This smart contract sets burner addresses for every type of token
    /// who are allowed to burn the token. this addresses will be set by owner.
    /// Only registered address in burner list can execute this function
    /// @param account The owner address of the token
    /// @param id The token ID
    function forceBurn(address account, uint256 id)
        external
        validAddress(account)
        onlyBurner(id)
    {
        _burn(account, id, SUPPLY_PER_TOKENID);
        emit ForceBurn(msg.sender, account, id, SUPPLY_PER_TOKENID);
    }

    /// @notice Checks whether the caller function can burn specific token
    /// @param id The token ID to burn
    function isValidBurner(uint256 id) public view returns (bool) {
        return burnerList[getTokenType(id)][msg.sender];
    }

    /// @notice Checks the token type for specific token ID
    /// @dev It will return an integer that represents the token type.
    /// @param tokenId Token ID based on range for each token type
    function getTokenType(uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 1; i <= totalTokenType; i++) {
            if (
                tokenId >= tokenCollection[i].startIndex &&
                tokenId <
                tokenCollection[i].startIndex + tokenCollection[i].maxSupply
            ) return i;
        }
        revert InvalidTokenId();
    }

    /// @notice Set base URL for storing off-chain information
    /// @param newuri A valid URL
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    /// @notice Appends token ID to base URL
    /// @param tokenId The token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, intToString(tokenId)))
                : "";
    }

    /// @notice The maximum supply for specific token type
    /// @param tokenType Number that represents the token type
    function maxSupply(uint256 tokenType)
        external
        view
        validTokenType(tokenType)
        returns (uint256)
    {
        return tokenCollection[tokenType].maxSupply;
    }

    /// @notice The total supply for specific token type
    /// @param tokenType Number that represents the token type
    function totalSupply(uint256 tokenType)
        external
        view
        validTokenType(tokenType)
        returns (uint256 supply)
    {
        supply = tokenCollection[tokenType].totalSupply;
    }

    /// @notice The start index for specific token type
    /// @param tokenType Number that represents the token type
    function startIndex(uint256 tokenType)
        external
        view
        validTokenType(tokenType)
        returns (uint256 supply)
    {
        supply = tokenCollection[tokenType].startIndex;
    }
}
