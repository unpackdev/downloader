// SPDX-License-Identifier: MIT
/**
  __  __              _   _                          _     _____                ____  
 |  \/  |            | | (_)                        | |   |  __ \      /\      / __ \ 
 | \  / |   ___    __| |  _    ___  __   __   __ _  | |   | |  | |    /  \    | |  | |
 | |\/| |  / _ \  / _` | | |  / _ \ \ \ / /  / _` | | |   | |  | |   / /\ \   | |  | |
 | |  | | |  __/ | (_| | | | |  __/  \ V /  | (_| | | |   | |__| |  / ____ \  | |__| |
 |_|  |_|  \___|  \__,_| |_|  \___|   \_/    \__,_| |_|   |_____/  /_/    \_\  \____/ 
                                                                                      
 */
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./VRFConsumerBase.sol";

import "./ERC721PsiRandomSeedRevealBurnableUpgradeable.sol";

import "./MedievalAccessControlled.sol";
import "./IProxyRegistry.sol";
import "./IMedievalNFT.sol";
import "./Traits.sol";


contract MedievalNFT is Initializable, MedievalAccessControlled, IMedievalNFT, ERC721PsiRandomSeedRevealBurnableUpgradeable {
    bytes32 private constant NFT_MINTER_ROLE = keccak256("NFT_MINTER_ROLE");

    using Traits for uint256;

    // Chainlink
    bytes32 immutable public keyHash;
    uint64 immutable public subscriptionId;

    uint256 public levelCap;
    
    mapping(uint256 => string) public tokenName; //reserved
    mapping(uint256 => uint256) _tokenLevel;

    struct OccupationCDF {
        uint32 reserved;
        uint16 occupation1;
        uint16 occupation1CDF;
        uint16 occupation2;
        uint16 occupation2CDF;
        uint16 occupation3;
        uint16 occupation3CDF;
    }

    mapping(uint256 => OccupationCDF) public genOccupationCDF;


    function initialize(
        address _controlCenter
    ) initializer virtual public {
        __ERC721Psi_init("Medieval Adventurer", "ADVENTURER");
        _setControlCenter(_controlCenter, tx.origin); 
        levelCap = 5; //TODO
    }

    //TODO
    function _baseURI() internal pure override returns (string memory) {
        return "https://medieval-backend.herokuapp.com/api/metadata/";
    }

    function tokenLevel(uint256 tokenId) public view returns (uint256 level){
        level = _tokenLevel[tokenId] + 1;
    }

    function tokenOccupation(uint256 tokenId) public view virtual returns (uint16 occupation) {
        OccupationCDF memory cdf = genOccupationCDF[_tokenGen(tokenId)];
        require(cdf.occupation1 != 0, "Uninitialized CDF");
        uint16 _seed = uint16(seed(tokenId));

        if(_seed <= cdf.occupation1CDF) {
            occupation = cdf.occupation1;
        } else if(_seed <= cdf.occupation2CDF) {
            occupation = cdf.occupation2;
        } else if(_seed <= cdf.occupation3CDF) {
            occupation = cdf.occupation3;
        } else {
            revert();
        }
    }

    /// @param to The address that would receive the NFT.
    /// @param quantity Amount of token to be minted.
    function mint(address to, uint256 quantity) external override onlyRole(NFT_MINTER_ROLE) {
        _safeMint(to, quantity);
    }

    function setName(uint256 tokenId, string calldata name) public pure {
        revert("Not implemented! Stay tuned!");
    }

    function strength(uint256 tokenId) public virtual view returns(uint256){
        return seed(tokenId).strength(tokenLevel(tokenId));
    }

    function house(uint256 tokenId) public view returns(uint256){
        return seed(tokenId).house();
    }

    function _burn(uint256 _tokenId) internal override {
        delete _tokenLevel[_tokenId];
        delete tokenName[_tokenId];
        super._burn(_tokenId);
    }

    /// Burn the NFTs to upgrade a NFT;
    /// @param upgradeTokenId ID of the NFT to be upgraded.
    /// @param materialTokenIds IDs of the NFT used as the material. The NFTs in the list will be burned.
    function upgradeLevel(uint256 upgradeTokenId, uint256[] calldata materialTokenIds) external {
        require(ownerOf(upgradeTokenId) == msg.sender, "Not NFT Owener!");
        
        // Burn the NFTs.
        for(uint256 i=0; i < materialTokenIds.length; i++){
            uint256 tokenIdToBurn = materialTokenIds[i];
            require(tokenIdToBurn != upgradeTokenId);
            require(ownerOf(tokenIdToBurn) == msg.sender, "Not NFT Owener!");
            _burn(tokenIdToBurn);
        }

        _tokenLevel[upgradeTokenId] += materialTokenIds.length;
        require(_tokenLevel[upgradeTokenId] < levelCap, "Exceed the level cap!");
    }

    function setLevelCap(uint256 _cap) external onlyAdmin {
        levelCap = _cap;
    }

    function setRandomOccupation(
        uint256 gen,
        uint16 occupation1,
        uint16 occupation1CDF,
        uint16 occupation2,
        uint16 occupation2CDF,
        uint16 occupation3,
        uint16 occupation3CDF
        ) external onlyAdmin {
        
        OccupationCDF memory _occupationCDF;

        _occupationCDF.occupation1 = occupation1;
        _occupationCDF.occupation2 = occupation2;
        _occupationCDF.occupation3 = occupation3;
        _occupationCDF.occupation1CDF = occupation1CDF;
        _occupationCDF.occupation2CDF = occupation2CDF;
        _occupationCDF.occupation3CDF = occupation3CDF;

        genOccupationCDF[gen] = _occupationCDF;
    }

    function generation(uint256 tokenId) view public returns (uint256) {
        require(_exists(tokenId));
        return _tokenGen(tokenId);
    }

    // Called by the governanace to reveal the seed of the NFT.
    function reveal() external onlyAdmin {
        _reveal();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) ERC721PsiRandomSeedRevealUpgradeable(
            _vrfV2Coordinator,
            200000,
            10
        ) initializer {
            keyHash = keyHash_;
            subscriptionId = subscriptionId_;
    }

    // For opensea management.
    function owner() public view virtual returns (address) {
        return controlCenter.addressBook(
            keccak256("OPENSEA_OWNER_ID")
        );
    }

    /** 
        @dev Override the function to provide the corrosponding keyHash for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/vrf-contracts/
     */
    function _keyHash() internal view override returns (bytes32) {
        return keyHash;
    }
    
    /** 
        @dev Override the function to provide the corrosponding subscription id for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/get-a-random-number/#create-and-fund-a-subscription
     */
    function _subscriptionId() internal view override returns (uint64) {
        return subscriptionId;
    }
}