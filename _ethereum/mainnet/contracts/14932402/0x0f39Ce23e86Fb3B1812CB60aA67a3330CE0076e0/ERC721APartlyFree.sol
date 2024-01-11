// SPDX-License-Identifier: GPL-3.0-only
// Version 1.0
// Ⱎⴹ ⵢꓔ𐌠ⵎᏦ

pragma solidity ^0.8.0;

import "AccessControl.sol";
import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Address.sol";
import "ERC721A.sol";

error MintInactive(uint256 currentTime, uint256 startTime);
error NonPositiveMintAmount(uint32 amount);
error InsufficientSupplyAvailable(
    uint256 availableSupply,
    uint32 requestedAmount
);
error InsufficientReservedTokensAvailable(
    uint32 remainingReservedTokens,
    uint32 amount
);
error InsufficientFunds(uint256 funds, uint256 cost);
error ExceedingMaxTokensPerWallet(
    uint256 balance,
    uint16 requestedAmount,
    uint32 walletLimit
);
error CallerIsContract(address address_);

error OccupiedSupplyExceedsNewMaxSupply(
    uint256 occupiedSupply,
    uint32 newMaxSupply
);
error ReservedTokensExceedsRemainingSupply(
    uint256 remainingSupply,
    uint32 newReservedTokens
);
error UnableToWithdraw(uint256 amount);
error UnableToSendChange(uint256 cashChange);

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721APartlyFree is ERC721A, AccessControl, ReentrancyGuard, Ownable {
    using Address for address;

    uint32 public maxSupply;
    uint32 public maxMintsPerWallet;
    // for team members and giveaways.
    uint32 public reservedTokens;

    uint32 public totalFreeItems;
    uint32 public freeItemsMinted = 0;
    uint256 public mintStartTime;
    uint256 public mintPrice;

    string public preRevealURI;
    string public baseURI = "";
    bool public revealed = false;

    address public proxyRegistryAddress;

    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint32 maxSupply_,
        uint32 reservedTokens_,
        uint32 totalFreeItems_,
        // In wei.
        uint256 mintPrice_,
        uint32 maxMintsPerWallet_,
        uint256 mintStartTime_,
        string memory preRevealURI_,
        address proxyRegistryAddress_
    ) ERC721A(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_MANAGER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);

        maxSupply = maxSupply_;
        reservedTokens = reservedTokens_;
        mintPrice = mintPrice_;
        mintStartTime = mintStartTime_;
        preRevealURI = preRevealURI_;
        totalFreeItems = totalFreeItems_;
        maxMintsPerWallet = maxMintsPerWallet_;
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    modifier mintActive(uint256 time) {
        if (block.timestamp < time) {
            revert MintInactive({
                currentTime: block.timestamp,
                startTime: time
            });
        }
        _;
    }

    modifier mintCheck() {
        if (tx.origin != msg.sender) {
            revert CallerIsContract({address_: msg.sender});
        }

        uint256 availableSupply = (maxSupply - _totalMinted() - reservedTokens);
        if (availableSupply == 0) {
            revert InsufficientSupplyAvailable({
                availableSupply: availableSupply,
                requestedAmount: 1
            });
        }

        uint256 numberMinted = _numberMinted(msg.sender);
        if (numberMinted == maxMintsPerWallet) {
            revert ExceedingMaxTokensPerWallet({
                balance: numberMinted,
                requestedAmount: 1,
                walletLimit: maxMintsPerWallet
            });
        }
        _;
    }

    modifier validAdminMint(uint16 amount) {
        validateAdminMint(amount);
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function adminMint(address _to, uint16 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        validAdminMint(amount)
    {
        reservedTokens -= amount;
        _mint(_to, amount);
    }

    // Current implementation required an address to be present multiple times
    // to airdrop multiple nfts.
    function airdrop(address[] memory _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint16 totalAddresses = uint16(_to.length);
        validateAdminMint(totalAddresses);

        reservedTokens -= totalAddresses;

        for (uint256 i = 0; i < totalAddresses; i++) {
            _mint(_to[i], 1);
        }
    }

    function publicMint()
        external
        payable
        nonReentrant
        mintCheck
        mintActive(mintStartTime)
    {
        _internalMint();
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function safeWithdraw() external onlyRole(WITHDRAW_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert UnableToWithdraw({amount: address(this).balance});
        }
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setBaseURI(string memory newBaseURI, bool reveal)
        external
        onlyRole(URI_MANAGER_ROLE)
    {
        baseURI = newBaseURI;
        if (reveal) {
            revealed = reveal;
        }
    }

    function setRevealed(bool isRevealed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revealed = isRevealed;
    }

    function setMintPrice(uint256 newMintPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintPrice = newMintPrice;
    }

    function setMintStartTime(uint256 newMintStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintStartTime = newMintStartTime;
    }

    function setTotalFreeItems(uint32 newTotalFreeItems)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        totalFreeItems = newTotalFreeItems;
    }

    function setMaxSupply(uint32 newMaxSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 occupiedSupply = _totalMinted() + reservedTokens;
        if (newMaxSupply < occupiedSupply) {
            revert OccupiedSupplyExceedsNewMaxSupply({
                occupiedSupply: occupiedSupply,
                newMaxSupply: newMaxSupply
            });
        }
        maxSupply = newMaxSupply;
    }

    function setMaxMintsPerWallet(uint32 newMintsMaxPerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxMintsPerWallet = newMintsMaxPerWallet;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        proxyRegistryAddress = newProxyRegistryAddress;
    }

    function setReservedTokens(uint32 newReservedTokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 remainingSupply = maxSupply - _totalMinted();
        if (newReservedTokens > remainingSupply) {
            revert ReservedTokensExceedsRemainingSupply({
                remainingSupply: remainingSupply,
                newReservedTokens: newReservedTokens
            });
        }

        reservedTokens = newReservedTokens;
    }

    function exists(uint32 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed) {
            if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(baseURI, _toString(tokenId), ".json")
                    )
                    : "";
        } else {
            return preRevealURI;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return (ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId));
    }

    function _internalMint() internal {
        uint256 cashIn = msg.value;
        uint32 freeItemsLeft = totalFreeItems - freeItemsMinted;
        bool free = freeItemsLeft >= 1;
        uint256 cost = 0;

        if (!free) {
            if (mintPrice > msg.value) {
                revert InsufficientFunds({funds: msg.value, cost: mintPrice});
            }
            cost = mintPrice;
        } else {
            freeItemsMinted += 1;
        }

        uint256 cashChange = cashIn - cost;
        _mint(msg.sender, 1);

        if (cashChange > 0) {
            (bool success, ) = msg.sender.call{value: cashChange}("");
            if (!success) {
                revert UnableToSendChange({cashChange: cashChange});
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function validateAdminMint(uint16 amount) private {
        if (amount == 0) {
            revert NonPositiveMintAmount({amount: amount});
        }

        if (amount > reservedTokens) {
            revert InsufficientReservedTokensAvailable({
                remainingReservedTokens: reservedTokens,
                amount: amount
            });
        }
    }
}
