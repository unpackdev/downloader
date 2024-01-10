//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./console.sol";
import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./CountersUpgradeable.sol";

abstract contract MaterialsContract {
    function ownerOf(uint256 tokenId) public virtual returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);
}

contract ForgeV1 is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    MaterialsContract public materialsContract;
    CountersUpgradeable.Counter public tokenIds;
    address public CUSTODY_WALLET;
    string public BASE_URI;
    mapping(uint32 => uint32[]) public tokenIdToMaterialsTokenIds;
    uint8[] public materialTokenTypes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    event WeaponForged(address minter, uint256 token_id, uint32[]);

    function initialize(
        address materialsAddress,
        address custodyWallet,
        string memory _baseUri
    ) public initializer {
        materialsContract = MaterialsContract(materialsAddress);
        BASE_URI = _baseUri;
        CUSTODY_WALLET = custodyWallet;
        __ERC721_init("Sky Crucible", "SKYCWEAPON");
        __Pausable_init();
        __Ownable_init();
        _pause();
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setCustodyWallet(address _custodyWallet) public onlyOwner {
        CUSTODY_WALLET = _custodyWallet;
    }

    function setMaterialsContract(address materialsAddress) public onlyOwner {
        materialsContract = MaterialsContract(materialsAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function version() public pure virtual returns (string memory) {
        return "v1";
    }

    function getTokenMaterialIds(uint32 index) public view returns (uint32[] memory) {
        return tokenIdToMaterialsTokenIds[index];
    }

    function setMaterialTypes(uint32 start, uint8[] calldata _materialTokenTypes) external {
        require(start == materialTokenTypes.length, "Start index must equal the length of the array.");

        for (uint16 i = 0; i < _materialTokenTypes.length; i += 1) {
            materialTokenTypes.push(_materialTokenTypes[i]);
        }
    }

    function getMaterialTypes() public view returns (uint8[] memory) {
        return materialTokenTypes;
    }

    function getMaterialType(uint32 index) public view returns (uint8) {
        return materialTokenTypes[index];
    }

    function forge(uint32[] memory _materials)
        public
        isApproved
        sufficientMaterials(_materials)
        validMaterialSelection(_materials)
        materialsOwnedBySender(_materials)
        whenNotPaused
    {
        transferMaterials(_materials);
        // Increment the token id, and mint the forged weapon token.
        uint256 currentTokenId = tokenIds.current();

        // Mapping between materials and the new weapon
        tokenIdToMaterialsTokenIds[uint32(currentTokenId)] = _materials;

        // Mint
        _safeMint(msg.sender, currentTokenId);

        emit WeaponForged(msg.sender, currentTokenId, _materials);
        // Increment token counter
        tokenIds.increment();
    }

    function transferMaterials(uint32[] memory _materials) internal {
        // Transfer the input tokens to the contract
        for (uint8 i = 0; i < _materials.length; i += 1) {
            materialsContract.safeTransferFrom(msg.sender, address(CUSTODY_WALLET), _materials[i]);
        }
    }


    modifier isApproved() {
        // Check approval on the Materials contract
        require(materialsContract.isApprovedForAll(msg.sender, address(this)), "Operator not approved.");
        _;
    }

    modifier sufficientMaterials(uint32[] memory _materials) {
        // Check input length is valid
        require(_materials.length >= 3 && _materials.length <= 5, "Materials length is < 3 or > 5.");
        _;
    }

    modifier validMaterialSelection(uint32[] memory _materials) {
        // Check inputs at each index are the valid token type
        require(getMaterialType(_materials[0]) == 1, "Token at index 0 must be a weapon.");
        require(getMaterialType(_materials[1]) == 2, "Token at index 1 must be an ore.");
        require(getMaterialType(_materials[2]) == 3, "Token at index 2 must be an orb.");

        if (_materials.length > 3) {
            require(getMaterialType(_materials[3]) == 3, "Token at index 3 must be an orb.");
        }

        if (_materials.length > 4) {
            require(getMaterialType(_materials[4]) == 3, "Token at index 4 must be an orb.");
        }
        _;
    }

    modifier materialsOwnedBySender(uint32[] memory _materials) {
        // Check inputs are all owned by the msg.sender
        require(msg.sender == materialsContract.ownerOf(_materials[0]), "Tokens not all owned by sender.");
        require(msg.sender == materialsContract.ownerOf(_materials[1]), "Tokens not all owned by sender.");
        require(msg.sender == materialsContract.ownerOf(_materials[2]), "Tokens not all owned by sender.");

        if (_materials.length > 3) {
            require(msg.sender == materialsContract.ownerOf(_materials[3]), "Tokens not all owned by sender.");
        }
        if (_materials.length > 4) {
            require(msg.sender == materialsContract.ownerOf(_materials[4]), "Tokens not all owned by sender.");
        }
        _;
    }
}
