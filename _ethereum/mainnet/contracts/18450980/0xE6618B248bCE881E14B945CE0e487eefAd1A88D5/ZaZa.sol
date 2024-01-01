// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Math.sol";
import "./Strings.sol";

contract ZaZa is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public supplyCap = 5000;

    struct Pool {
        uint256 supply;
        uint256 minted;
        uint256 mintLimit;
        uint256 price;
    }

    Pool public freeWhitelistPool = Pool(3054, 0, 1, 0);
    Pool public paidWhitelistPool = Pool(446, 0, 2, 0.0059 ether);
    Pool public publicPool = Pool(1500, 0, 3, 0.0069 ether);

    bool public salesOpen = true;
    string private baseURL = "";
    bytes32 public merkleRoot;

    struct UserMintLimits {
        uint256 freeWhitelistLimit;
        uint256 paidWhitelistLimit;
        uint256 publicPoolLimit;
    }

    mapping(address => UserMintLimits) public userMintLimits;

    constructor() ERC721A("Smoking Zaza", "ZAZA") Ownable(msg.sender){}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "That token doesn't exist");
        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                )
                : "";
    }

    function setBaseUri(string memory _baseURL) public onlyOwner {
        baseURL = _baseURL;
    }

    function setMerkleRoot(bytes32 _newMerkle) public onlyOwner {
        merkleRoot = _newMerkle;
    }

    modifier canMint(Pool storage pool, uint256 amount) {
        require(salesOpen, "Sales are closed");
        require(amount > 0 && amount <= pool.mintLimit, "Invalid mint amount");
        require(
            supplyCap -
                freeWhitelistPool.minted -
                paidWhitelistPool.minted -
                publicPool.minted >=
                amount,
            "Not enough supply"
        );
        _;
    }

    function mintFreeWhitelist(
        bytes32[] calldata _merkleProof
    ) external canMint(freeWhitelistPool, 1) {
        require(
            userMintLimits[msg.sender].freeWhitelistLimit + 1 <=
                freeWhitelistPool.mintLimit,
            "Exceeds mint limit"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        require(
            freeWhitelistPool.supply > freeWhitelistPool.minted,
            "No more free whitelist tokens available"
        );
        freeWhitelistPool.minted++;
        userMintLimits[msg.sender].freeWhitelistLimit++;
        _safeMint(msg.sender, 1);
    }

    function mintPaidWhitelist(
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) external payable canMint(paidWhitelistPool, amount) {
        require(
            userMintLimits[msg.sender].paidWhitelistLimit + amount <=
                paidWhitelistPool.mintLimit,
            "Exceeds mint limit"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        require(
            msg.value >= amount * paidWhitelistPool.price,
            "Insufficient funds"
        );
        require(
            paidWhitelistPool.supply - paidWhitelistPool.minted >= amount,
            "Not enough paid whitelist supply"
        );
        paidWhitelistPool.minted += amount;
        userMintLimits[msg.sender].paidWhitelistLimit += amount;
        _safeMint(msg.sender, amount);
    }

    function mintPublic(
        uint256 amount
    ) external payable canMint(publicPool, amount) {
        require(
            userMintLimits[msg.sender].publicPoolLimit + amount <=
                publicPool.mintLimit,
            "Exceeds mint limit"
        );

        require(msg.value >= amount * publicPool.price, "Insufficient funds");
        require(
            publicPool.supply - publicPool.minted >= amount,
            "Not enough public pool supply"
        );
        publicPool.minted += amount;
        userMintLimits[msg.sender].publicPoolLimit += amount;
        _safeMint(msg.sender, amount);
    }

    function setOpenSales(bool _salesOpen) external onlyOwner {
        salesOpen = _salesOpen;
    }

    function editFreeWhitelistPool(
        uint256 _supply,
        uint256 _limit
    ) external onlyOwner {
        freeWhitelistPool.supply = _supply;
        freeWhitelistPool.mintLimit = _limit;
    }

    function editPaidWhitelistPool(
        uint256 _supply,
        uint256 _limit,
        uint256 _price
    ) external onlyOwner {
        paidWhitelistPool.supply = _supply;
        paidWhitelistPool.mintLimit = _limit;
        paidWhitelistPool.price = _price;
    }

    function editPublicPool(
        uint256 _supply,
        uint256 _limit,
        uint256 _price
    ) external onlyOwner {
        publicPool.supply = _supply;
        publicPool.mintLimit = _limit;
        publicPool.price = _price;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
