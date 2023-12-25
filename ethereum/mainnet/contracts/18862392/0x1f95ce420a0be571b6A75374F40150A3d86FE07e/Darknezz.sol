// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

import "./MerkleProof.sol";

contract Darknezz {

    error MaxSupplyReached();
    error UserMaxSupplyReached();
    error InvalidValue();
    error RequestingTooMany();
    error TransferFailed();
    error OnlyOwner();
    error WlMintNotActive();
    error MintNotActive();

    event Mint(address indexed minter, uint256 indexed amount, uint256 startID);

    uint256 public TOTAL_SUPPLY = 0;
    mapping (address=>uint16) balances;
    mapping (address=>uint16) wlBalances;
    uint256 public immutable WL_PRICE = 0.0055 * 1 ether;
    uint256 public immutable PRICE = 0.0110 * 1 ether;
    uint256 public immutable MAX_SUPPLY = 555;
    uint public immutable MAX_PER_WALLET_WL = 3;
    uint16 public immutable MAX_PER_WALLET = 5;
    bool public wlMintActive = false;
    bool public mintActive = false;
    bytes32 public merkleRoot;
    address OWNER;

    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert OnlyOwner();
        }
        _;
    }

    constructor (bytes32 _merkleRoot) {
        OWNER = msg.sender;
        merkleRoot = _merkleRoot;
    }

    function setWlMintActive(bool _wlMintActive) external onlyOwner {
        wlMintActive = _wlMintActive;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function getWlBalance(address _address) external view returns (uint16) {
        return wlBalances[_address];
    }

    function getBalance(address _address) external view returns (uint16) {
        return balances[_address];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setOwner(address _owner) external onlyOwner {
        OWNER = _owner;
    }

    function wlMint(uint256 amount,bytes32[] memory proof) external payable {
        if (!wlMintActive) { revert WlMintNotActive(); }
        if (TOTAL_SUPPLY == MAX_SUPPLY) { revert MaxSupplyReached(); }
        if ((TOTAL_SUPPLY + amount) > MAX_SUPPLY) { revert RequestingTooMany(); }
        if ((WL_PRICE * amount) != msg.value) { revert InvalidValue(); }
        if (wlBalances[msg.sender] + amount > MAX_PER_WALLET_WL) { revert UserMaxSupplyReached(); }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        emit Mint(msg.sender, amount, TOTAL_SUPPLY);
        
        unchecked {
            TOTAL_SUPPLY += amount;
            wlBalances[msg.sender] += uint16(amount);
        }
    }

    function mint(uint256 amount) external payable {
        if (!mintActive) { revert MintNotActive(); }
        if (TOTAL_SUPPLY == MAX_SUPPLY) { revert MaxSupplyReached(); }
        if ((TOTAL_SUPPLY + amount) > MAX_SUPPLY) { revert RequestingTooMany(); }
        if ((PRICE * amount) != msg.value) { revert InvalidValue(); }
        if (balances[msg.sender] + amount > MAX_PER_WALLET) { revert UserMaxSupplyReached(); }

        emit Mint(msg.sender, amount, TOTAL_SUPPLY);
        
        unchecked {
            TOTAL_SUPPLY += amount;
            balances[msg.sender] += uint16(amount);
        }
    }


    function withdraw() external onlyOwner {
        (bool success,) = address(OWNER).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }
}
