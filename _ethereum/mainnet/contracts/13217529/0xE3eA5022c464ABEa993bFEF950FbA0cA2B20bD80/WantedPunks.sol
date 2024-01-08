// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WantedPunks is Ownable, ERC721Enumerable {
    using Strings for uint256;

    event TokenURISet(string indexed tokenUri);
    event TokenURILocked(string indexed tokenUri);
    event CollectionRevealed();
    event PresaleClosed();
    event MultisigProposed(address multisig);
    event MultisigUpdated(address multisig);
    event Pause();
    event Resume();

    uint256 public constant PRE_PRICE = 39000000000000000;
    uint256 public constant PRICE = 60000000000000000;
    uint256 public constant MAX_WP_SUPPLY = 950;
    uint256 public constant PRESALE_SUPPLY = 200;
    uint256 public constant WP_PACK_LIMIT = 5;
    uint256 private constant SPECIAL_RESERVE = 50;
    uint256 private constant SPLIT = 40;
    address private constant DEV_WALLET =
        0xebA9F4d9D11A3bD96C5dE4bcE02da592a2676473;
    string private constant PLACEHOLDER_SUFFIX = "placeholder.json";
    string private constant METADATA_INFIX = "/metadata/";
    string public constant provenance =
        "7488c72e8faa6dbfaa4188434b1d50dd9602843031cc9bbbf402052088dbdc65";

    // current metadata base prefix
    string private _baseTokenUri;
    uint256 private tipAccumulator;
    uint256 private earningsAccumulator;
    uint256 private specialReserveCounter;
    address public multisig;
    address private proposedMultisig;
    bool public tokenURILocked;
    bool public collectionRevealed;
    bool public presaleOn;
    bool public saleOn;
    bool public paused;

    constructor(address multisig_) ERC721("WP", "Wanted Punks") {
        require(multisig_ != address(0), "ZeroMultisigAddress");
        multisig = multisig_;
        presaleOn = true;
    }

    function finalizePresale() public onlyOwner {
        _finalizePresale();
    }

    function setTokenURI(string memory newUri)
        public
        onlyOwner
        whenUriNotLocked
    {
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    function lockTokenURI() public onlyOwner {
        if (!tokenURILocked) {
            tokenURILocked = true;
            emit TokenURILocked(_baseTokenUri);
        }
    }

    function presaleMint(uint256 punks) public payable {
        _enforceNotPaused();
        _enforcePresale();
        uint256 ts = totalSupply();
        uint256 sl = MAX_WP_SUPPLY;
        require(punks > 0, "ZeroWantedPunksRequested");
        // TODO: uncomment after testing
        // if (punks > WP_PACK_LIMIT) revert BuyLimitExceeded(WP_PACK_LIMIT);
        require(PRE_PRICE * punks == msg.value, "InvalidETHAmount");
        require(ts + punks <= sl, "MintingExceedsMaxSupply");

        for (uint256 i = 0; i < punks; i++) {
            _safeMint(msg.sender, ts + i);
        }

        uint256 tip = (msg.value * SPLIT) / 100;
        tipAccumulator += tip;
        earningsAccumulator += (msg.value - tip);

        if (totalSupply() == sl) {
            _finalizePresale();
        }
    }

    /// @dev mint up to `punks` tokens
    function mint(uint256 punks) public payable {
        _enforceNotPaused();
        _enforceSale();
        uint256 ts = totalSupply();
        uint256 sl = MAX_WP_SUPPLY;
        require(ts < MAX_WP_SUPPLY, "WantedPunksSoldOut");
        require(punks > 0, "ZeroWantedPunksRequested");
        require(punks <= WP_PACK_LIMIT, "BuyLimitExceeded");
        require(PRICE * punks == msg.value, "InvalidETHAmount");
        require(ts + punks <= sl, "MintingExceedsMaxSupply");

        for (uint256 i = 0; i < punks; i++) {
            _safeMint(msg.sender, ts + i);
        }

        uint256 tip = (msg.value * SPLIT) / 100;
        tipAccumulator += tip;
        earningsAccumulator += (msg.value - tip);

        if (totalSupply() == sl) {
            _reveal();
        }
    }

    function memorialize(uint256 punks) public onlyOwner {
        require(
            specialReserveCounter + punks <= SPECIAL_RESERVE,
            "MintingExceedsSpecialReserve"
        );

        require(punks > 0, "ZeroWantedPunksRequested");

        for (uint256 i = 0; i < punks; i++) {
            _safeMint(multisig, MAX_WP_SUPPLY + specialReserveCounter + i);
        }

        specialReserveCounter += punks;
    }

    function tipdraw(uint256 amount) public onlyDev {
        require(amount > 0, "ZeroWEIRequested");
        require(amount <= tipAccumulator, "AmountExceedsEarnings");

        tipAccumulator -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETHTransferFailed");
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "ZeroWEIRequested");
        require(amount <= earningsAccumulator, "AmountExceedsEarnings");

        earningsAccumulator -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETHTransferFailed");
    }

    /**
     * @dev Returns placeholder for a minted token prior to reveal time,
     * the regular tokenURI otherise.
     *
     * @param tokenId Identity of an existing (minted) WP NFT.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "UnknownTokenId");

        result = collectionRevealed ? regularURI(tokenId) : placeholderURI();
    }

    function earnings() public view returns (uint256 bal) {
        require(
            (msg.sender == owner()) || (msg.sender == DEV_WALLET),
            "StrangerDetected"
        );

        bal = (msg.sender == DEV_WALLET) ? tipAccumulator : earningsAccumulator;
    }

    function reveal() public onlyOwner {
        _reveal();
    }

    function proposeMultisigUpdate(address proposal) public onlyDev {
        require(proposal != address(0), "ZeroProposalAddress");
        proposedMultisig = proposal;
        emit MultisigProposed(proposedMultisig);
    }

    function approveMultisigUpdate(address confirmation) public onlyOwner {
        require(confirmation != address(0), "ZeroConfirmationAddress");
        require(confirmation == proposedMultisig, "ConfirmationMismatch");
        multisig = proposedMultisig;
        delete proposedMultisig;
        emit MultisigUpdated(multisig);
    }

    function toggle() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit Pause();
        } else {
            emit Resume();
        }
    }

    //
    // BASEMENT
    //
    function _pause() internal {
        paused = true;
        emit Pause();
    }

    function _enforceNotPaused() internal view {
        require(!paused, "OnPause");
    }

    modifier onlyDev() {
        require(msg.sender == DEV_WALLET, "StrangerDetected");

        _;
    }

    modifier whenUriNotLocked() {
        require(!tokenURILocked, "TokenURILockedErr");

        _;
    }

    function _enforcePresale() internal view {
        require(presaleOn, "PresaleNotOn");
    }

    function _enforceSale() internal view {
        require(saleOn, "SaleNotOn");
    }

    function placeholderURI() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    PLACEHOLDER_SUFFIX
                )
            );
    }

    function regularURI(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function _reveal() internal {
        if (!collectionRevealed) {
            collectionRevealed = true;
            emit CollectionRevealed();
        }
    }

    function _finalizePresale() internal {
        if (presaleOn) {
            _pause();
            presaleOn = false;
            saleOn = true;
            emit PresaleClosed();
        }
    }
}
