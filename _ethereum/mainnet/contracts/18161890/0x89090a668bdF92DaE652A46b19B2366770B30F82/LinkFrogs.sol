// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./LinkTokenInterface.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract LinkFrogs is ERC721A, Ownable, ReentrancyGuard {
    error LinkFrogs__TeamMintingAlreadyDone();
    error LinkFrogs__TeamMintingNotCompleted();
    error LinkFrogs__AllTokensAlreadyMinted();
    error LinkFrogs__InvalidNumberOfTokensToMint();
    error LinkFrogs__TokenDoesntExist();
    error LinkFrogs__EthTransferFailed();
    error LinkFrogs__LinkTransferFailed();
    error LinkFrogs__EthBalanceEmpty();
    error LinkFrogs__LinkBalanceEmpty();

    using Strings for uint256;

    uint256 private constant LINK_COST = 2.16 ether; // 2.16 LINK
    uint256 private constant MAX_TOKENS = 7777;
    uint256 private constant TEAM_MINTS = 216;
    uint256 private constant DISCOUNTED_MINTS = 1000;
    uint256 private s_tokenCounter;
    string private s_baseURI;

    LinkTokenInterface internal immutable LINK;

    bool private teamMintingCompleted = false;
    mapping(address => uint256) private walletMints;

    event FrogMinted(address indexed sender, uint256 startId, uint256 endId, uint256 amount);

    constructor(address _linkToken) ERC721A("Link Frogs", "FROG") {
        LINK = LinkTokenInterface(_linkToken);
        s_baseURI = "ipfs.io/ipfs/QmZi3bcRwDoSpznrMcZo6GoCzC9T8QUzqnPmK7taQ9kQie/";
    }

    function mintTeamFrogs() external onlyOwner {
        if (teamMintingCompleted) {
            revert LinkFrogs__TeamMintingAlreadyDone();
        }
        uint256 teamMints = TEAM_MINTS;
        _mint(msg.sender, teamMints);
        s_tokenCounter += teamMints;
        teamMintingCompleted = true;
        emit FrogMinted(msg.sender, s_tokenCounter - teamMints, s_tokenCounter - 1, teamMints);
    }

    function mintFrogs(uint256 amountToMint) external nonReentrant {
        if (!teamMintingCompleted) {
            revert LinkFrogs__TeamMintingNotCompleted();
        }
        if (!(amountToMint > 0)) {
            revert LinkFrogs__InvalidNumberOfTokensToMint();
        }
        uint256 currentTokenCounter = s_tokenCounter;
        if (currentTokenCounter + amountToMint > MAX_TOKENS) {
            revert LinkFrogs__AllTokensAlreadyMinted();
        }
        uint256 startId = currentTokenCounter + 1;
        uint256 endId = currentTokenCounter + amountToMint;
        uint256 remainingDiscountedMints = DISCOUNTED_MINTS + TEAM_MINTS - currentTokenCounter;
        uint256 cost;
        if (amountToMint > remainingDiscountedMints) {
            uint256 discountedCost = LINK_COST * remainingDiscountedMints / 2;
            uint256 fullCost = LINK_COST * (amountToMint - remainingDiscountedMints);
            cost = discountedCost + fullCost;
        } else {
            if (currentTokenCounter < DISCOUNTED_MINTS + TEAM_MINTS) {
                cost = LINK_COST * amountToMint / 2;
            } else {
                cost = LINK_COST * amountToMint;
            }
        }
        s_tokenCounter = endId;
        walletMints[msg.sender] += amountToMint;
        if (!LINK.transferFrom(msg.sender, address(this), cost)) {
            revert LinkFrogs__LinkTransferFailed();
        }
        _mint(msg.sender, amountToMint);
        emit FrogMinted(msg.sender, startId, endId, amountToMint);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert LinkFrogs__TokenDoesntExist();
        }
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseURI;
    }

    function withdrawLink() external onlyOwner {
        if (LINK.balanceOf(address(this)) <= 0) {
            revert LinkFrogs__LinkBalanceEmpty();
        } else {
            if (!LINK.transfer(owner(), LINK.balanceOf(address(this)))) {
                revert LinkFrogs__LinkTransferFailed();
            }
        }
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function getTeamMintCompletedStatus() public view returns (bool) {
        return teamMintingCompleted;
    }
}
