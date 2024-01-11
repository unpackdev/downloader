//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract Cyberzuki2077 is ERC721A, Ownable {
    // sale config
    bool public SALE_OPEN = false;
    bool public FREE_CLAIM_OPEN = false;
    uint256 public PRICE = 0.05 ether;
    uint256 public AVAILABLE_SUPPLY = 7777;
    uint256 public MAX_PER_TX = 5;
    uint256 public MAX_PER_ADDRESS = 100;
    uint256 public AVAILABLE_FREE_MINTS = 250;
    bytes32 public MERKLE_ROOT = 0x0;

    // mints per address counter
    mapping(address => uint256) public mintedAmounts;

    // inherit
    string public baseURI = "";

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    // sale state
    function flipSaleOpen() external onlyOwner {
        SALE_OPEN = !SALE_OPEN;
    }

    // free claim state
    function flipFreeClaimOpen() external onlyOwner {
        FREE_CLAIM_OPEN = !FREE_CLAIM_OPEN;
    }

    function mint(uint256 _amount, bytes32[] memory _proof) external payable {
        require(SALE_OPEN, "Sale not started");
        require(totalSupply() + _amount <= AVAILABLE_SUPPLY, "Higher than available supply");
        require(_amount <= MAX_PER_TX, "Higher than available per transaction");
        require(mintedAmounts[msg.sender] + _amount <= MAX_PER_ADDRESS, "Higher than available per wallet");
        require(_amount > 0, "Amount must be above zero");

        bool hasFreeMint = addressHasFreeMint(msg.sender, _proof);
        require((_amount - (hasFreeMint ? 1 : 0)) * PRICE <= msg.value, "Not enough ETH received");

        if (hasFreeMint) {
            AVAILABLE_FREE_MINTS = AVAILABLE_FREE_MINTS - 1;
        }

        mintedAmounts[msg.sender] = mintedAmounts[msg.sender] + _amount;
        _safeMint(msg.sender, _amount);
    }

    // free mint helper
    function addressHasFreeMint(address _address, bytes32[] memory _proof) public view returns (bool) {
        if (mintedAmounts[_address] > 0 || totalSupply() == AVAILABLE_SUPPLY) return false;

        return (FREE_CLAIM_OPEN && AVAILABLE_FREE_MINTS > 0)
            || MerkleProof.verify(_proof, MERKLE_ROOT, keccak256(abi.encodePacked(_address)));
    }

    // admin mints
    function privateMint(uint256 _amount, address _receiver) external onlyOwner {
        require(totalSupply() + _amount <= AVAILABLE_SUPPLY, "Higher than available supply");
        _safeMint(_receiver, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function changeMaxPerTx(uint256 _newValue) external onlyOwner {
        MAX_PER_TX = _newValue;
    }

    function changeMaxPerAddress(uint256 _newValue) external onlyOwner {
        MAX_PER_ADDRESS = _newValue;
    }

    function changeAvailableFreeMints(uint256 _newValue) external onlyOwner {
        AVAILABLE_FREE_MINTS = _newValue;
    }

    function setNewMerkleRoot(bytes32 _newValue) external onlyOwner {
        MERKLE_ROOT = _newValue;
    }

    function changePrice(uint256 _newValue) external onlyOwner {
        PRICE = _newValue;
    }

    // admin withdraw
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
