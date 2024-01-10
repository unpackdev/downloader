// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/// @custom:security-contact xmichael446@gmail.com
contract SmartNFT is ERC1155, Ownable {
    bytes32 immutable MERKLE_ROOT;
    uint32 mintedCount = 0;
    uint32 vipClaimed = 0;
    address vipClient = 0xC2150aD829F5929b413c8b25Bb19B89309776c9D;

    mapping(address => uint8) whitelistClaimed;
    mapping(address => uint8) didMint;

    constructor(bytes32 _merkleRoot)
    ERC1155("ipfs://QmbmrujXMGTh8whsL7pGLLMW2F1hpZ1Lda7ULRECNQLVgZ/{id}.json")
    {
        MERKLE_ROOT = _merkleRoot;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint() public payable {
        require(msg.value >= 1 ether, "Not enough ether");
        require(!minted(msg.sender), "You have already minted a token");
        require(mintedCount < 50, "All tokens have been minted");

        payable(owner()).transfer(msg.value);

        _mint(msg.sender, 1, 1, "");
        didMint[msg.sender] = 1;
        mintedCount++;
    }

    function claim(bytes32[] calldata proof) external {
        require(isInWhitelist(msg.sender, proof), "You can't claim this token");
        require(!claimed(msg.sender), "You have already claimed this token");

        _mint(msg.sender, 1, 1, "");
        whitelistClaimed[msg.sender] = 1;
    }

    function vipClaim() external {
        require(msg.sender == vipClient, "You are not the VIP client");
        require(vipClaimed < 18, "All tokens have been claimed");

        _mint(vipClient, 1, 1, "");
        vipClaimed++;
    }

    function isInWhitelist(address claimer, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, MERKLE_ROOT, keccak256(abi.encodePacked(claimer)));
    }

    function claimed(address _owner) public view returns (bool) {
        return whitelistClaimed[_owner] == 1;
    }

    function minted(address _owner) public view returns (bool) {
        return didMint[_owner] == 1;
    }
}
