// SPDX-License-Identifier: GPL-3.0

/**
                                                                                                                                                      
                                                                                       
                                
                 ..   8"=,,88,   _.
                  8""=""8'  "88a88'
             .. .;88m a8   ,8"" "8
              "8"'  "88"  A"     8;
                "8,  "8   8  'u'   "8,
                 "8   8,  8,       "8
                  8,  "8, "8,    ___8,
                  "8,  "8, "8mm""""""8m.
                   "8,algo.8"'   ,mm"
                   ,8"  _8"  .lite"
                  ,88P"""""I88con8
                  "'         "much0"
                              "a8,   
                               "m8   
                                 "o8_
                     ,by:jawn.m""i,,r8""  ,johnny,'.
                    m""    . "8.8 I8  ,8"   .  "88
                   i8  . '  ,mi""8I8 ,8 . '  ,8" 88
                   88.' ,mm""    "iain"m,,mm'"    8
                   "8_m""         "I8   ""'
                    "8             I8
                                   I8_ 
                                   I8""
                                   I8
                                  _I8
                                 ""I8
                                   I8     ALGO LITE




*/

pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./IMintable.sol";

/// @author Iain Nash @isiain
/// @dev Contract for Algo Lite Project by @jawn +
/// @custom:warning UNAUDITED: Use at own risk
contract AlgoLite is ERC721, IERC2981, Ownable, IMintable {
    /// Base URI for metadata (immutable)
    string private metadataBase;
    /// Available IDS list
    uint16[] private availableIds;
    /// Mapping of approved minters (can be updated by admin)
    mapping(address => bool) private approvedMinters;
    /// Entropy base
    bytes32 entropyBase;

    /// @param name Name of NFT contract
    /// @param symbol Symbol of NFT contract
    /// @param _metadataBase Base URL of metadata
    /// @param _maxAvailableId Max number that can be minted beyond 0
    /// @param multisigOwner New owner after deploying
    /// @dev Sets up the serial contract with a name, symbol, and an initial allowed creator.
    /// @dev Mints the genesis token to the deployer.
    constructor(
        string memory name,
        string memory symbol,
        string memory _metadataBase,
        uint16 _maxAvailableId,
        address multisigOwner
    ) ERC721(name, symbol) {
        metadataBase = _metadataBase;
        // Create array of avilable ids (not initialized as a gas optimization)
        availableIds = new uint16[](_maxAvailableId);
        // Init entropy
        _updateEntropy();
        // Set new owner
        transferOwnership(multisigOwner);
        // Mint genesis token
        _mint(multisigOwner, 0);
    }

    /// @dev Updates entropy value hash
    function _updateEntropy() internal {
        entropyBase = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                block.coinbase,
                block.difficulty,
                gasleft(),
                tx.gasprice,
                metadataBase
            )
        );
    }

    /// @dev Returns tokenURI for given token that exists
    /// @param tokenId id of token to retrieve metadata for
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NO TOKEN");

        return
            string(
                abi.encodePacked(
                    metadataBase,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    /// @dev Admin owner-only function to update the list of approved minters
    /// @param minter list of addresses that are approved minters
    /// @param isApproved if given minter is approved
    function setIsApprovedMinter(address minter, bool isApproved)
        public
        onlyOwner
    {
        approvedMinters[minter] = isApproved;
    }

    /// @dev Modifier to only allow approved minter to mint pieces
    modifier onlyApprovedMinter() {
        require(
            approvedMinters[msg.sender] || owner() == msg.sender,
            "not approved"
        );
        _;
    }

    /// @dev Authenticated mint function that mints a random available NFT
    /// @param to Address to mint NFT to
    function mint(address to) public override onlyApprovedMinter {
        require(availableIds.length > 0, "Sold out");
        // This updates the entropy base for minting. Fairly simple but should work for this use case.
        _updateEntropy();
        // Get index of ID to mint from available ids
        uint256 swapIndex = uint256(entropyBase) % availableIds.length;
        // Load in new id
        uint256 newId = availableIds[swapIndex];
        // If unset, assume equals index
        if (newId == 0) {
            newId = swapIndex;
        }
        uint16 lastIndex = uint16(availableIds.length - 1);
        uint16 lastId = availableIds[lastIndex];
        if (lastId == 0) {
            lastId = lastIndex;
        }
        // Set last value as swapped index
        availableIds[swapIndex] = lastId;
        // Remove potential value that was minted
        availableIds.pop();

        // Mint token (1-indexed to allow for genesis token to be pre-minted)
        _safeMint(to, newId + 1);
    }

    // Specify owner can be both from mintable (interface) and ownable (parent)
    function owner()
        public
        view
        override(Ownable, IMintable)
        returns (address)
    {
        return super.owner();
    }

    /// @dev Returns 5% royalty to owner
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            owner(),
            // 50 bps = 5% royalty
            (_salePrice * 50) / 10_000
        );
    }

    /// @param interfaceId interface id to match to erc165 standard
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            type(IMintable).interfaceId == interfaceId ||
            type(IERC2981).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
