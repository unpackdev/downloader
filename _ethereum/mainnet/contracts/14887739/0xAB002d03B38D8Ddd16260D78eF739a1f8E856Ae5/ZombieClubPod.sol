//SPDX-License-Identifier: MIT
/**
▒███████▒ ▒█████   ███▄ ▄███▓ ▄▄▄▄    ██▓▓█████     ▄████▄   ██▓     █    ██  ▄▄▄▄   
▒ ▒ ▒ ▄▀░▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▓██▒▓█   ▀    ▒██▀ ▀█  ▓██▒     ██  ▓██▒▓█████▄ 
░ ▒ ▄▀▒░ ▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██▒▒███      ▒▓█    ▄ ▒██░    ▓██  ▒██░▒██▒ ▄██
  ▄▀▒   ░▒██   ██░▒██    ▒██ ▒██░█▀  ░██░▒▓█  ▄    ▒▓▓▄ ▄██▒▒██░    ▓▓█  ░██░▒██░█▀  
▒███████▒░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓░██░░▒████▒   ▒ ▓███▀ ░░██████▒▒▒█████▓ ░▓█  ▀█▓
░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒░▓  ░░ ▒░ ░   ░ ░▒ ▒  ░░ ▒░▓  ░░▒▓▒ ▒ ▒ ░▒▓███▀▒
░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░  ░      ░▒░▒   ░  ▒ ░ ░ ░  ░     ░  ▒   ░ ░ ▒  ░░░▒░ ░ ░ ▒░▒   ░ 
░ ░ ░ ░ ░░ ░ ░ ▒  ░      ░    ░    ░  ▒ ░   ░      ░          ░ ░    ░░░ ░ ░  ░    ░ 
  ░ ░        ░ ░         ░    ░       ░     ░  ░   ░ ░          ░  ░   ░      ░      
░                                  ░               ░                               ░ 
 
Website: https://zombieclub.io
Twitter: https://twitter.com/get_turned
Discord: https://discord.gg/zombieclub
Github: https://github.com/getTurned

0xEstarriol
 */

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./BitMapsUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./IERC721.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";

import "./FPEMap.sol";

contract ZombieClubPod is Initializable, ERC721Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ERC2981Upgradeable, VRFConsumerBaseV2 {
    using StringsUpgradeable for uint256;

    // Constants and Immutables

    IERC721 immutable public zombieNFT;
    VRFCoordinatorV2Interface immutable public coordinator;

    uint256 constant private ZOMBIECLUB_START_ID = 1;
    uint256 constant private ZOMBIECLUB_QUANTITY = 6666;

    uint96 constant private ROYALTY_NUMERATOR = 666; // 6.66 %

    string public baseURI;

    address public admin;
    

    // State Variables

    uint256 public randomSeed;
    uint64 public subId;
    bytes32 public keyHash;

    bool public lock;

    /// @dev Only configure the immutables here.
    constructor(
        IERC721 _zmobieNFT,
        address _vrfCoordinator
    ) VRFConsumerBaseV2(_vrfCoordinator) initializer {
        zombieNFT = _zmobieNFT;
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }


    modifier onlyAuthorized {
        if(msg.sender != owner()) {
            if (msg.sender != admin) {
                revert("Unauthorized");
            }
        }
        _;
    }

    /// @param subId_ VRF V2 subscription Id
    /// @param keyHash_ VRF V2 keyHash. Different keyHash's have different gas price ceilings
    function initialize(uint64 subId_, bytes32 keyHash_, address royaltyReceiver) external initializer {
        __ERC721_init("ZombiePod Genesis", "ZPG");
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC2981_init();
        subId = subId_;
        keyHash = keyHash_;

        _setDefaultRoyalty(royaltyReceiver, ROYALTY_NUMERATOR); 
    }

    /// @dev Claim the ZombieClubPod NFTs.
    /// @param zombieTokenIds List of tokenIds of ZombieClub Tokens owned by the caller. (excluding the claimed ones)
    function claim(uint16[] calldata zombieTokenIds) external nonReentrant {
        require(!lock, "ZombieClubPod: Cannot claim the token now");
        require(msg.sender == tx.origin, "ZombieClubPod: Only EOA");
        for(uint256 i=0; i < zombieTokenIds.length; i++) {
            uint256 tokenId = zombieTokenIds[i];
            require(zombieNFT.ownerOf(tokenId) == msg.sender, "ZombieClubPod: msg.sender not the nft owner");
            _claimFor(msg.sender, tokenId);
        }
    }

    /*  Administrative Functions */

    function airdropTo(uint16 stardId, uint16 quantity) external onlyAuthorized {
        for(uint256 tokenId=stardId; tokenId < stardId + quantity; tokenId++) {
            address owner = zombieNFT.ownerOf(tokenId);
            _claimFor(owner, tokenId);
        }
    }

    function airdropMultiple(uint16[] calldata tokenIds) external onlyAuthorized {
        for(uint256 i=0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = zombieNFT.ownerOf(tokenId);
            _claimFor(owner, tokenId);
        }
    }

    /// @dev for retriving the tokens that have not been claimed
    function devMint(uint16[] calldata tokenIds, address to) external onlyAuthorized {
        for(uint256 i=0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _claimFor(to, tokenId);
        }
    }

    /// @dev Reveal the ZombieClubPod NFTs.
    function reveal() external onlyAuthorized {
        require(!isRevealed(), "ZombieClubPod: Randomness has been supplied");

        coordinator.requestRandomWords(
            keyHash,
            subId,
            10,  // requestConfirmations
            200000, // callbackGasLimit
            1 // length of the random words
        );
    }

    function setLock(bool lock_) external onlyAuthorized {
        lock = lock_;
    }

    /// @dev Set the new keyHash for the VRF coordinator
    function setKeyHash(bytes32 keyHash_) external onlyAuthorized {
        keyHash = keyHash_;
    }

    function setRoyaltyReceiver(address _receiver) external onlyAuthorized {
        _setDefaultRoyalty(_receiver, ROYALTY_NUMERATOR); 
    }

    /*  Internal Functions */

    function _claimFor(address to, uint256 tokenId) internal{
        require(!isClaimed(tokenId), "ZombieClubPod: NFT has been claimed");
        _safeMint(to, tokenId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(!isRevealed(), "ZombieClubPod: Randomness has been supplied");
        randomSeed = randomWords[0];
    }

    function _unrevealedURI() internal view virtual returns (string memory) {
        return "ipfs://QmVb4stGQubQwZVACS4XFmS2wkKb2ZjtdUttBmphubqeVL";
    }   

    function setBaseURI(string calldata baseUIRI_) external onlyAuthorized {
        baseURI = baseUIRI_;
    }

    function setAdminAccount(address admin_) external onlyOwner {
        admin = admin_;
    }


    /*  View Functions */

    /// @dev Check if the pod belongs to a ZombieClub Token has been claimed.
    /// @param zombieTokenId ZombieClub Token ID
    function isClaimed(uint256 zombieTokenId) public view returns (bool) {
        return _exists(zombieTokenId);
    }

    /// @dev Check if the NFTs have been revealed.
    function isRevealed() public view returns (bool) {
        return randomSeed!=0;
    }

    /// @dev Return actual tokenId of the metadata
    function getActualTokenId(uint256 tokenId) public view returns (uint256 actualTokenId) {
        if(isRevealed()) {
            actualTokenId = ZOMBIECLUB_START_ID + 
                FPEMap.fpeMappingFeistelAuto(tokenId-ZOMBIECLUB_START_ID, randomSeed, ZOMBIECLUB_QUANTITY);
        } else {
            revert("ZombieClubPod: Unrevealed");
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(isRevealed()) {
            uint256 actualTokenId = getActualTokenId(tokenId);
            return string(abi.encodePacked(baseURI, actualTokenId.toString()));
        } else {
            return _unrevealedURI();
        }
        
    }

    /// @dev List all the token IDs of an address. (This function is not designed to be called on chain.)
    function listTokensByOwner(address owner_) public view returns (uint16[] memory) {
        uint16[] memory tokenIds = new uint16[](balanceOf(owner_));
        uint256 index;
        unchecked {
            for(uint256 tokenId=ZOMBIECLUB_START_ID; tokenId < ZOMBIECLUB_START_ID + ZOMBIECLUB_QUANTITY; tokenId++) {
                if(_exists(tokenId)) {
                    if(ownerOf(tokenId) == owner_) {
                        tokenIds[index] = uint16(tokenId);
                        index++;
                    }
                }
            }
        }
        
        return tokenIds;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}