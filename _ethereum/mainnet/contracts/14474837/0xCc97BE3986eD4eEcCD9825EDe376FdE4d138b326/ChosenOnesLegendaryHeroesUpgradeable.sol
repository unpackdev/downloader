// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./BaseERC721Upgradeable.sol";

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

contract ChosenOnesLegendaryHeroesUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;

    struct Voucher {
        bool everybody;
        address minter;
        uint256 wallet_limit; // 0 means no limit
        uint256 price;
    }

    // ROLES
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // DATA Setting
    address payable private treasury;
    string private base_uri;
    uint256 private max;
    mapping(address => uint256[]) address_tokens;
    mapping(address => mapping(uint256 => uint256)) address_tokens_index;

    function initialize() public initializer {
        __ERC721_init("Chosen Ones Legendary Heroes", "COLH");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __EIP712_init("Chosen Ones Legendary Heroes", "1.0.0");

        address owner = address(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(UPGRADER_ROLE, owner);
        _setupRole(BURN_ROLE, owner);
        _setupRole(SIGNER_ROLE, owner);
        _setupRole(WITHDRAW_ROLE, owner);

        treasury = payable(owner);
        base_uri = "https://nft.chosenones.io/api/";
        max = 10000;
    }

    // Overrides

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, tokenId);
        if (from != address(0)) DelTokenFromAddress(from, tokenId);
        if (to != address(0)) AddTokenToAddress(to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        onlyRole(BURN_ROLE)
    {
        DelTokenFromAddress(msg.sender, tokenId);
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return base_uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
    }

    // Functions
    function AddTokenToAddress(address to, uint256 tokenId) private {
        address_tokens[to].push(tokenId);
        address_tokens_index[to][tokenId] = address_tokens[to].length - 1;
    }

    function DelTokenFromAddress(address from, uint256 tokenId) private {
        uint256 index = address_tokens_index[from][tokenId];
        delete address_tokens[from][index];
        delete address_tokens_index[from][tokenId];
    }

    function GetTreasury() public view returns (address payable) {
        return treasury;
    }

    function SetTreasury(address payable value) public onlyRole(OWNER_ROLE) {
        treasury = value;
    }

    function GetBaseURI() public view returns (string memory) {
        return base_uri;
    }

    function SetBaseURI(string memory value) public onlyRole(OWNER_ROLE) {
        base_uri = value;
    }

    function GetMax() public view returns (uint256) {
        return max;
    }

    // function SetMax(uint256 value) public onlyRole(OWNER_ROLE) {
    //     max = value;
    // }

    function GetTokens(address owner) public view returns (uint256[] memory) {
        return address_tokens[owner];
    }

    // MINT
    function Mint(
        Voucher memory voucher,
        uint256 count,
        bytes memory Signature
    ) public payable whenNotPaused {
        // Inputs
        require(count > 0, "Count can not be less than 1.");
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSAUpgradeable.recover(Hash(voucher), Signature)
            ),
            "Signature is not valid."
        );
        uint256 balance = totalSupply();
        require(balance < max, "All tokens in the drop have been sold out.");
        require(
            balance + count <= max,
            "Insufficient count of token requested."
        );

        // Voucher
        require(
            voucher.everybody || msg.sender == address(voucher.minter),
            "You are not a valid minter."
        );
        require(
            voucher.wallet_limit == 0 ||
                balanceOf(msg.sender) + count <= voucher.wallet_limit,
            "drop.wallet_limit is exceeded."
        );
        require(voucher.price * count <= msg.value, "Drop price is not valid");

        // Mint
        for (uint256 index = 0; index < count; index++) {
            uint256 next = totalSupply();
            _safeMint(msg.sender, next);
        }
    }

    function Burn(uint256 tokenId) public onlyRole(BURN_ROLE) {
        _burn(tokenId);
    }

    function Withdraw(uint256 amount)
        public
        onlyRole(WITHDRAW_ROLE)
        whenNotPaused
    {
        AddressUpgradeable.sendValue(treasury, amount);
    }

    function WithdrawAll() public onlyRole(WITHDRAW_ROLE) {
        Withdraw(address(this).balance);
    }

    function Pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function Resume() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function Hash(Voucher memory voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(bool everybody,address minter,uint256 wallet_limit,uint256 price)"
                        ),
                        voucher.everybody,
                        voucher.minter,
                        voucher.wallet_limit,
                        voucher.price
                    )
                )
            );
    }
}
