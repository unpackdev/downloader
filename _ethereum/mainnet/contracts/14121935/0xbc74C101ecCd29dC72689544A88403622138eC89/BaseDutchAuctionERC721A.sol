// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity 0.8.10;

import "./ERC721A.sol";
import "./LinearDutchAuction.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract BaseDutchAuctionERC721A is ERC721A, LinearDutchAuction, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public prefix = "Leveling Up Heroes Epic Base Verification:";
    string public prefixDiscounted = "Leveling Up Heroes Epic Discounted Verification:";
    string private baseTokenURI = '';

    mapping(address => uint256) private _whitelistClaimed;
    mapping(address => uint256) private _publicListClaimed;

    uint256 public whitelistMaxMint;
    uint256 public publicListMaxMint;
    uint256 public nonReservedMax;
    uint256 public reservedMax;
    uint256 public max;
    uint256 public nonReservedMinted;
    uint256 public reservedMinted;
    uint256 public discountedPrice;

    PaymentSplitter private _splitter;

    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint, 
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _discountedPrice
    )
        ERC721A(name, symbol, 5)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0, // disabled at deployment
                startPrice: 5 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 900, // 15 minutes
                decreaseSize: 0.5 ether,
                numDecreases: 9
            }),
            .5 ether
        )
    {
        whitelistMaxMint = _whitelistMaxMint;
        publicListMaxMint = _publicListMaxMint;
        nonReservedMax = _nonReservedMax;
        reservedMax = _reservedMax;
        max = nonReservedMax + reservedMax;
        nonReservedMinted = 0;
        reservedMinted = 0;
        discountedPrice = _discountedPrice;
        _splitter = new PaymentSplitter(payees, shares);
    }

    function release(address payable account) external {
        _splitter.release(account);
    }

    function _hash(string memory _prefix, address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        prefix = _prefix;
    }

    function setPrefixDiscounted(string memory _prefix) public onlyOwner {
        prefixDiscounted = _prefix;
    }

    function setWhitelistMaxMint(uint256 _whitelistMaxMint) external onlyOwner {
        whitelistMaxMint = _whitelistMaxMint;
    }

    function setPublicListMaxMint(uint256 _publicListMaxMint) external onlyOwner {
        publicListMaxMint = _publicListMaxMint;
    }

    function mintPublic(uint256 numberOfTokens) external payable {
        require(_publicListClaimed[msg.sender] + _whitelistClaimed[msg.sender] + numberOfTokens <= publicListMaxMint, 'You cannot mint this many.');

        _publicListClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens);
    }
    
    function mintWhitelist(bytes32 hash, bytes memory signature, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(prefix, msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens);
    }

    function _nonReservedMintHelper(uint256 numberOfTokens) internal nonReentrant {
        require(totalSupply() + numberOfTokens <= max, "Sold out.");
        uint256 price = cost(numberOfTokens);
        require(price <= msg.value, "Invalid amount.");

        _safeMint(msg.sender, numberOfTokens);

        if (msg.value > price) {
            address payable reimburse = payable(_msgSender());
            uint256 refund = msg.value - price;

            // Using Address.sendValue() here would mask the revertMsg upon
            // reentrancy, but we want to expose it to allow for more precise
            // testing. This otherwise uses the exact same pattern as
            // Address.sendValue().
            (bool success, bytes memory returnData) = reimburse.call{
                value: refund
            }("");
            // Although `returnData` will have a spurious prefix, all we really
            // care about is that it contains the ReentrancyGuard reversion
            // message so we can check in the tests.
            require(success, string(returnData));
        }
    }

    function splitPayments() public payable onlyOwner {
        (bool success, ) = payable(_splitter).call{value: address(this).balance}(
        ""
        );
        require(success);
    }

    function mintReserved(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= reservedMax,
            "Sold out."
        );

        if (quantity < maxBatchSize) {
            _safeMint(msg.sender, quantity);
        } else {
            require(
                quantity % maxBatchSize == 0,
                "Can only mint a multiple of the maxBatchSize."
            );
            uint256 numChunks = quantity / maxBatchSize;
            for (uint256 i = 0; i < numChunks; i++) {
                _safeMint(msg.sender, maxBatchSize);
            }
        }
    }

    function mintWhitelistDiscounted(bytes32 hash, bytes memory signature, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(prefixDiscounted, msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');
        require(discountedPrice == msg.value, "Invalid amount.");

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}