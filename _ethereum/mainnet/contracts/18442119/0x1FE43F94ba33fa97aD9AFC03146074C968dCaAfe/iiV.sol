// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./MerkleProof.sol";
import "./BitMaps.sol";
import "./ERC721AQueryable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./IERC4906.sol";
import "./AccessControl.sol";
import "./console2.sol";

enum TicketID {
    Premium,
    Standard
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract iiV is ERC721A, IERC4906, ERC2981, ERC721AQueryable, AccessControl {
    using BitMaps for BitMaps.BitMap;

    string private constant BASE_EXTENSION = ".json";
    address private constant FUND_ADDRESS =
        0x37df2D6523265a68975e2429e74E841d524b6BB9;
    address private constant ADMIN_ADDRESS =
        0x8b7fFdC69a06e06eba7352F012cdCf717Dcb11B4;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PIE_ROLE = keccak256("PIE_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public renounceOwnerMintFlag = false;
    bool public revealed = false;

    string private notRevealedURIPremium =
        "https://arweave.net/zpiRCW3zf3l1JHCtbjZlORua6ty--0oFv_nBPVxEfyc";
    string private notRevealedURIStandard =
        "https://arweave.net/YX0nlZOnMEo7vo5ll-qT2rG3McB4ufO6jfmpKPsVMjE";
    string private baseURI = "https://arweave.net/aaa/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public nftCost;
    mapping(TicketID => uint256) public maxSupply;
    mapping(TicketID => uint256) public totalSupplyCategory;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private metadataURI;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    BitMaps.BitMap private _premiumList;

    constructor() ERC721A("iiV", "iiV") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        nftCost[TicketID.Premium] = 0.08 ether;
        nftCost[TicketID.Standard] = 0.035 ether;
        maxSupply[TicketID.Premium] = 1500;
        maxSupply[TicketID.Standard] = 524;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (revealed) {
            return revealedURI(tokenId);
        } else {
            return getNotRevealedURI(tokenId);
        }
    }

    function getNotRevealedURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        if (_premiumList.get(tokenId)) {
            return notRevealedURIPremium;
        } else {
            return notRevealedURIStandard;
        }
    }

    function revealedURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION)
                );
        } else {
            return metadataURI[tokenId];
        }
    }

    function isPremium(uint256 tokenId) external view returns (bool) {
        return _premiumList.get(tokenId);
    }

    function setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(
        bytes32 _merkleRoot,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setMaxSupply(
        uint256 _max_supply,
        TicketID _ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply[_ticket] = _max_supply;
    }

    function setCallerIsUserFlg(
        bool flg
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function setRevealed(bool flg) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revealed = flg;
    }

    function publicMint(
        address _to,
        uint256 _mintAmount,
        TicketID ticket
    ) external payable callerIsUser whenMintable {
        if (totalSupplyCategory[ticket] + _mintAmount > maxSupply[ticket])
            revert MaxSupplyOver();
        if (msg.value < nftCost[ticket] * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();

        uint256 _firstTokenId = _nextTokenId();
        _mint(_to, _mintAmount);
        totalSupplyCategory[ticket] = totalSupplyCategory[ticket] + _mintAmount;
        if (ticket == TicketID.Premium) {
            for (uint i = _firstTokenId; i < _firstTokenId + _mintAmount; i++) {
                _premiumList.set(i);
            }
        }
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID _ticket
    ) external payable whenMintable {
        _preMint(_mintAmount, _presaleMax, _merkleProof, msg.sender, _ticket);
    }

    function _preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        address _recipient,
        TicketID _ticket
    ) internal {
        if (totalSupplyCategory[_ticket] + _mintAmount > maxSupply[_ticket])
            revert MaxSupplyOver();
        if (msg.value < nftCost[_ticket] * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!presalePhase[_ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _presaleMax));
        if (whiteListClaimed[_ticket][_recipient] + _mintAmount > _presaleMax)
            revert AlreadyClaimedMax();
        if (
            !MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_ticket], leaf)
        ) revert InvalidMerkleProof();

        uint256 _firstTokenId = _nextTokenId();

        _mint(_recipient, _mintAmount);
        whiteListClaimed[_ticket][_recipient] += _mintAmount;

        totalSupplyCategory[_ticket] =
            totalSupplyCategory[_ticket] +
            _mintAmount;
        if (_ticket == TicketID.Premium) {
            for (uint i = _firstTokenId; i < _firstTokenId + _mintAmount; i++) {
                _premiumList.set(i);
            }
        }
    }

    function mintPie(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        address _recipient,
        TicketID ticket
    ) external payable whenMintable onlyRole(PIE_ROLE) {
        _preMint(_mintAmount, _presaleMax, _merkleProof, _recipient, ticket);
    }

    function ownerMint(
        address _address,
        uint256 _mintAmount,
        TicketID _ticket
    ) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        uint256 _firstTokenId = _nextTokenId();
        _safeMint(_address, _mintAmount);
        totalSupplyCategory[_ticket] =
            totalSupplyCategory[_ticket] +
            _mintAmount;
        if (_ticket == TicketID.Premium) {
            for (uint i = _firstTokenId; i < _firstTokenId + _mintAmount; i++) {
                _premiumList.set(i);
            }
        }
    }

    function setPresalePhase(
        bool _state,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(
        uint256 _cost,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftCost[ticket] = _cost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(FUND_ADDRESS).transfer(address(this).balance);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
