// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

contract GOBToken is ERC1155, Ownable, ERC1155Burnable, Pausable {

    using SafeMath for uint256;

    bytes32 public merkleRoot;
    mapping (address => bool) redeemableContracts;
    mapping(address => uint256) public claimedMPs;

    event Claimed(address indexed account, uint amount);

    constructor(string memory _uri, bytes32 _merkleRoot) ERC1155(_uri) {
        merkleRoot = _merkleRoot;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _leaf(address account, uint256 amount) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function claim(uint256 amount, bytes32[] calldata proof) public whenNotPaused {
        require(claimedMPs[msg.sender] < amount, "Claim: Not allowed to claim given amount");
        require(_verify(_leaf(msg.sender, amount), proof), "Invalid merkle proof");
        uint256 numberToClaim = amount.sub(claimedMPs[msg.sender]);
        claimedMPs[msg.sender] = claimedMPs[msg.sender].add(numberToClaim);
        _mint(msg.sender, 0, numberToClaim, "");
        emit Claimed(msg.sender, numberToClaim);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function forceMint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        claimedMPs[account] = claimedMPs[account].add(amount);
        _mint(account, id, amount, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

   function burnFromRedeem(
        address account, 
        uint256 index, 
        uint256 amount
    ) external {
        require(redeemableContracts[msg.sender] == true, "Burnable: Only allowed from redeemable contract");
        _burn(account, index, amount);
    } 

    function updateAuthorizedContract(address contractAddress, bool isAuthorized) public onlyOwner {
        redeemableContracts[contractAddress] = isAuthorized;
    }
}



