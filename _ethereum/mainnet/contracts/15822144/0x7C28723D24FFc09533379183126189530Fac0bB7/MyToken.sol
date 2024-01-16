// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./ERC721OperatorFilter.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./ECDSA.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Burnable.sol";
import "./draft-EIP712.sol";

error MismatchedInputs();
error HouseOpeningIsClosed();
error HouseAlreadyOpen();
error CannotOpenUnownedHouse();
error OfriendFactoryNotOpenYet();
error AddressIsNull();
error TransferFailed();
error PublicSaleClosed();
error NoContractMints();
error MaxMintExceeded();
error OnlyOfriendsBurnable();
error OnlyOfriendsLick();
error AlreadyMintedAddress();
error InvalidSignature();
error NotEnoughEth();
error OnlyOwnerCanDrop();

abstract contract OfriendFactory {
    function callOfTheWild(address to, uint256 oFriendTokenId) public virtual returns (uint256);
}

contract oFriends is Ownable, ReentrancyGuard, ERC721OperatorFilter, Pausable, EIP712, ERC2981, ERC721Burnable  {
    using ECDSA for bytes32;
    
    event Licked(address indexed toLickContract, uint256 indexed toLickTokenId, uint256 indexed oFriendTokenId);
    
    mapping(address => mapping(uint256 => address)) private _licked;

    uint256 public constant MAX_HOUSES = 10_000;
    uint256 public constant MAX_PUPPIES = 20_000;
    
    uint64 private _oHouseIdCounter = 1;    
    uint64 private _oPuppyIdCounter = 20_000;
    
    address private oMoonContract;
    bool public canOpenHouse;

    address public dogTrainer = 0x68edBe29b331f211e4edB059919ECb64C5790c17;
    address public sigSigner = 0x68edBe29b331f211e4edB059919ECb64C5790c17;

    bool public raffleMintOpen;
    bool public puppyMintOpen;
    bool public friskyMintOpen;
    uint256 public publicMintPrice;

    string private _baseTokenURI;

    constructor() ERC721("oFriends", "OF") EIP712("oFriends", "1") {}    

    function lick(address toLickContract, uint256 toLickTokenId, uint256 oFriendTokenId) external {
        if (msg.sender != ownerOf(oFriendTokenId)) revert("Cannot lick");
        if (oFriendTokenId < MAX_HOUSES) revert OnlyOfriendsLick();
        if (oFriendTokenId > MAX_PUPPIES) revert OnlyOfriendsLick();
        _licked[toLickContract][toLickTokenId] = msg.sender;
        emit Licked(toLickContract, toLickTokenId, oFriendTokenId);
    }

    function isLicked(address toLickContract, uint256 toLickTokenId) public view virtual returns (address) {
        return _licked[toLickContract][toLickTokenId];
    }
    
    function friskyOfriend(uint256 oFriendTokenId) public nonReentrant() returns (uint256) {
        
        if (!friskyMintOpen) {
            if (msg.sender != owner()) revert HouseOpeningIsClosed();
        }
        if (oFriendTokenId < MAX_HOUSES) revert OnlyOfriendsBurnable();
        if (oFriendTokenId > MAX_PUPPIES) revert OnlyOfriendsBurnable();

        address to = ownerOf(oFriendTokenId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotOpenUnownedHouse();
        }

        OfriendFactory factory = OfriendFactory(oMoonContract);

        _burn(oFriendTokenId);

        uint256 oMoonTicketId = factory.callOfTheWild(to, oFriendTokenId);
        return oMoonTicketId;
    }

    function openHouse(uint256 houseId) public nonReentrant() returns (uint256) {
        if (!canOpenHouse) {
            if (msg.sender != owner()) revert HouseOpeningIsClosed();
        }
        if (houseId > MAX_HOUSES) revert HouseAlreadyOpen();

        address to = ownerOf(houseId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotOpenUnownedHouse();
        }

        _burn(houseId);
        unchecked {
            houseId += MAX_HOUSES;
        }
        _safeMint(to, houseId);
        return houseId;
    }

    // ======== oTreats ========

    function spillOtreats(address[] calldata receivers) external {
        if (receivers.length == 0) revert MismatchedInputs();
        if (msg.sender != dogTrainer) revert OnlyOwnerCanDrop();

        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], _oHouseIdCounter);
            unchecked {
                _oHouseIdCounter += 1;
                ++i;
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ======== Public Sale ========

    function findPuppy(bytes calldata sig) external payable {
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_oPuppyIdCounter + 1 > MAX_PUPPIES) revert MaxMintExceeded();

        bytes memory data;

        // once waitlist mint opens, only check waitlist signatures
        if (puppyMintOpen) {
            data = abi.encodePacked(msg.sender, uint256(1));
        } else if (raffleMintOpen) {
            data = abi.encodePacked(msg.sender, uint256(0));
        } else {
            revert PublicSaleClosed();
        }

        address signedAddr = keccak256(data)
            .toEthSignedMessageHash()
            .recover(sig);

        if (sigSigner != signedAddr) revert InvalidSignature();
        
        uint64 oPuppyTokenId = _oPuppyIdCounter;
        unchecked {
            _oPuppyIdCounter += 1;
        }
        _safeMint(msg.sender, oPuppyTokenId);
        _refundOverPayment(publicMintPrice);
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert NotEnoughEth();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    // ======== Info ========

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ======== Royalty ========

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ======== Admin ========

    function toggleCanOpenHouse() external onlyOwner {
        canOpenHouse = !canOpenHouse;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setOmoonContract(address contractAddress) external onlyOwner {
        oMoonContract = contractAddress;
    }

    function setSigSigner(address signer) external onlyOwner {
        if (signer == address(0)) revert AddressIsNull();
        sigSigner = signer;
    }

    function setDogTrainer(address addr) external onlyOwner {
        if (addr == address(0)) revert AddressIsNull();
        dogTrainer = addr;
    }

    function toggleRaffleMint() external onlyOwner {
        raffleMintOpen = !raffleMintOpen;
    }

    function togglePuppyMint() external onlyOwner {
        puppyMintOpen = !puppyMintOpen;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721OperatorFilter)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}