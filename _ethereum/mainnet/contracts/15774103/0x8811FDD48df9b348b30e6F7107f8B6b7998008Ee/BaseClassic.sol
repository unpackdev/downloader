// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

import "./TokenMetadata.sol";
import "./Royalty.sol";

abstract contract BaseClassic is
    ERC721AUpgradeable,
    ERC2771ContextUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokenMetadata,
    Royalty
{
    // URI for the contract metadata
    string public contractURI;

    // total assests in the collection
    uint256 public totalQuantity;

    // maximum mints per wallet
    uint256 public maxMintPerWallet;

    // maximum mint per each transaction
    uint256 public maxMintPerTx;

    // time minting begins
    uint256 public startingTimestamp;

    // time minting ends
    uint256 public endingTimestamp;

    // sale status
    bool public isSaleActive;

    // primay sale recipients address
    address[] public paymentAddresses;

    // primary sale recipients percentages
    uint256[] public paymentPercentages;

    // tracks number of times an address has minted
    mapping(address => uint256) public mintCountPerWallet;

    /***********************************************************************
                                    MODIFIERS
     *************************************************************************/

    modifier whenSaleIsActive() {
        require(isSaleActive, "Sale is not active");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    /***********************************************************************
                                PUBLIC FUNCTIONS
     *************************************************************************/

    function hasSaleStarted() public view returns (bool) {
        return
            block.timestamp >= startingTimestamp &&
            block.timestamp <= endingTimestamp;
    }

    function paymentAddressesCount() public view returns (uint256) {
        return paymentAddresses.length;
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/

    function airdrop(uint8 quantity, address recipient)
        external
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + quantity <= totalQuantity,
            "Not enough NFTs to airdrop"
        );

        _safeMint(recipient, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        for (uint256 i; i < paymentAddresses.length; i++) {
            _withdraw(
                paymentAddresses[i],
                (balance * paymentPercentages[i]) / 100
            );
        }
    }

    /**===========================================================================
                                    Setter Functions
    ============================================================================== */
    function _setOwnership(address owner) internal onlyInitializing {
        _transferOwnership(owner);
    }

    function _setSaleState() internal onlyInitializing {
        isSaleActive = true;
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function setName(string memory name) external onlyOwner {
        ERC721AStorage.layout()._name = name;
    }

    function setSymbol(string memory symbol) external onlyOwner {
        ERC721AStorage.layout()._symbol = symbol;
    }

    function setTotalQuantity(uint256 quantity) external onlyOwner {
        totalQuantity = quantity;
    }

    function setMaxMint(uint256 maxMint) external onlyOwner {
        maxMintPerWallet = maxMint;
    }

    function setMaxMintTx(uint256 maxMintTx) external onlyOwner {
        maxMintPerTx = maxMintTx;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        startingTimestamp = startTime;
    }

    function setEndTime(uint256 endTime) external onlyOwner {
        endingTimestamp = endTime;
    }

    function setSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /***********************************************************************
                                OVERRIDE FUNCTIONS
     *************************************************************************/

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (delayReveal && isRevealed == false) {
            return previewURI();
        }
        return _actualTokenURI(tokenId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /***********************************************************************
                                INTERNAL FUNCTIONS
     *************************************************************************/
    function _refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            (bool success, ) = _msgSender().call{value: msg.value - price}("");
            require(success, "Payment failed");
        }
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function _actualTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        _toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}
