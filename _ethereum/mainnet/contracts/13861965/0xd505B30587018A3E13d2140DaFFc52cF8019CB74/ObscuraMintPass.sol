//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./IERC2981.sol";

contract ObscuraMintPass is
    ERC721Enumerable,
    AccessControlEnumerable,
    IERC2981
{
    string private _contractURI;
    string private _defaultPendingCID;
    uint256 private constant DIVIDER = 10**5;
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private nextPassId;
    uint256 private royaltyFee;
    address private _obscuraAddress;

    mapping(uint256 => uint256) public tokenIdToPass;
    mapping(uint256 => Pass) public passes;

    struct Pass {
        uint256 maxTokens;
        uint256 circulatingTokens;
        uint256 platformReserveAmount;
        uint256 price;
        bool active;
        string name;
        string cid;
    }

    event SetSalePublicEvent(
        address caller,
        uint256 indexed passId,
        bool isSalePublic
    );
    event PassCreatedEvent(address caller, uint256 indexed passId);

    event PassMintedEvent(
        address user,
        uint256 indexed passId,
        uint256 tokenId
    );

    event ObscuraAddressChanged(
        address oldAddress,
        address newAddress
    );

    event WithdrawEvent(address caller, uint256 balance);

    constructor(address admin, address payable obscuraAddress)
        ERC721("Obscura Mint Pass", "OMP")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _obscuraAddress = obscuraAddress;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        uint256 _royaltyAmount = (salePrice * royaltyFee) / 100;

        return (_obscuraAddress, _royaltyAmount);
    }

    function setRoyalteFee(uint256 fee) public onlyRole(MODERATOR_ROLE) {
        royaltyFee = fee;
    }

    function setContractURI(string memory contractURI_)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _contractURI = contractURI_;
    }

    function setSalePublic(uint256 passId, bool _isSalePublic)
        external
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].active = _isSalePublic;

        emit SetSalePublicEvent(msg.sender, passId, _isSalePublic);
    }

    function isSalePublic(uint256 passId) external view returns (bool active) {
        return passes[passId].active;
    }

    function setDefaultPendingCID(string calldata defaultPendingCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _defaultPendingCID = defaultPendingCID;
    }

    function updatePassCID(uint256 passId, string memory cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].cid = cid;
    }

    function updateObscuraAddress(address newObscuraAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        emit ObscuraAddressChanged(_obscuraAddress, newObscuraAddress);
        _obscuraAddress = payable(newObscuraAddress);
    }

    function getPassPrice(uint256 passId)
        external
        view
        returns (uint256 price)
    {
        return passes[passId].price;
    }

    function getPassMaxTokens(uint256 passId)
        external
        view
        returns (uint256 maxTokens)
    {
        return passes[passId].maxTokens;
    }

    function getTokenIdToPass(uint256 tokenId)
        external
        view
        returns (uint256 passId)
    {
        return tokenIdToPass[tokenId];
    }

    function createPass(
        string memory name,
        uint256 maxTokens,
        uint256 platformReserveAmount,
        uint256 price,
        string memory cid
    ) external onlyRole(MODERATOR_ROLE) {
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(name).length > 0, "Pass name missing");
        require(
            platformReserveAmount < maxTokens,
            "Platform reserve too high."
        );
        require(price > 0, "Pass price missing");
        require(bytes(cid).length > 0, "Pass CID missing");

        uint256 passId = nextPassId += 1;
        passes[passId] = Pass({
            name: name,
            maxTokens: maxTokens,
            circulatingTokens: 0,
            platformReserveAmount: platformReserveAmount,
            price: price,
            active: false,
            cid: cid
        });

        emit PassCreatedEvent(msg.sender, passId);
    }

    function mintTo(address to, uint256 passId) external onlyRole(MINTER_ROLE) {
        uint256 circulatingTokens = passes[passId].circulatingTokens += 1;
        require(passes[passId].active == true, "Public sale is not open");
        require(
            circulatingTokens <= passes[passId].maxTokens,
            "All drop's SP tokens have been minted"
        );
        uint256 _tokenId = (passId * DIVIDER) + (circulatingTokens);
        tokenIdToPass[_tokenId] = passId;
        _mint(to, _tokenId);

        emit PassMintedEvent(to, passId, _tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 passId = tokenIdToPass[tokenId];
        string memory passCID = passes[passId].cid;

        if (bytes(passCID).length > 0) {
            return string(abi.encodePacked("https://arweave.net/", passCID));
        }

        return
            string(
                abi.encodePacked("https://arweave.net/", _defaultPendingCID)
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
