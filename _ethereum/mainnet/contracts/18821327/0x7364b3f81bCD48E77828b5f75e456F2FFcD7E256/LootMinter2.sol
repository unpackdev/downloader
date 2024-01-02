// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

//                                .__        ___.
//  ____________ _______   ____    |  | _____ \_ |__   ______
//  \_  __ \__  \\_  __ \_/ __ \   |  | \__  \ | __ \ /  ___/
//   |  | \// __ \|  | \/\  ___/   |  |__/ __ \| \_\ \\___ \
//   |__|  (____  /__|    \___  >  |____(____  /___  /____  >
//              \/            \/             \/    \/     \/
//
// Apepe Loot Minter
// the possibilities multiply..
//

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface LootMainInterface {
    struct CollectionConfig {
        address collection;
        uint256 price;
        uint16 usagePerPass;
    }

    struct TokenConfig {
        uint8 mechanism;
        CollectionConfig[] collectionConfigs;
        uint256 limit;
        uint256 startDate;
        uint256 endDate;
    }

    function getTokenConfig(
        uint256 _tokenId
    ) external view returns (TokenConfig memory);

    function getMinted(uint256 _tokenId) external view returns (uint256 count);

    function contractMint(address _to, uint256 _id, uint256 _quantity) external;
}

contract ApepeLootMinter2 is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    LootMainInterface public lootMain;
    IERC721 public genesis;
    IERC721 public zombie;
    bytes32 public merkleRootMint1;
    mapping(address => uint256) public claimedAmountsMint1;
    uint256[50] __gap;

    error StartDateNotSet();
    error MintNotStarted();
    error UnauthorizedCaller(address caller);
    error ExceededAllowedLimit(uint256 requested, uint256 allowed);
    error InvalidMerkleProof();

    event RelicCasted(address indexed owner, uint256 quantity);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _lootMain,
        address _genesis,
        address _zombie
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        lootMain = LootMainInterface(_lootMain);
        genesis = IERC721(_genesis);
        zombie = IERC721(_zombie);
    }

    function setMerkleRootMint1(bytes32 _root) public onlyOwner {
        merkleRootMint1 = _root;
    }

    function mint1(
        bytes32[] calldata _merkleProof,
        address _wallet,
        uint256 _allocationAmount,
        uint256 _quantity
    ) public whenNotPaused {
        LootMainInterface.TokenConfig memory tokenConfig = lootMain
            .getTokenConfig(1);


        if (tokenConfig.startDate == 0) {
            revert StartDateNotSet();
        }
        
        if (tokenConfig.startDate > block.timestamp) {
            revert MintNotStarted();
        }
        
        if (_wallet != msg.sender) {
            revert UnauthorizedCaller(msg.sender);
        }

        if (claimedAmountsMint1[msg.sender] + _quantity > _allocationAmount) {
            revert ExceededAllowedLimit(claimedAmountsMint1[msg.sender] + _quantity , _allocationAmount);
        }
    
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_wallet, _allocationAmount))));

        if (!MerkleProofUpgradeable.verify(_merkleProof, merkleRootMint1, leaf)) {
            revert InvalidMerkleProof();
        }
        
        claimedAmountsMint1[msg.sender] += _quantity;
        emit RelicCasted(msg.sender, _quantity);
        lootMain.contractMint(_wallet, 1, _quantity);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    // required by upgradable contract
    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}
}
