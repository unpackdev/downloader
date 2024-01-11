// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./PullPayment.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Elite is ERC721, PullPayment, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 999;
    uint256 public constant MINT_PRICE = 1.5 ether;
    bytes32 public merkleRoot;
    uint256 public mintStart = 1655661600;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("Elite Collective Pass", "Elite") {
        baseTokenURI = "ipfs://QmRDs5Bby2rkwttVzMcuD8YCzkMEFbr5YwbdWxQ3vdQy7C";
    }

    /// @notice start minting process.
    function mint(address recipient) external payable returns (uint256) {
        require(block.timestamp > mintStart, "Minting is not enabled");
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        require(
            msg.value == MINT_PRICE,
            "Transaction value did not equal the mint price"
        );
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        _asyncTransfer(owner(), msg.value);
        return newItemId;
    }
    
    /// @notice start minting process for addresses with proof.No need to use this if mint() is enabled
    function mintFromList(address recipient, bytes32[] calldata proof) external payable returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        require(
            msg.value == MINT_PRICE,
            "Transaction value did not equal the mint price"
        );
        require(isWalletOnMintList(recipient, proof), "Wallet verification failed");
        
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        _asyncTransfer(owner(), msg.value);
        return newItemId;
    }
    function isWalletOnMintList(address recipient, bytes32[] calldata proof) private view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(recipient)));
    }
    /// @dev Sets MerkleRoot for allowed addresses.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    /// @dev Sets minting start time.
    function changeStartDate(uint256 _Start) public onlyOwner {
        mintStart = _Start;
    }
    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Sends minting fees to owner.
    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
    {
        super.withdrawPayments(payee);
    }

    /// @notice Returns the token's metadata URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(ERC721._exists(tokenId), "Token doesn't exist");
        return baseTokenURI;
    }
    /// @notice Returns the number of minted tokens.
    function totalSupply() external view returns (uint256) {
        return currentTokenId.current();
    }
}
