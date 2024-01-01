pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

interface ICelmates {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IDeathrow {
    function getDeathrow(
        uint256 _celId
    ) external view returns (Infos memory infos);
}

struct Infos {
    bool status;
    address owner;
    uint256 timestamp;
}

contract Inkmates is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    IERC721Receiver,
    DefaultOperatorFilterer
{
    constructor() ERC721("Inkmates", "INK") {}

    using Strings for uint256;

    ICelmates private CELMATES;
    IDeathrow private DEATHROW;

    uint256 RUNTIME = 420 hours;
    uint256 public OPENED_TIME;
    address private vault;
    uint256 mintPrice = 111000000000000000;
    string public BASE_URI;
    mapping(uint256 => bool) public applied;

    function mintTattoo(
        uint256[] memory _celIds
    ) external payable nonReentrant {
        require(block.timestamp < OPENED_TIME + RUNTIME, "Mint is closed");
        require(_celIds.length > 0, "No Celmates selected");
        require(msg.value == mintPrice * _celIds.length, "Not exact ETH");
        for (uint i = 0; i < _celIds.length; i++) {
            require(
                CELMATES.ownerOf(_celIds[i]) == msg.sender,
                "You don't own this Celmate"
            );
            require(DEATHROW.getDeathrow(_celIds[i]).status, "Not on Deathrow");
            _safeMint(msg.sender, _celIds[i]);
        }
    }

    function applyTattoo(uint256 _tattooId) external nonReentrant {
        require(ownerOf(_tattooId) == msg.sender, "Not owner");
        _burn(_tattooId);
        applied[_tattooId] = true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ------------------ Public ------------------ //

    function exist(uint256 _tattooId) public view returns (bool) {
        return _exists(_tattooId);
    }

    function tokenURI(
        uint256 _tattooId
    ) public view virtual override returns (string memory) {
        require(_exists(_tattooId));
        return string(abi.encodePacked(BASE_URI, _tattooId.toString()));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ------------------ Owner ------------------ //

    function safeMint(
        address[] memory _to,
        uint256[] memory _tokenIds
    ) public onlyOwner {
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _tokenIds[i]);
        }
    }

    function withdraw() external onlyOwner {
        require(vault != address(0), "no vault");
        require(payable(vault).send(address(this).balance));
    }

    function launchMint() external onlyOwner {
        OPENED_TIME = block.timestamp;
    }

    function setURI(string memory _uri) external onlyOwner {
        BASE_URI = _uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setAddresses(
        address _celmates,
        address _deathrow,
        address _vault
    ) external onlyOwner {
        CELMATES = ICelmates(_celmates);
        DEATHROW = IDeathrow(_deathrow);
        vault = _vault;
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}
