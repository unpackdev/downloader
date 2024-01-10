// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./AbstractOriginsV1.sol";

/*
* @title ERC1155 token for Zero to One Origins: Cover Art
*/
contract OriginsV1 is AbstractOriginsV1 {
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY;

    bytes32 public merkleRoot;

    mapping(address => bool) private wasClaimed;

    using Counters for Counters.Counter;
    Counters.Counter public totalMinted;

    event Withdraw(uint256 amount);

    constructor(string memory _uri, bytes32 _merkleRoot) ERC1155(_uri)  {
        contractName = "Zero to One Origins: Cover Art";
        contractSymbol = "ORIGINSV1";

        merkleRoot = _merkleRoot;

        MAX_SUPPLY = 99;
    }

    /**
    * @notice edit merkle root
    * @param newMerkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    /**
    * @notice claim your origins token
    * @param proof check you have purchased the nft
    */
    function claim(bytes32[] calldata proof) external payable whenNotPaused {
        require(totalMinted.current() + 1 <= MAX_SUPPLY, "all tokens claimed");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "acct not permitted to claim");
        require(!wasClaimed[msg.sender], "token already claimed");
        wasClaimed[msg.sender] = true;
        totalMinted.increment();
        _mint(msg.sender, 0, 1, "");
    }

    /**
    * @notice see if a token was claimed
    * @param account to be checked
    */
    function peekClaimed(address account) external view returns (bool){
        return wasClaimed[account];
    }

    /**
    * @notice returns the metadata uri
    * @param _id for this contract will always be 0
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function withdraw() external payable onlyOwner {
        uint256 bal = address(this).balance;

        address overagebounce = payable(0x429c71D391dB10a0cEaDE2CB2DE8C8c9AF4133c1);

        emit Withdraw(bal);
        (bool success, ) = overagebounce.call{value: bal}("");
        require(success, "txn failed");
    } 
}
