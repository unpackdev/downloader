// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

/**
 * @title Galactic Konquest contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract Konquest is ERC721A, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // Metadata
    string private constant TOKEN_NAME = 'Galactic Konquest';
    string private constant TOKEN_SYMBOL = 'GK';
    uint private constant KONQUEST_RESERVED = 299;
    uint private constant MAX_KONQUESTS = 999;
    uint public constant MAX_PURCHASE_PER_ONCE = 1;
    uint256 public constant KONQUEST_PRICE = 40000000000000000; // 0.04 ETH per 1 token
    uint public SALE_WHITELIST_A_TIMESTAMP = 1703250000; // Friday, December 22, 2023 8:00:00 PM GMT+07:00
    uint public SALE_WHITELIST_B_TIMESTAMP = 1703257200; // Friday, December 22, 2023 10:00:00 PM GMT+07:00
    uint public SALE_START_TIMESTAMP = 1703260800; // Friday, December 22, 2023 11:00:00 PM GMT+07:00
    uint public REVEAL_TIMESTAMP = 1703682000; // Wednesday, December 27, 2023 8:00:00 PM GMT+07:00
    string public KONQUEST_PROVENANCE = '';
    bool public konquestIsReserved = false;
    bool public saleIsActive = false;
    string private _baseTokenURI;

    // Mapping from address to bool to check if the address has already minted
    mapping(address => bool) private _hasMinted;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Set starting index logic
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    constructor() ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {}

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        KONQUEST_PROVENANCE = provenanceHash;
    }

    /*
     * Set timestamp for all sale tiers
     * tier = 1 if whitelistA
     * tier = 2 if whitelistB
     * tier = 3 if public sale
     * tier = 4 if reveal timestamp
     */
    function setTimestamp(uint8 tier, uint256 timestamp) public onlyOwner {
        if (tier == 1) {
            SALE_WHITELIST_A_TIMESTAMP = timestamp;
        } else if (tier == 2) {
            SALE_WHITELIST_B_TIMESTAMP = timestamp;
        } else if (tier == 3) {
            SALE_START_TIMESTAMP = timestamp;
        } else if (tier == 4) {
            REVEAL_TIMESTAMP = timestamp;
        } else {
            revert('Invalid tier');
        }
    }

    /*
     * Get base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * Set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Reserve Konquests
     */
    function reserveKonquests() public onlyOwner {
        require(!konquestIsReserved, 'Konquest is already reserved');

        // mint tokens
        _safeMint(msg.sender, KONQUEST_RESERVED);

        konquestIsReserved = true;
    }

    /**
     * Mint Konquests
     * tier = 1 if whitelistA
     * tier = 2 if whitelistB
     * tier = 3 if public sale
     */
    function mintKonquest(
        uint numberOfTokens,
        uint8 tier,
        bytes memory signature
    ) public payable {
        require(saleIsActive, 'Sale is not active');
        require(!_hasMinted[msg.sender], 'Caller has already minted');
        if (tier == 1 || tier == 2) {
            require(
                verifySignatureMatchTierAndSender(tier, signature),
                'Caller is not in the whitelist'
            );
        }
        if (tier == 1) {
            require(
                block.timestamp >= SALE_WHITELIST_A_TIMESTAMP,
                'Sale has not started for whitelist A'
            );
        } else if (tier == 2) {
            require(
                block.timestamp >= SALE_WHITELIST_B_TIMESTAMP,
                'Sale has not started for whitelist B'
            );
        } else if (tier == 3) {
            require(
                block.timestamp >= SALE_START_TIMESTAMP,
                'Sale has not started for public sale'
            );
        } else {
            revert('Invalid tier');
        }
        require(
            numberOfTokens <= MAX_PURCHASE_PER_ONCE,
            'Can only mint 1 token at a time'
        );
        require(
            totalSupply() + numberOfTokens <= MAX_KONQUESTS,
            'Purchase would exceed max supply of Konquests'
        );
        require(
            KONQUEST_PRICE * numberOfTokens <= msg.value,
            'Ether value sent is not correct'
        );

        // mint tokens
        _safeMint(msg.sender, numberOfTokens);

        // flag that the address has minted
        _hasMinted[msg.sender] = true;

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_KONQUESTS ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, 'Starting index is already set');
        require(startingIndexBlock != 0, 'Starting index block must be set');

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_KONQUESTS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - (startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_KONQUESTS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, 'Starting index is already set');

        startingIndexBlock = block.number;
    }

    /**
     * Get token ids of the tokens owned by the address at index.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * Override _afterTokenTransfers to update the token owners
     * token mint, burn and transfer will call this function
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        for (uint256 i = 0; i < quantity; i++) {
            _holderTokens[from].remove(startTokenId + i);
            _holderTokens[to].add(startTokenId + i);
        }
    }

    /**
     * Verify signature match tier and sender
     * by checking if the signature is signed by the owner
     */
    function verifySignatureMatchTierAndSender(
        uint8 tier,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, tier));
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(msgHash);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        address signer = ecrecover(_ethSignedMessageHash, v, r, s);
        return signer == owner();
    }

    /**
     * Split signature into r, s, v
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * Get eth signed message hash
     */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    _messageHash
                )
            );
    }
}
