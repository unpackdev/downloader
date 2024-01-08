// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";

contract NFTYPass is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant TOKEN_COST = 2 ether;
    uint256 public constant TOKEN_RENEWAL = 1 ether;
    uint256 public constant TOKEN_MAXIMUM = 512;
    uint256 public constant OWNER_MAX_MINT = 10;

    bool public frozen;
    bool public purchasable;

    string public baseURI;

    uint256 public ownerMint;

    address private constant A = 0xc57112FB1872130A85ecF29877DD96042572a027;
    address private constant B = 0x69827Bf658898541380f78e0FBaF920ff020203b;

    address private signerAddress;

    mapping(uint256 => uint256) public tokenExpiry;
    mapping(address => uint256) private presalePurchases;

    constructor() ERC721("NFTYPass", "NFTY") {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "NFTYPass: EOA Only");
        _;
    }

    function _isExpired(uint256 tokenId) internal view returns (bool) {
        return block.timestamp > tokenExpiry[tokenId];
    }

    function purchase() external payable onlyEOA {
        uint256 supply = totalSupply();

        require(!frozen, "NFTYPass: Contract frozen");
        require(msg.value >= TOKEN_COST, "NFTYPass: Invalid ether amount");
        require(purchasable, "NFTYPass: Sale is not live");
        require(
            supply + 1 <= TOKEN_MAXIMUM,
            "NFTYPass: Exceeds supply maximum"
        );
        require(
            balanceOf(msg.sender) == 0,
            "NFTYPass: One pass per individual"
        );

        uint256 tokenId = supply + 1;
        tokenExpiry[tokenId] = block.timestamp + 30 days;

        _safeMint(msg.sender, tokenId);
    }

    function validatePresale(bytes calldata signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender))
            )
        );

        return signerAddress == hash.recover(signature);
    }

    function presale(bytes calldata signature) external payable onlyEOA {
        uint256 supply = totalSupply();

        require(validatePresale(signature), "NFTYPass: Invalid Signature");
        require(!frozen, "NFTYPass: Contract frozen");
        require(msg.value >= TOKEN_COST, "NFTYPass: Invalid ether amount");
        require(
            supply + 1 <= TOKEN_MAXIMUM,
            "NFTYPass: Exceeds supply maximum"
        );
        require(
            presalePurchases[msg.sender] == 0,
            "NFTYPass: One pass per individual"
        );

        uint256 tokenId = supply + 1;
        presalePurchases[msg.sender]++;
        tokenExpiry[tokenId] = block.timestamp + 30 days;

        _safeMint(msg.sender, tokenId);
    }

    function sendGift(address to) external onlyOwner {
        uint256 supply = totalSupply();

        require(!frozen, "NFTYPass: Contract frozen");
        require(purchasable, "NFTYPass: Sale is not live");
        require(
            supply + 1 <= TOKEN_MAXIMUM,
            "NFTYPass: Exceeds supply maximum"
        );
        require(
            ownerMint + 1 <= OWNER_MAX_MINT,
            "NFTYPass: Exceeds owner mint"
        );
        require(balanceOf(to) == 0, "NFTYPass: One pass per individual");

        uint256 tokenId = supply + 1;

        ownerMint++;
        tokenExpiry[tokenId] = block.timestamp + 30 days;

        _safeMint(to, tokenId);
    }

    function renew(uint256 tokenId) external payable {
        require(_exists(tokenId), "NFTYPass: Token does not exist");
        require(msg.value >= TOKEN_RENEWAL, "NFTYPass: Invalid ether amount");

        if (_isExpired(tokenId)) {
            tokenExpiry[tokenId] = block.timestamp + 30 days;
        } else {
            tokenExpiry[tokenId] += 30 days;
        }
    }

    function enablePurchases() external onlyOwner {
        require(!frozen, "NFTYPass: Contract frozen");
        purchasable = true;
    }

    function freeze() external onlyOwner {
        require(!frozen, "NFTYPass: Contract frozen");
        frozen = true;
    }

    function setSignerAddress(address signer) external onlyOwner {
        signerAddress = signer;
    }

    function setExpiryTime(uint256 tokenId, uint256 time) external onlyOwner {
        require(!frozen, "NFTYPass: Contract frozen");
        require(_exists(tokenId), "NFTYPass: Token does not exist");

        tokenExpiry[tokenId] = time;
    }

    function isExpired(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "NFTYPass: Token does not exist");

        return _isExpired(tokenId);
    }

    function expiryTime(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFTYPass: Token does not exist");

        return tokenExpiry[tokenId];
    }

    function _isTransferrable(uint256 tokenId) internal view returns (bool) {
        return
            !_isExpired(tokenId) &&
            (tokenExpiry[tokenId] - block.timestamp > 1 weeks);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            _isTransferrable(tokenId),
            "NFTYPass: Token must have at least 1 week remaining"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        require(!frozen, "NFTYPass: Contract frozen");
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function withdrawBalance() external onlyOwner {
        uint256 share = address(this).balance / 3;
        uint256 valueA = share * 2;
        uint256 valueB = share;

        (bool successA, ) = A.call{value: valueA}("");
        (bool successB, ) = B.call{value: valueB}("");

        require(successA && successB, "NFTYPass: Failed to withdraw");
    }
}
