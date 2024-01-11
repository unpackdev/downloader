// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
                                           
 ,----.   ,--.,------.    ,---.   ,-----.  
'  .-./   |  ||  .-.  \  /  O  \ '  .-.  ' 
|  | .---.|  ||  |  \  :|  .-.  ||  | |  | 
'  '--'  ||  ||  '--'  /|  | |  |'  '-'  ' 
 `------' `--'`-------' `--' `--' `-----'  
                                           
 */

contract GIFounderPass is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant RESERVE_TOKEN_AMOUNT = 200;

    uint256 private constant MAX_MINTS_PER_TRANSACTION = 10;
    uint256 private constant MAX_WL_MINTS = 2;

    mapping(address => uint256) public whitelistMinted;

    uint256 public tokenIdCounter;

    string public baseTokenURI;

    uint256 public publicMintPrice = 0.15 ether;
    uint256 public whitelistMintPrice = 0.12 ether;

    bool public isWhitelistMintActive = false;
    bool public isPublicMintActive = false;

    bytes32 public whitelistMerkleRoot;

    constructor() ERC721("GI Founder Pass", "GIFP") {}

    function whitelistMint(
        uint256 numberOfMints,
        bytes32[] calldata _merkleProof
    ) external payable {
        //state
        require(isWhitelistMintActive, "WHITE_LIST_MINT_NOT_ACTIVE");
        //proof
        require(
            isWhitelistEligible(msg.sender, _merkleProof),
            "ADDRESS_NOT_ELIGIBLE_FOR_WHITELIST_MINT"
        );
        //allowed amount
        require(
            whitelistMinted[msg.sender] + numberOfMints <= MAX_WL_MINTS,
            "EXCEEDS_WHITELIST_ALLOWED_AMOUNT"
        );
        //price
        require(
            msg.value >= numberOfMints * whitelistMintPrice,
            "INSUFFICIENT_PAYMENT"
        );
        //total supply
        require(
            totalSupply() + numberOfMints <= MAX_SUPPLY,
            "EXCEEDS_MAX_SUPPLY"
        );

        for (uint32 i = 0; i < numberOfMints; i++) {
            tokenIdCounter++;
            _safeMint(msg.sender, tokenIdCounter);
        }

        whitelistMinted[msg.sender] += numberOfMints;
    }

    function isWhitelistEligible(address addr, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function publicMint(uint256 numberOfMints) external payable {
        //state
        require(isPublicMintActive, "PUBLIC_MINT_NOT_ACTIVE");
        //numberOfMints
        require(numberOfMints > 0, "INVALID_PURCHASE_AMOUNT");
        //per tx
        require(
            numberOfMints <= MAX_MINTS_PER_TRANSACTION,
            "EXCEEDS_MAX_MINTS_PER_TRANSACTION"
        );
        //price
        require(
            msg.value >= numberOfMints * publicMintPrice,
            "INSUFFICIENT_PAYMENT"
        );
        //total supply
        require(
            totalSupply() + numberOfMints <= MAX_SUPPLY,
            "EXCEEDS_MAX_SUPPLY"
        );

        for (uint32 i = 0; i < numberOfMints; i++) {
            tokenIdCounter++;
            _safeMint(msg.sender, tokenIdCounter);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenURI,
                        Strings.toString(tokenId),
                        ""
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /** Only Owner */

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function toggleWhitelistMintActive() external onlyOwner {
        isWhitelistMintActive = !isWhitelistMintActive;
    }

    function togglePublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function reserveToken() public onlyOwner {
        for (uint256 i = 0; i < RESERVE_TOKEN_AMOUNT; i++) {
            tokenIdCounter++;
            _safeMint(msg.sender, tokenIdCounter);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}
