// SPDX-License-Identifier: MIT

/// @title SharkDAO Commemorative Nfts Contract

/***********************************************************
------------------------░░░░░░░░----------------------------
--------------------------░░░░░░░░░░------------------------
----------------------------░░░░░░░░░░----------------------
----░░----------------------░░░░░░░░░░░░--------------------
------░░----------------░░░░░░░░░░░░░░░░░░░░░░--------------
------░░░░----------░░░░░░░░░░░░░░░░░░░░░░░░░░░░------------
------░░░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░░░░░--░░░███████████░░███████████░░░░░░░░░--------
--------░░░░░░░░░░░██    █████░░██    █████░░░░░░░░░░░------
----------░░█████████    █████████    █████░░░░░░░░░░░------
----------░░██░░░░░██    █████░░██    █████░░░░░░░░░--------
--------░░░░░░--░░░███████████░░███████████░░░░░░░----------
--------░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░------░░░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░------------
------░░--------░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░░░------------
----------------░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░--------------
----------------░░░░░░████░░░░░██░░░░░██░░░░----------------
----------------░░░░--██░░██░██░░██░██░░██░░----------------
----------------░░░░--██░░██░██████░██░░██░░----------------
----------------░░░░--████░░░██░░██░░░██░░░░----------------
----------------░░░░--░░░░░░░░░░░░░░░░░░░░░░----------------
************************************************************/

/// @author Rayo ⚡️
/*
 *                                     ,/
 *     ____                          ,'/
 *    / __ \____ ___  ______       ,' /
 *   / /_/ / __ `/ / / / __ \    ,'  /_____
 *  / _, _/ /_/ / /_/ / /_/ /  .'____    ,'      
 * /_/ |_|\__,_/\__, /\____/        /  ,'
 *             /____/              / ,'
 *                                /,'
 *                               /' 
 */

pragma solidity ^0.8.4;

import "./AbstractSharkDaoNfts.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./MerkleProof.sol";

contract SharkDaoNfts is AbstractSharkDaoNfts {

    mapping(uint256 => CommemorativeNft) public commemorativeNfts;

    event MintedSharkNft(uint index, address indexed account, uint amount);
    event AddedProject(bytes32 merkleRoot, string ipfsMetadataHash, uint indexed id, uint mintCost);

    struct CommemorativeNft {
        uint256 mintCost;
        bytes32 merkleRoot;
        string ipfsMetadataHash;
    }
    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;

    }

    function mintCommemorativeShark(
        uint256 _nounId,
        bytes32[] calldata merkleProof
    ) external payable {
        require(commemorativeNfts[_nounId].merkleRoot != bytes32(0), "Project does not exist");
        require(balanceOf(msg.sender, _nounId) < 1, "Already claimed this Nft");
        require(msg.value >= commemorativeNfts[_nounId].mintCost, "Mint: Ether Value incorrect");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(_verify(merkleProof, node, _nounId), "Invalid proof");
        
        uint excessPayment = msg.value - commemorativeNfts[_nounId].mintCost;
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        _mint(msg.sender, _nounId, 1, "");

        emit MintedSharkNft(_nounId, msg.sender, 1);
    }
   
    function addNftProject(
        bytes32 _merkleRoot,
        string memory _ipfsMetadataHash,
        uint256 _id,
        uint256 _mintCost
    ) external onlyOwner {
        require(commemorativeNfts[_id].merkleRoot == bytes32(0), "Project ID has already been initialized");
        CommemorativeNft storage project = commemorativeNfts[_id];
        project.merkleRoot = _merkleRoot;
        project.ipfsMetadataHash = _ipfsMetadataHash;
        project.mintCost = _mintCost;

        emit AddedProject(_merkleRoot, _ipfsMetadataHash, _id, _mintCost);
    }

    function editNftProject(
        bytes32 _merkleRoot,  
        string memory _ipfsMetadataHash,
        uint256 _id,
        uint256 _mintCost
    ) external onlyOwner {
        require(commemorativeNfts[_id].merkleRoot != bytes32(0), 
            "Project does not exist, please create before editing");
        
        commemorativeNfts[_id].merkleRoot = _merkleRoot;
        commemorativeNfts[_id].ipfsMetadataHash = _ipfsMetadataHash;    
        commemorativeNfts[_id].mintCost = _mintCost;    
    }       

    function uri(uint256 _id) public view override returns (string memory) {
        require(commemorativeNfts[_id].merkleRoot != bytes32(0), "Token does not exist");
        return string (abi.encodePacked(super.uri(_id), commemorativeNfts[_id].ipfsMetadataHash));

    }

    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _verify(
        bytes32[] memory _proof,
        bytes32 _leaf,
        uint256 _id
    ) private view returns (bool) {
        bytes32 root = commemorativeNfts[_id].merkleRoot;
        return MerkleProof.verify(_proof, root, _leaf);
    }
}

