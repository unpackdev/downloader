// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";

import "./ERC721ARoyalties.sol";
import "./draft-EIP712.sol";

contract AlienVerse is ERC721ARoyalties, EIP712, ReentrancyGuard {

    using Strings for uint256;
    string private constant version = "1";
    address public cfo = address(0xD359aD36ae52fe04F1FF2B01ff549646dDA3403E);
    address private _validator;

    uint256 public auctionStartTime;
    mapping(address => uint256) public auctionMintsByAddress;
    uint256 public auctionMinted;
    uint256 public lastAuctionPrice;

    uint256 public constant WL_QTY_PER_ADDRESS = 1;
    uint256 public constant AUCTION_MAX_MINT = 1000;
    uint256 public constant AUCTION_MAX_MINT_BY_ADDRESS = 30;
    uint256 public constant AUCTION_START_PRICE = 0.25 ether;
    uint256 public constant AUCTION_END_PRICE = 0.01 ether;
    uint256 public constant AUCTION_TIME = 60 * 24 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 60 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
    (AUCTION_TIME / AUCTION_DROP_INTERVAL);


    mapping(address => uint256) public whiteMintsByAddress;
    uint256 public whiteMintStart;
    uint256 public whiteMintEnd;

    mapping(string => bool) public minted_code;

    bytes32 private constant WHITELIST_MINT_TYPEHASH =
    keccak256(
        "whiteListMint(address to,string code)"
    );

    error InvalidSign();


    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseUri,
        uint256 maxBatchSize,
        RoyaltyInfo memory royaltyInfo,
        address validator,
        uint256 auctionStartTime_,
        uint256 whiteMintStart_,
        uint256 whiteMintEnd_
    ) ERC721ARoyalties(name, symbol, maxSupply, baseUri, maxBatchSize, royaltyInfo) EIP712(name, version) {
        _validator = validator;
        auctionStartTime = auctionStartTime_;
        whiteMintStart = whiteMintStart_;
        whiteMintEnd = whiteMintEnd_;
    }


    function getWhiteMintPrice()
    public
    view
    returns (uint256)
    {
        if (lastAuctionPrice >= 0.01 ether) {
            return lastAuctionPrice * 7 / 10;
        } else {
            return AUCTION_START_PRICE * 7 / 10;
        }
    }

    function getAuctionPrice()
    public
    view
    returns (uint256)
    {
        uint256 _auctionStartTime = auctionStartTime;//For gas saving
        if (block.timestamp < _auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if (block.timestamp - _auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _auctionStartTime) /
                        AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    function auctionMint(uint256 quantity, address to) external payable nonReentrant {
        uint256 _auctionStartTime = auctionStartTime;//For gas saving
        require(
            _auctionStartTime == 0 || (block.timestamp <= _auctionStartTime + AUCTION_TIME && block.timestamp >= _auctionStartTime),
            "auction has not started or has ended"
        );

        uint256 _auctionMinted = auctionMinted + quantity;
        require(
            _auctionMinted <= AUCTION_MAX_MINT,
            "not enough remaining reserved"
        );
        auctionMinted = _auctionMinted;

        uint256 minted = auctionMintsByAddress[to] + quantity;
        require(
            minted <= AUCTION_MAX_MINT_BY_ADDRESS,
            "reach max mints per address");
        auctionMintsByAddress[to] +=minted;

        uint256 auctionPrice = getAuctionPrice();
        uint256 totalCost = auctionPrice * quantity;
        require(msg.value >= totalCost, "Need to send more ETH.");

        mintTo(to, quantity);

        payable(cfo).transfer(totalCost);

        // refund
        if (msg.value > totalCost) {
            payable(to).transfer(msg.value - totalCost);
        }

        lastAuctionPrice = auctionPrice;
    }

    function verifySignature(
        address to,
        string memory code,
        bytes calldata signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WHITELIST_MINT_TYPEHASH,
                    to,
                    keccak256(bytes(code))
                )
            )
        );
        if (ECDSA.recover(digest, signature) != _validator) {
            revert InvalidSign();
        }
        return _validator;
    }


    function whiteListMint(string memory code, address to, bytes calldata signature) public payable {
        require(
            whiteMintStart == 0 || block.timestamp >= whiteMintStart,
            "sale has not started yet"
        );
        require(
            whiteMintEnd == 0 || block.timestamp <= whiteMintEnd,
            "sale has end"
        );
        require(minted_code[code] == false, "mint code has been used");
        minted_code[code] = true;

        uint256 totalCost = getWhiteMintPrice() * WL_QTY_PER_ADDRESS;
        require(msg.value == totalCost, "Need to check ETH value.");


        payable(cfo).transfer(totalCost);
        verifySignature(to, code, signature);

        mintTo(to, WL_QTY_PER_ADDRESS);
    }

    function setValidator(address validator) public onlyOwner {
        _validator = validator;
    }

    function setAuctionStartTime(uint256 auctionStartTime_) public onlyOwner {
        auctionStartTime = auctionStartTime_;
    }

    function setWhiteMintStart(uint256 whiteMintStart_) public onlyOwner {
        whiteMintStart = whiteMintStart_;
    }

    function setWhiteMintEnd(uint256 whiteMintEnd_) public onlyOwner {
        whiteMintEnd = whiteMintEnd_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function setCFO(address _cfo) public onlyOwner {
        cfo = _cfo;
    }
}
