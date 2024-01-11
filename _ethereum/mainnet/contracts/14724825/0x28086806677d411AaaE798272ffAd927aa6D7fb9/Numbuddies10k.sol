// SPDX-License-Identifier: MIT

import "Strings.sol";
import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

pragma solidity ^0.8.6;

interface IRegistrarController {
    function valid(string memory name) external pure returns (bool);

    function owner() external view returns (address);
}

interface IBaseRegistrar {
    function ownerOf(uint256 tokenId) external view returns (address);

    function owner() external view returns (address);
}

/**
 * @title Numbuddies10k
 * @dev VicMac
 */
contract Numbuddies10k is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    mapping(address => bool) public isAdmin;
    string public baseURI;
    string public baseExtension = ".json";

    Counters.Counter public totalSupply;

    uint256 public constant price = 0.0555 ether;
    uint256 public constant MAX_SUPPLY = 10000;

    uint8 public salePhase;

    // 0 closed
    // 1 reserved (by ENS)
    // 2 members (by ENS)
    // 3 holders

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _salePhase,
        string memory _base_URI
    ) ERC721(_name, _symbol) {
        salePhase = _salePhase;
        baseURI = _base_URI;
    }

    event Minted(uint256 remainingSupply);

    event Mintedd(uint256 remainingSupply);

    error DirectMintFromContractNotAllowed();
    error InsufficientETHSent();
    error SaleClosed();
    error NotOwnerOfTokenMatchingENS();
    error AllMinted();
    error AlreadyMinted();
    error TokenIdOutOfRange();
    error ENSOutOfRange();
    error WithdrawalFailed();
    error UseReservedMintFunction();
    error UseMemberMintFunction();
    error YouDoNotOwnThisEns();
    error InvalidTokenId();
    error MustOwnATokenForPhase3();
    error NotValidName();

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert DirectMintFromContractNotAllowed();
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner() || isAdmin[msg.sender]);
        _;
    }

    function getPhase() external view returns (uint8) {
        return salePhase;
    }

    function length4Pad(uint256 tokenNum)
        internal
        pure
        returns (string memory)
    {
        string memory rep = Strings.toString(tokenNum);
        if (tokenNum < 10) rep = string(abi.encodePacked("000", rep));
        else if (tokenNum < 100) rep = string(abi.encodePacked("00", rep));
        else if (tokenNum < 1000) rep = string(abi.encodePacked("0", rep));
        return rep;
    }

    function ownerOfENS(uint256 tokenId) public view returns (address) {
        string memory name = length4Pad(tokenId);
        bytes32 label = keccak256(bytes(name));
        // Official ENS: Base Registrar Implementation
        IRegistrarController registrarController = IRegistrarController(
            0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5
        );
        if (!registrarController.valid(name)) revert NotValidName();
        // Official ENS: ETH Registrar Controller
        IBaseRegistrar baseRegistrar = IBaseRegistrar(
            0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
        );
        return baseRegistrar.ownerOf(uint256(label));
    }

    function getRemainingSupply() public view returns (uint256) {
        unchecked {
            return MAX_SUPPLY - totalSupply.current();
        }
    }

    function checkValidMint(uint256 tokenId) public view {
        if (salePhase == 0) revert SaleClosed();
        if (totalSupply.current() == MAX_SUPPLY) revert AllMinted();
        if (tokenId < 0 || tokenId >= MAX_SUPPLY) revert TokenIdOutOfRange();
        if (_exists(tokenId)) revert AlreadyMinted();
        if (salePhase == 1 && ownerOfENS(tokenId) != msg.sender)
            revert NotOwnerOfTokenMatchingENS();
        if (salePhase == 3 && balanceOf(msg.sender) == 0)
            revert MustOwnATokenForPhase3();
    }

    // phase 1, 3 - 1) token #NNNN buyable by NNNN.eth 3) #NNNN buyable by any NNNN.eth
    function reservedMint(uint256 tokenId)
        external
        payable
        nonReentrant
        callerIsUser
    {
        checkValidMint(tokenId);
        if (salePhase == 2) revert UseMemberMintFunction();
        if (msg.value < price) revert InsufficientETHSent();

        totalSupply.increment();
        _safeMint(msg.sender, tokenId);
        emit Minted(getRemainingSupply());
    }

    // phase 2 - token #NNNN buyable by NNNN.eth
    function memberMint(uint256 tokenId, uint256 ensOwnedNumber)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (salePhase != 2) revert UseReservedMintFunction();
        checkValidMint(tokenId);
        if (ensOwnedNumber < 0 || ensOwnedNumber >= MAX_SUPPLY)
            revert ENSOutOfRange();
        if (ownerOfENS(ensOwnedNumber) != msg.sender)
            revert YouDoNotOwnThisEns();
        if (msg.value < price) revert InsufficientETHSent();

        totalSupply.increment();
        _safeMint(msg.sender, tokenId);
        emit Minted(getRemainingSupply());
    }

    function withdraw() external onlyAdmin nonReentrant {
        address payable DEV1 = payable(
            address(0xb93541327FA2b5BEB449FC6F42290B43dD269d8C)
        );
        address payable DEV2 = payable(
            address(0xC263251b3e64F27D6F7aFB41AF0934E682c6b362)
        );
        address payable DEV3 = payable(
            address(0x10d17d231eF198742Ed41588741BFbBc09Fd7Ed6)
        );
        address payable DEV4 = payable(
            address(0xBbB363F1b5a8fBC0b8b34ee3675969A80A255F9C)
        );
        uint256 each = address(this).balance / 4;
        (bool success1, ) = payable(DEV1).call{value: each}("");
        if (!success1) revert WithdrawalFailed();
        (bool success2, ) = payable(DEV2).call{value: each}("");
        if (!success2) revert WithdrawalFailed();
        (bool success3, ) = payable(DEV3).call{value: each}("");
        if (!success3) revert WithdrawalFailed();
        (bool success4, ) = payable(DEV4).call{value: address(this).balance}(
            ""
        );
        if (!success4) revert WithdrawalFailed();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function addAdmin(address _add) public onlyOwner {
        isAdmin[_add] = true;
    }

    function setBaseURI(string calldata _uri) external onlyAdmin {
        baseURI = _uri;
    }

    function setBaseExtension(string calldata _extension) external onlyAdmin {
        baseExtension = _extension;
    }

    function setSalePhase(uint8 _salePhase) external onlyAdmin {
        salePhase = _salePhase;
    }
}
