// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./IAmogus.sol";
import "./IProxyRegistry.sol";

contract Amogus is Ownable, ERC721, IAmogus {
    error AmountExceedsMax(uint256 amount, uint256 maxAmount);
    error AmountExceedsMaxPerMint(uint256 amount, uint256 maxAmountPerMint);
    error NotEnoughEther(uint256 value, uint256 requiredEther);
    error SaleNotStarted(uint256 timestamp, uint256 startTime);

    // Thursday, 9 September 2021, 16:00 UTC
    uint256 public immutable saleStartTimestamp = 1631203200;

    // Max amount of public tokens
    uint256 public immutable maxPublicAmount = 9800;

    // Current amount of public tokens
    uint256 public currentPublicAmount;

    // Max amount of reserved tokens
    uint256 public immutable maxReservedAmount = 200;

    // Current amount of reserved tokens
    uint256 public currentReservedAmount;

    // Mint price of each token (1 ETH)
    uint256 public immutable price = 0.025 ether;

    // Max amount of NFT per one `mint()` function call
    uint256 public immutable maxAmountPerMint = 20;

    /// @inheritdoc IAmogus
    string public override contractURI;

    /// @inheritdoc IAmogus
    uint256 public override totalSupply;

    // Interface id of `contractURI()` function
    bytes4 private constant INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    // OpenSea Proxy Registry address
    address internal immutable openSeaProxyRegistry = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // Prefix of each tokenURI
    string internal baseURI;

    /// @notice Creates Amogus NFTs, stores all the required parameters.
    constructor() ERC721("Amogus", "SUS") { }
    // solhint-disable-previous-line no-empty-blocks

    /// @inheritdoc IAmogus
    function setBaseURI(string memory newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
    }

    /// @inheritdoc IAmogus
    function setContractURI(string memory newContractURI) external override onlyOwner {
        contractURI = newContractURI;
    }

    /// @inheritdoc IAmogus
    function mint(uint256 amount) external payable override {
        // solhint-disable not-rely-on-time
        if (block.timestamp < saleStartTimestamp)
            revert SaleNotStarted(block.timestamp, saleStartTimestamp);
        // solhint-enable not-rely-on-time
        if (amount > maxAmountPerMint) revert AmountExceedsMaxPerMint(amount, maxAmountPerMint);
        if (msg.value < price * amount) revert NotEnoughEther(msg.value, price * amount);
        uint256 newPublicAmount = currentPublicAmount + amount;
        if (newPublicAmount > maxPublicAmount)
            revert AmountExceedsMax(newPublicAmount, maxPublicAmount);

        currentPublicAmount = newPublicAmount;

        _safeMintMultiple(_msgSender(), amount);
    }

    /// @inheritdoc IAmogus
    function mintReserved(uint256 amount, address[] calldata recipients)
        external
        override
        onlyOwner
    {
        uint256 length = recipients.length;
        uint256 newReservedAmount = currentReservedAmount + length * amount;
        if (newReservedAmount > maxReservedAmount)
            revert AmountExceedsMax(newReservedAmount, maxReservedAmount);

        currentReservedAmount = newReservedAmount;

        for (uint256 i = 0; i < length; i++) {
            _safeMintMultiple(recipients[i], amount);
        }
    }

    /// @inheritdoc IAmogus
    function withdrawEther() external override onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_CONTRACT_URI || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        IProxyRegistry proxyRegistry = IProxyRegistry(openSeaProxyRegistry);
        if (proxyRegistry.proxies(owner) == operator) return true;

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Helper function for minting multiple tokens
    function _safeMintMultiple(address recipient, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, totalSupply);
        }
    }

    /// @inheritdoc ERC721
    function _safeMint(address recipient, uint256 tokenId) internal override {
        totalSupply += 1;

        super._safeMint(recipient, tokenId);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
