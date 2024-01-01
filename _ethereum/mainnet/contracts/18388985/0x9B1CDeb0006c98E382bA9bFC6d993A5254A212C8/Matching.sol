// SPDX-License-Identifier: MIT
/***
 *              _____                _____                    _____                    _____            _____                    _____          
 *             /\    \              /\    \                  /\    \                  /\    \          /\    \                  /\    \         
 *            /::\    \            /::\    \                /::\    \                /::\____\        /::\    \                /::\    \        
 *           /::::\    \           \:::\    \              /::::\    \              /:::/    /       /::::\    \               \:::\    \       
 *          /::::::\    \           \:::\    \            /::::::\    \            /:::/    /       /::::::\    \               \:::\    \      
 *         /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/    /       /:::/\:::\    \               \:::\    \     
 *        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/    /       /:::/__\:::\    \               \:::\    \    
 *        \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \      /:::/    /        \:::\   \:::\    \              /::::\    \   
 *      ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    /:::/    /       ___\:::\   \:::\    \    ____    /::::::\    \  
 *     /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/    /       /\   \:::\   \:::\    \  /\   \  /:::/\:::\    \ 
 *    /::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/____/       /::\   \:::\   \:::\____\/::\   \/:::/  \:::\____\
 *    \:::\   \:::\   \::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\    \       \:::\   \:::\   \::/    /\:::\  /:::/    \::/    /
 *     \:::\   \:::\   \/____/   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/    / \/____/ 
 *      \:::\   \:::\    \      /:::/    /            \:::\   \:::\    \       \:::\    \       \:::\   \:::\    \       \::::::/    /          
 *       \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\       \:::\    \       \:::\   \:::\____\       \::::/____/           
 *        \:::\  /:::/    /    \::/    /                \:::\   \::/    /        \:::\    \       \:::\  /:::/    /        \:::\    \           
 *         \:::\/:::/    /      \/____/                  \:::\   \/____/          \:::\    \       \:::\/:::/    /          \:::\    \          
 *          \::::::/    /                                 \:::\    \               \:::\    \       \::::::/    /            \:::\    \         
 *           \::::/    /                                   \:::\____\               \:::\____\       \::::/    /              \:::\____\        
 *            \::/    /                                     \::/    /                \::/    /        \::/    /                \::/    /        
 *             \/____/                                       \/____/                  \/____/          \/____/                  \/____/         
 *                                                                                                                                              
 */

pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IRoleManager.sol";
import "./INFTBase.sol";
import "./ILandNFT.sol";
import "./IBuildingNFT.sol";
import "./STELSI.sol";

contract Matching is Initializable, UUPSUpgradeable, ContextUpgradeable {

    using SafeMathUpgradeable for uint256;

    IRoleManager public roleManager;
    INFTBase public nftBase;
    ILandNFT public landNft;
    IBuildingNFT public buildingNft;
    STELSI public stls;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    // Duration of matching locked (in seconds)
    uint256 public duration;
    uint256 public matchingFee;
    address public teamAddr;

    struct Match {
        uint256 buildingId;
        uint256 endTime;
    }

    mapping (uint256 => Match) public matchs;  //Land id => Match
    mapping (uint256 => uint256) public matchBuildings;  //Building id => Land id

    event Matched(uint256 indexed landId, uint256 indexed buildingId, uint256 endTime);
    event UnMatched(uint256 indexed landId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoleManager _roleManager, INFTBase _nftBase, ILandNFT _landNft, IBuildingNFT _buildingNft,
        STELSI _stls) initializer public {
        __UUPSUpgradeable_init();

        roleManager = IRoleManager(_roleManager);
        nftBase = INFTBase(_nftBase);
        landNft = ILandNFT(_landNft);
        buildingNft = IBuildingNFT(_buildingNft);

        stls = _stls;
        
        duration = 30 days;
        matchingFee = 100e18; //100 STLS
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}

    modifier onlyRole(bytes32 role) {
        require(roleManager.hasRole(role, _msgSender()),"Matching/has_no_role");
        _;
    }

    /**
     * @dev Set duration time
     */ 
    function setDuration(uint256 _duration) public onlyRole(ADMIN_ROLE) {
        duration = _duration;
    }

    /**
     * @dev Set matching fee
     */ 
    function setMatchingFee(uint256 _matchingFee) public onlyRole(ADMIN_ROLE) {
        matchingFee = _matchingFee;
    }
    
    /**
     * @dev Set team address
     */ 
    function setTeamAddress(address _teamAddr) public onlyRole(ADMIN_ROLE) {
        teamAddr = _teamAddr;
    }
    
    /**
     * @dev Get matching check
     */ 
    function isMatching(uint256 _landId) public view returns (bool) {
        return matchs[_landId].buildingId > 0 ? true : false;
    }

    /**
     * @dev matching : 건설
     * 
     * Requirements:
     * 
     *    land -> building
     *    land 보유자 실행
     * 
     * Event : Matched
     */
    function matching(uint256 _landId, uint256 _buildingId) public {
        require(nftBase.balanceOf(_msgSender(), _landId) > 0,"Matching/nft_is_0");
        require(matchs[_landId].buildingId == 0,"Matching/already_matching_land");
        require(matchBuildings[_buildingId] == 0,"Matching/already_matching_building");
        
        ILandNFT.NFTInfo memory tempLandNft = landNft.getNFT(_landId);
        IBuildingNFT.NFTInfo memory tempBuildingNft = buildingNft.getNFT(_buildingId);

        require(tempLandNft.isleId == tempBuildingNft.isleId 
            && keccak256(abi.encodePacked(tempLandNft.usage)) == keccak256(abi.encodePacked(tempBuildingNft.usage))
            && tempLandNft.scale == tempBuildingNft.scale
            && keccak256(abi.encodePacked(tempLandNft.form)) == keccak256(abi.encodePacked(tempBuildingNft.form))
            ,"Matching/diff_standard");
        
        //get fee
        require(matchingFee <= stls.allowance(_msgSender(), address(this)),"Matching/not_allowance");
        require(matchingFee <= stls.balanceOf(_msgSender()),"Matching/insufficient_balance");
        stls.transferFrom(_msgSender(), teamAddr, matchingFee);

        matchs[_landId].buildingId = _buildingId;
        matchs[_landId].endTime = block.timestamp.add(duration);
        matchBuildings[_buildingId] = _landId;

        emit Matched(_landId, _buildingId, matchs[_landId].endTime);
    }

    /**
     * @dev unMatching : 철거
     * 
     * Requirements:
     * 
     *    land 보유자 실행
     * 
     * Event : UnMatched
     */
    function unMatching(uint256 _landId) public {
        require(nftBase.balanceOf(_msgSender(), _landId) > 0,"Matching/nft_is_0");
        require(matchs[_landId].endTime < block.timestamp,"Matching/time_left");
        require(matchs[_landId].buildingId > 0,"Matching/not_matching");
        
        matchBuildings[matchs[_landId].buildingId] = 0;
        matchs[_landId].buildingId = 0;
        matchs[_landId].endTime = 0;

        emit UnMatched(_landId);
    }
}