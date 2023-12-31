// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IMintable.sol";
import "./MerkleProofLib.sol";

contract MintTranche {
    address payable public owner;
    IMintable public mintable;

    bytes32 public root;
    bool whitelistActive;

    uint256 public trancheRemaining;
    uint256 public trancheEnd;

    uint256 public mintPrice = 0.123 ether;

    mapping(address => uint256) public hasMinted;

    event TrancheCreated(uint amount, uint end);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function changeOwner(address payable _owner) external onlyOwner() {
        owner = _owner;
    }

    function setMintable(IMintable _mintable) external onlyOwner() {
        require(address(mintable) == address(0) && address(_mintable) != address(0));

        mintable = _mintable;
    }

    function setRoot(bytes32 _root) external onlyOwner() {
        root = _root;
    }

    function setWhitelist(bool _active) external onlyOwner(){
        whitelistActive = _active;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function createTranche(uint256 trancheAmount, uint256 endTime) public onlyOwner() {
        require(address(mintable) != address(0));
        
        trancheRemaining = trancheAmount;
        trancheEnd = endTime;

        emit TrancheCreated(trancheAmount, endTime);
    }

    function mint(uint256 amount, bytes32[] memory proof) payable public {
        require(block.timestamp < trancheEnd, 'Tranche not active');
        require(trancheRemaining >= amount, 'Not enough remaining in current tranche');
        require(msg.value == mintPrice * amount, 'wrong price');
        require(hasMinted[msg.sender] + amount <= 2, 'Mint limit 2');

        if (whitelistActive) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
            require(MerkleProofLib.verify(proof, root, leaf), "Invalid proof");
        }

        hasMinted[msg.sender] += amount;
        mintable.mint(address(msg.sender), amount);

        trancheRemaining = trancheRemaining - amount;
    }

    function withdraw() external onlyOwner() {
        (bool success, ) = owner.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }
}
