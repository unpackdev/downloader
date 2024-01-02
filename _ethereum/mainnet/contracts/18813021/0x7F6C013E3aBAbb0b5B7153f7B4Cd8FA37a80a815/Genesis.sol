// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Counters.sol";
import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./MerkleProof.sol";
// import "./StringsUpgradeable.sol";
import "./IERC4906Upgradeable.sol";

contract Genesis is Initializable, ERC721Upgradeable, AccessControlUpgradeable, IERC4906Upgradeable, IERC1155ReceiverUpgradeable {
    using Counters for Counters.Counter;

    struct Accessory {
        address contractAddr;
        uint256 accessoryId;
    }

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public whitelistedContracts;
    mapping(uint256 => mapping(uint256 => Accessory)) public equippedAccessories;
    mapping(uint256 => address) public accessoryOrder;
    uint256 public totalSupply;
    uint256 public salePrice;
    uint256 public saleStartAt;
    string public baseURI;
    bytes32 public whitelistMerkleRoot;
    uint8 public accessorySlots;

    event AccessoriesUpdates(uint256 indexed tokenId, Accessory[]);
    bytes32 public constant FUND_CLAIMER_ROLE = keccak256("FUND_CLAIMER_ROLE");

    uint256 public adminMintedCount;
    uint256 public constant MAX_ADMIN_MINT = 50;
    event AdminMint(address indexed to, uint256 tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _salePrice,
        address fundRaiseClaimer
    ) initializer public {
        __ERC721_init("Popbit", "PBT");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FUND_CLAIMER_ROLE, fundRaiseClaimer);
        require(_totalSupply > 0, "totalSupply must be greater than 0");
        totalSupply = _totalSupply;
        salePrice = _salePrice;
        saleStartAt = _startTime;
    }

    modifier isTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Genesis: not owner");
        _;
    }

    modifier validAccessories(Accessory[] memory _accessories) {
        require(_accessories.length <= accessorySlots, "Genesis: wrong length");
        for(uint256 i; i < _accessories.length; i++){
            require(whitelistedContracts[_accessories[i].contractAddr] == true, "Genesis: not whitelisted");
            require(accessoryOrder[i] == _accessories[i].contractAddr, "Genesis: wrong order");
        }
        _;
    }

    // ======================================================== Accessory Functions ========================================================

    function setAccessoryOrder(address[] calldata accessoryContracts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < accessoryContracts.length; i++) {
            accessoryOrder[i] = accessoryContracts[i];
        }
    }

    function setAccessorySlots(uint8 _accessorySlots) external onlyRole(DEFAULT_ADMIN_ROLE) {
        accessorySlots = _accessorySlots;
    }

    function getEquippedAccessories(uint256 _tokenId) public view returns (Accessory[] memory) {
        Accessory[] memory accessories = new Accessory[](accessorySlots);
        for (uint i; i < accessorySlots; i++) {
            accessories[i] = equippedAccessories[_tokenId][i];
        }
        return accessories;
    }

    function deEquipAllAccessories(uint256 _tokenId) external isTokenOwner(_tokenId) {
        for(uint i; i < accessorySlots; i++){
            if(equippedAccessories[_tokenId][i].accessoryId != 0){
                IERC1155Upgradeable(equippedAccessories[_tokenId][i].contractAddr).safeTransferFrom(
                    address(this),
                    msg.sender,
                    equippedAccessories[_tokenId][i].accessoryId,
                    1,
                    ""
                );
                equippedAccessories[_tokenId][i] = Accessory(address(0), 0);
            }
        }

        emit AccessoriesUpdates(_tokenId, getEquippedAccessories(_tokenId));
        emit MetadataUpdate(_tokenId);
    }

    function deEquipAccessory(uint256 _tokenId, uint256 accessoryType) external isTokenOwner(_tokenId) {
        require(accessoryType <= accessorySlots, 'Genesis: invalid accessoryType');
        require(equippedAccessories[_tokenId][accessoryType].accessoryId != 0, "Genesis: accessory already de-equipped");
        IERC1155Upgradeable(equippedAccessories[_tokenId][accessoryType].contractAddr).safeTransferFrom(
            address(this),
            msg.sender,
            equippedAccessories[_tokenId][accessoryType].accessoryId,
            1,
            ""
        );
        equippedAccessories[_tokenId][accessoryType] = Accessory(address(0), 0);

        emit AccessoriesUpdates(_tokenId, getEquippedAccessories(_tokenId));
        emit MetadataUpdate(_tokenId);
    }

    function equipAccessories(uint256 _tokenId, Accessory[] calldata _accessories) external isTokenOwner(_tokenId) validAccessories(_accessories) {
        for(uint i; i < _accessories.length; i++) {
            Accessory memory previous = equippedAccessories[_tokenId][i];
            if(previous.contractAddr != address(0) && previous.accessoryId != 0){
                IERC1155Upgradeable(previous.contractAddr).safeTransferFrom(
                    address(this),
                    msg.sender,
                    previous.accessoryId,
                    1,
                    ""
                );
            }
            Accessory memory current = _accessories[i];
            if(current.accessoryId != 0){
                IERC1155Upgradeable(current.contractAddr).safeTransferFrom(
                    msg.sender,
                    address(this),
                    current.accessoryId,
                    1,
                    ""
                );
            }
            equippedAccessories[_tokenId][i] = current;
        }

        emit AccessoriesUpdates(_tokenId, getEquippedAccessories(_tokenId));
        emit MetadataUpdate(_tokenId);
    }

    function setWhitelisted(address[] memory _whitelistedContracts, uint8 _accessorySlots) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_whitelistedContracts.length == _accessorySlots, "Genesis: wrong length");
        for(uint i; i < _whitelistedContracts.length; i++){
            whitelistedContracts[_whitelistedContracts[i]] = true;
        }
        accessorySlots = _accessorySlots;
    }

    function addWhitelistedContract(address _contractAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_contractAddr != address(0), 'Genesis: no address 0');
        whitelistedContracts[_contractAddr] = true;
    }

    function removeWhitelistedContracts(address[] memory _whitelistedContracts) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < _whitelistedContracts.length; i++) {
            if (whitelistedContracts[_whitelistedContracts[i]] == true) {
                whitelistedContracts[_whitelistedContracts[i]] = false;
            }
        }
    }

    // ======================================================== NFT Functions ========================================================

    function setTotalSupply(uint256 _totalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalSupply = _totalSupply;
    }

    function getCurrentSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setSalePrice(uint256 _salePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        salePrice = _salePrice;
    }

    function setSaleStartAt(uint256 _saleStartAt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStartAt = _saleStartAt;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function safeMint(address to, bytes32[] calldata merkleProof) external payable {
        require(msg.value >= salePrice, "Genesis: not enough ether sent");
        require(block.timestamp >= saleStartAt, "Genesis: sale has not started");
        require(_tokenIdCounter.current() < totalSupply, "Genesis: max supply reached");
        require(balanceOf(to) == 0, "Genesis: max 1 per wallet");
        if (whitelistMerkleRoot != bytes32(0)) {
            require(
                MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(_msgSender()))),
                "Genesis: invalid merkle proof"
            );
        }
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    // The following functions are overrides required by Solidity.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function setBaseURI(string calldata _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
        emit BatchMetadataUpdate(1, _tokenIdCounter.current());
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyRole(FUND_CLAIMER_ROLE) {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Genesis: failed to send to owner");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, IERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            )
        );
    }

    function mintBatch(address[] calldata toAddresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(toAddresses.length <= MAX_ADMIN_MINT - adminMintedCount, "Genesis: Exceeds admin mint limit");

        for (uint256 i = 0; i < toAddresses.length; i++) {
            address to = toAddresses[i];
            require(balanceOf(to) == 0, "Genesis: Max 1 per wallet");

            if (adminMintedCount < MAX_ADMIN_MINT) {
                // Skip merkle proof verification for admin minting
                _tokenIdCounter.increment();
                _safeMint(to, _tokenIdCounter.current());
                adminMintedCount++;

                emit AdminMint(to, _tokenIdCounter.current());
            }
        }
    }
}
