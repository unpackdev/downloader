// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//      __              __         __                __     __           __
//   __/ /_  ___  ___  / /_  ___  / /_____ ___ __   / /__ _/ /  ___   __/ /_
//  /_  __/ / _ \/ _ \/ __/ / _ \/  '_/ _ `/ // /  / / _ `/ _ \(_-<  /_  __/
//   /_/   /_//_/\___/\__/  \___/_/\_\\_,_/\_, /  /_/\_,_/_.__/___/   /_/
//                                        /___/

/**
 * @author NotOkayLabs
 */
contract NotOkayLions is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {

    string public baseURI;
    string private preRevealURI;

    uint256 public constant MINT_PRICE = 0.015 ether; 
    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MAX_PER_WALLET = 60;
    uint256 public constant FREE_SUPPLY = 1000;
    uint256 public constant TOTAL_SUPPLY = 10000;

    bool public isMintOpened;

    // As per ERC721R docs - check https://github.com/exo-digital-labs/ERC721R
    uint256 public constant refundPeriod = 5 hours;
    uint256 public refundEndTime;
    address public refundAddress;

    // False for all tokenIDs by default
    mapping(uint256 => bool) public _secondarySale;

    constructor() ERC721A("NotOkayLions", "NOL") {
        refundAddress = msg.sender;
        toggleRefundCountdown();
    }

    /**
     * @dev Make the starting tokenID 1 instead of 0.
     */
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    /* ========================================== MINT ========================================== */

    /**
     * @notice Mints _amount tokens to the caller address
     */
    function mint(uint256 _amount) external payable {
        require(msg.sender == tx.origin, "No bots s'il vous plait.");
        uint256 cost = MINT_PRICE;
        if (totalSupply() + _amount <= FREE_SUPPLY) {
            cost = 0;
        }
        require(
            msg.value == _amount * cost,
            "Wrong amount of ETH transferred through."
        );
        require(
            totalSupply() + _amount <= TOTAL_SUPPLY,
            "I'm afraid we're out of Not Okay Lions..."
        );
        require(isMintOpened, "Minting is closed.");
        require(
            numberMinted(msg.sender) + _amount <= MAX_PER_WALLET,
            "Too many Not Okay Lions per wallet. Try to buy a few less."
        );
        require(
            _amount <= MAX_PER_TX,
            "Minting too many Lions in one transaction!"
        );
        _safeMint(msg.sender, _amount);
    }

    /**
     * @notice Toggles minting on/off
     */
    function toggleMinting() external onlyOwner {
        isMintOpened = !isMintOpened;
    }

    /**
     * @notice Returns number of already minted tokens
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /* ======================================== REFUNDS ======================================== */

    // The implementation of this section is done in accordance
    // with ERC721R documentation: https://github.com/exo-digital-labs/ERC721R

    /**
     * @notice Returns true, if refund time window is still open, false if it's too late
     */
    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    /**
     * @notice Returns the time at which the refund time window closes
     */
    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    /**
     * @notice Processes refunds for provided tokenIds
     * @dev As tokens that were minted for free cannot be refunded,
     * the function skips those and only accounts for paid tokens
     */
    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");
        uint256 refundedTokens = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                msg.sender == ownerOf(tokenId),
                "Cannot refund tokens you do not own!"
            );
            require(
                _secondarySale[tokenId] == false,
                "Cannot refund token after it was resold!"
            );
            if (tokenId > FREE_SUPPLY) {
                // Check if token was paid for, if so transfer it and account for it in the final refund sum
                transferFrom(msg.sender, refundAddress, tokenId);
                refundedTokens++;
            }
        }

        uint256 refundAmount = refundedTokens * MINT_PRICE;
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    /**
     * @notice Starts the refund window countdown. Called upon deployment/mint open
     */
    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    /* ======================================== UTILS ======================================== */

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
        if (isRefundGuaranteeActive()) {
            return preRevealURI;
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /**
     * @dev Using the after transfer hook to update secondary sales data to process refunds
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        if (from == address(0) || to == address(0) || to == refundAddress) {
            return;
        }
        // Make sure we don't include minting and burning - only external txs
        for (uint256 i = startTokenId; i <= startTokenId + quantity; i++) {
            _secondarySale[i] = true;
        }
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPreRevealURI(string calldata preRevealURI_) external onlyOwner {
        preRevealURI = preRevealURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
