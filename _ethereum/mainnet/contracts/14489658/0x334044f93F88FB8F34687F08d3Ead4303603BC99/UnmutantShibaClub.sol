// SPDX-License-Identifier: MIT
//  _    _                       _              _    _____ _     _ _            _____ _       _
// | |  | |                     | |            | |  / ____| |   (_) |          / ____| |     | |
// | |  | |_ __  _ __ ___  _   _| |_ __ _ _ __ | |_| (___ | |__  _| |__   __ _| |    | |_   _| |__
// | |  | | '_ \| '_ ` _ \| | | | __/ _` | '_ \| __|\___ \| '_ \| | '_ \ / _` | |    | | | | | '_ \
// | |__| | | | | | | | | | |_| | || (_| | | | | |_ ____) | | | | | |_) | (_| | |____| | |_| | |_) |
//  \____/|_| |_|_| |_| |_|\__,_|\__\__,_|_| |_|\__|_____/|_| |_|_|_.__/ \__,_|\_____|_|\__,_|_.__/
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

error ExceedsMaxSupply();
error ExceedsMaxMintsPerWallet();
error CurrentSupplyExceedsQuantity();
error WrongEtherAmountSent();
error TokenDoesNotExist();
error SaleNotOpen();

contract UnmutantShibaClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 5555;
    uint256 public constant FREE_SUPPLY = 200;
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public PRICE_PER_NFT = .02 ether;

    enum ContractState {
        PAUSED,
        PUBLIC,
        REVEALED
    }
    ContractState public currentState = ContractState.PAUSED;

    mapping(address => bool) public proxyToApproved;

    string private baseURI;
    string private baseURISuffix;
    string private preRevealHolder = "PlaceHolder";

    constructor(string memory _base, string memory _suffix)
        ERC721A("UnmutantShibaClub", "USC")
    {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        if (currentState == ContractState.PAUSED) revert SaleNotOpen();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        uint256 currentPrice = getNFTPrice(quantity);
        if (currentPrice > msg.value) revert WrongEtherAmountSent();
        if (quantity > MAX_MINT_PER_TX) revert ExceedsMaxMintsPerWallet();

        _safeMint(msg.sender, quantity);

        if (msg.value > currentPrice) {
            Address.sendValue(payable(msg.sender), msg.value - currentPrice);
        }
    }

    function getNFTPrice(uint256 quantity) public view returns (uint256) {
        if (totalSupply() < FREE_SUPPLY) {
            uint256 freeLeft = FREE_SUPPLY - totalSupply();
            if (freeLeft + 1 > quantity) return 0;
            else return (quantity - freeLeft) * PRICE_PER_NFT;
        }

        return PRICE_PER_NFT * quantity;
    }

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
    }

    function setBaseURI(string calldata _base, string calldata _suffix)
        external
        onlyOwner
    {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function flipProxyApprovedState(address proxy) external onlyOwner {
        proxyToApproved[proxy] = !proxyToApproved[proxy];
    }

    function setMaxes(uint256 maxSupply, uint256 price) external onlyOwner {
        if (totalSupply() > maxSupply) revert CurrentSupplyExceedsQuantity();

        MAX_SUPPLY = maxSupply;
        PRICE_PER_NFT = price;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (currentState != ContractState.REVEALED) {
            return
                string(
                    abi.encodePacked(baseURI, preRevealHolder, baseURISuffix)
                );
        }
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), baseURISuffix)
            );
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (proxyToApproved[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }
}
