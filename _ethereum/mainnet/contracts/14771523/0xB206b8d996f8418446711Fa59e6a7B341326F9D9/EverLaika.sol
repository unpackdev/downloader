// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract EverLaika is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint;
    enum State { INACTIVE, ALLOWLIST, PUBLIC }

    struct Sale {
        State state;
        uint allowlistPrice;
        uint publicPrice;
        uint maxMintsPerAddress;
    }

    uint public constant MAX_TOKENS = 6000;
    Sale public sale;
    bool public revealed;
    bytes32 public allowlistMerkleRoot;

    // Free mint balance of each address.
    mapping(address => uint) public freeMintMap;
    // Minted amount of each address (Allowlist and public mint).
    mapping(address => uint) public tokenMinted;

    string private _unrevealedURI;
    string private _baseURI_;
  
    constructor() ERC721A("EverLaika", "LAIKA") {}
  
    /**
    * Customer functions
    */
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (!revealed) {
            return _unrevealedURI;
        }
        return bytes(_baseURI_).length > 0 ? string(abi.encodePacked(_baseURI_, tokenId.toString())) : "";
    }

    function isAllowlisted(address to, bytes32[] calldata proof) external view returns (bool) {
        return _checkAllowlist(to, proof);
    }

    function allowlistMint(uint amount, bytes32[] calldata proof) external payable nonReentrant {
        require(sale.state == State.ALLOWLIST || sale.state == State.PUBLIC, "Allowlist mint is inactive");
        require(_checkAllowlist(_msgSender(), proof), "Allowlist mint only");
        _doMint(_msgSender(), msg.value, amount, sale.allowlistPrice);
    }

    function mint(uint amount) external payable nonReentrant {
        require(sale.state == State.PUBLIC, "Public mint is inactive");
        _doMint(_msgSender(), msg.value, amount, sale.publicPrice);
    }

    function freeMint(uint amount) external nonReentrant {
        require(sale.state != State.INACTIVE, "Sale is inactive");
        require(amount > 0, "Invalid mint amount");
        require(totalSupply() + amount <= MAX_TOKENS, "Max tokens exceeded");
        require(freeMintMap[_msgSender()] >= amount, "Max mints exceeded");
        freeMintMap[_msgSender()] -= amount;
        _safeMint(_msgSender(), amount);
    }

    /**
    * Owner functions
    */
    function setSaleDetails(uint state, uint price, uint maxMintsPerAddress) external onlyOwner {
        sale.state = State(state);
        if (sale.state == State.ALLOWLIST) {
            sale.allowlistPrice = price;
        } else if (sale.state == State.PUBLIC) {
            sale.publicPrice = price;
        }
        sale.maxMintsPerAddress = maxMintsPerAddress;
    }

    function setAllowlistMerkleRoot(bytes32 allowlistMerkleRoot_) external onlyOwner {
        allowlistMerkleRoot = allowlistMerkleRoot_;
    }

    function setFreeMintMap(address[] memory accounts, uint[] memory amounts) external onlyOwner {
        require(accounts.length > 0, "Empty mint accounts");
        require(accounts.length == amounts.length, "Mismatched mint amounts");
        for (uint i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) revert("Receiver should be non-zero address");
            require(amounts[i] >= 0, "Invalid mint amount");
            freeMintMap[accounts[i]] = amounts[i];
        }
    }

    function toggleRevealed() external onlyOwner() {
        revealed = !revealed;
    }

    function setUnrevealedURI(string memory unrevealedURI) external onlyOwner {
        _unrevealedURI = unrevealedURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI_ = baseURI;
    }

    /**
     * Every address in `accounts` will receive `amount` airdrops.
     */
    function airdrop(address[] memory accounts, uint amount) external onlyOwner {
        require(accounts.length > 0, "Invalid airdrop destinations");
        require(amount > 0, "Invalid mint amount");
        require(totalSupply() + accounts.length * amount <= MAX_TOKENS, "Max tokens exceeded");
        for (uint i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], amount);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(_msgSender()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    /**
    * Helper functions
    */
    function _leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(bytes(payload));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, allowlistMerkleRoot, leaf);
    }

    function _checkAllowlist(address to, bytes32[] memory proof) internal view returns (bool) {
        require(allowlistMerkleRoot != 0, "Allowlist is not open");
        string memory payload = string(abi.encodePacked(to));
        return _verify(_leaf(payload), proof);
    }

    /**
    * Allowlist mint and public mint.
    */
    function _doMint(address to, uint value, uint amount, uint price) internal {
        require(amount > 0, "Invalid mint amount");
        require(totalSupply() + amount <= MAX_TOKENS, "Max tokens exceeded");
        require(value >= price * amount, "Ether value sent is insufficient");
        require(tokenMinted[to] + amount <= sale.maxMintsPerAddress, "Max mints per address exceeded");
        tokenMinted[to] += amount;
        _safeMint(to, amount);
    }
}
