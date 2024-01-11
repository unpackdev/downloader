//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Collections.sol";
import "./AdminManager.sol";
import "./IBredStrain.sol";
import "./IRaks.sol";

contract Staking is
    Initializable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminManagerUpgradable
{
    using Collections for Collections.LinkedList;
    uint256 public constant PLOT_ID = 0;

    IERC1155Upgradeable public _plotToken;
    IERC721Upgradeable public _strainToken;
    IBredStrain public _bredStrainToken;
    IRaks public _raksToken;

    uint256 public _baseCapacity;
    uint256 public _plotCapacity;
    uint256 public _accrualTime;

    struct StakerData {
        uint256 plotBalances;
        uint256 strainBalances;
        uint256 claims;
        uint256 lastClaims;
        Collections.LinkedList pendingClaims;
    }

    struct StakedResources {
        uint256 plotBalances;
        uint256 strainBalances;
        uint256 claims;
        uint256 lastClaims;
    }

    mapping(uint256 => address) public _strainOwners;
    mapping(uint256 => address) public _bredStrainOwners;
    mapping(address => StakerData) private _stakersData;
    mapping(uint256 => uint256) public _raksPerSecondCache;
    mapping(uint256 => bool) public _spentBredStrains;

    bool private _paused;

    function initialize(
        address plotToken,
        address strainToken,
        address bredStrainToken,
        address raksToken
    ) public initializer {
        // Already called from V1, removing code to reduce deployment cost
        // __ERC1155Holder_init();
        // __ERC721Holder_init();
        // __ReentrancyGuard_init();
        // __AdminManager_init();
        // _plotToken = IERC1155Upgradeable(plotToken);
        // _strainToken = IERC721Upgradeable(strainToken);
        // _bredStrainToken = IBredStrain(bredStrainToken);
        // _raksToken = IRaks(raksToken);
    }

    function setPlotToken(address plotTokenAddress) external onlyAdmin {
        _plotToken = IERC1155Upgradeable(plotTokenAddress);
    }

    function setStrainToken(address strainTokenAddress) external onlyAdmin {
        _strainToken = IERC721Upgradeable(strainTokenAddress);
    }

    function setBredStrainToken(address bredStrainTokenAddress)
        external
        onlyAdmin
    {
        _bredStrainToken = IBredStrain(bredStrainTokenAddress);
    }

    function setRaksToken(address raksTokenAddress) external onlyAdmin {
        _raksToken = IRaks(raksTokenAddress);
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function pause() external whenNotPaused onlyAdmin {
        _paused = true;
    }

    function unpause() external whenPaused onlyAdmin {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
}
