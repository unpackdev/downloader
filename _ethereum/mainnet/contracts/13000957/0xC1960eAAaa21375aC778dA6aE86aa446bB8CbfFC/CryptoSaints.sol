// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";

contract CryptoSaints is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    // prepublished hash of the artwork
    string public constant provenance = "7e652abe53d64f9293c97ece038b8b8f7c576e61c08081dca431cc9a0a9d20c2";

    // opens on ... 1619784005
    // FIXME: set this
    uint256 public constant SALE_START_TIMESTAMP = 1619870400 + 3600;

    uint256 public constant MAX_NFT_SUPPLY = 7777;

    uint256 public constant price = 111000000000000000;

    uint256 public startingIndex;

    // current metadata base prefix
    string private _baseTokenUri;

    uint256 public daoLockedFunds;
    uint256 public ownerBalance;

    // Make this an ERC20Upgradeable
    address public daoToken;

    function initialize() public initializer {
        __ERC721_init("CryptoSaints", "SAINT");
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function setStartingIndex() internal {
        startingIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.gasprice,
                        msg.sender,
                        block.difficulty,
                        block.timestamp
                    )
                )
            ) %
            MAX_NFT_SUPPLY;
    }

    /// @dev Mint a CryptoSaints tokens.
    function mintNFT() public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Max Supply Reached");
        require(price == msg.value, "Invalid ETH Amount");

        if (startingIndex == 0) {
            setStartingIndex();
        }

        _safeMint(msg.sender, totalSupply());
    }

    /// @dev Withdraw owner's ETH from this contract.
    /// @param amount ETH amount to withdraw.
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Can't withdraw 0 wei");
        require(amount <= address(this).balance, "Amount Exceeds Balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETH Transfer Failed");
    }

    /// @dev Return _baseTokenUri instead of the default impl's "".
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    /// @dev Set a new base URI to use in tokenURI.
    /// @param newUri Must NOT include the trailing slash.
    function setTokenURI(string calldata newUri) public onlyOwner {
        _baseTokenUri = newUri;
    }

    /// @dev Generate a token URI.
    /// @param rTokenId A token id remapped based on `startingIndex`
    function indexedTokenURI(uint256 rTokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    "/",
                    rTokenId.toString(),
                    ".json"
                )
            );
    }

    /// @dev Return a token URI.
    /// @param tokenId A token id. (Always non-remapped.)
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "Unknown tokenId");

        return indexedTokenURI((tokenId + startingIndex) % MAX_NFT_SUPPLY);
    }
}
