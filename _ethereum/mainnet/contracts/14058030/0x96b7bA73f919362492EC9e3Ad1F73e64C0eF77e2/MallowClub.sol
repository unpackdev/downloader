// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract MallowClub is Ownable, ERC721A {
    using MerkleProof for bytes32[];

    uint256 public constant MAX_SUPPLY = 6500;
    uint256 public constant PUBLIC_MINT_LIMIT = 10;
    uint256 public constant PRESALE_MINT_LIMIT = 2;

    uint256 public constant MINT_PRICE = 0.025 ether;

    /// @dev Inactive = 0; Presale = 1; Public = 2
    uint256 public saleFlag;

    bytes32 public merkleRoot;
    string public baseURI;
    bool public metadataLocked;
    
    mapping(address => uint256) private whitelistMints;

    constructor() ERC721A("Mallow Club", "MALLOW", PUBLIC_MINT_LIMIT, MAX_SUPPLY) {}

    modifier onlyUnlocked() {
        require(!metadataLocked, "METADATA_LOCKED");
        _;
    }

    function verifyProof(bytes32[] calldata _proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return _proof.verify(merkleRoot, leaf);
    }

    function lockMetadata() external onlyOwner {
        metadataLocked = true;
    }

    function setBaseURI(string calldata _base) external onlyOwner onlyUnlocked {
        baseURI = _base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setSaleState(uint256 _flag) external onlyOwner onlyUnlocked {
        saleFlag = _flag;
    }

    function setMerkleRoot(bytes32 _new) external onlyOwner {
        merkleRoot = _new;
    }

    function mint(uint256 _amount) external payable {
        require(totalSupply() + _amount <= MAX_SUPPLY, "MINT_EXCEEDS_TOTAL_SUPPLY");

        require(saleFlag == 2, "MINTING_PAUSED");
        require(_amount > 0 && _amount <= PUBLIC_MINT_LIMIT, "AMOUNT_TOO_HIGH");
        require(MINT_PRICE * _amount <= msg.value, "VALUE_TOO_LOW");
        require(tx.origin == msg.sender, "SENDER_IS_NOT_AN_EOA");

        _safeMint(msg.sender, _amount);
    }

    function mintWhitelist(uint256 _amount, bytes32[] calldata _proof) external payable {
        require(totalSupply() + _amount <= MAX_SUPPLY, "MINT_EXCEEDS_TOTAL_SUPPLY");

        require(saleFlag == 1, "MINTING_PAUSED");
        require(verifyProof(_proof), "INVALID_MERKLE_PROOF");
        require(whitelistMints[msg.sender] + _amount <= PRESALE_MINT_LIMIT, "MINT_EXCEEDS_LIMIT");
        require(_amount > 0 && _amount <= PRESALE_MINT_LIMIT, "AMOUNT_TOO_HIGH");
        require(MINT_PRICE * _amount <= msg.value, "VALUE_TOO_LOW");

        whitelistMints[msg.sender] += _amount;

        _safeMint(msg.sender, _amount);
    }

    function mintOwner(uint256 _amount, address _to) external onlyOwner onlyUnlocked {
        require(totalSupply() + _amount <= MAX_SUPPLY, "MINT_EXCEEDS_TOTAL_SUPPLY");

        _safeMint(_to, _amount);
    }   

    /** @notice
     * ALLOCATIONS:
     *  - Community Multisig: 20% (Signers: Bitquence, Pfpump, Mallow / 2 of 3 signatures)
     *  - Owners: 53%
     *  - Contract Dev: 12%
     *  - Advisor: 7.5%
     *  - Animator: 5%
     *  - Web Dev: 5%
     *  - Graphics: 2.5%
     */
    function withdraw() external onlyOwner {
        uint256 balanceDividend = address(this).balance / 1000;

        (bool sDev,) = address(0x91b26FffFfB325e13F1eF592b0933696098044Af).call{value: balanceDividend * 120}("");
        (bool sComm,) = address(0x672Ac43c28cE763Bea39bB8E195Db036C72209eE).call{value: balanceDividend * 200}("");
        (bool sPfpump,) = address(0xF82E94445Fed2F74A272C97Da8b2EFa9003B7d13).call{value: balanceDividend * 240}("");
        (bool sMallow,) = address(0x4cC3EB54b3ff22ffa1257453ca5d6b5d027fFffA).call{value: balanceDividend * 240}("");
        (bool sAnimator,) = address(0x43B7751Ce391c80C255141fd50fc41288374D36d).call{value: balanceDividend * 50}("");
        (bool sAdvisor,) = address(0x317D367663Edd9612Fbff00899F356F0E556380a).call{value: balanceDividend * 75}("");
        (bool sWeb,) = address(0xDd9A6283d8fb41AFcdCF29BF2884C9d3B9245cC7).call{value: balanceDividend * 50}("");
        (bool sGraphics,) = address(0x317b3a38C520228Ab3b9a6C70D5161530Af9DD40).call{value: balanceDividend * 25}("");
    }
}