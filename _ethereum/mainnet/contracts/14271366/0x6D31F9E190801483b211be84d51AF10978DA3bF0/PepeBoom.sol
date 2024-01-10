// SPDX-License-Identifier: MIT

/*
                                                              ▒▒▓▓▒▒
                                                            ▓▓░░  ░░▒▒
                                                        ░░▓▓        ▒▒
                                                        ▓▓            ░░
                                          ░░▒▒▒▒░░    ▒▒              ▓▓
                                          ▒▒▒▒▒▒▒▒▒▒▒▒▓▓              ▓▓
                                        ░░▒▒▒▒▒▒▒▒▒▒▓▓▒▒░░            ▓▓                    ░░░░░░░░
                                      ░░▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒░░            ░░            ░░  ░░░░░░░░░░
                          ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒            ▓▓            ░░░░▒▒▒▒▒▒▒▒▒▒░░░░
                    ░░░░  ░░  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒            ▓▓          ░░░░▒▒▒▒▒▒▒▒▓▓░░░░░░
                ░░▒▒▒▒▒▒      ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒            ░░        ░░  ▒▒▒▒▒▒▓▓▓▓▓▓▒▒░░
              ░░▒▒▒▒▒▒▒▒      ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░              ▒▒          ░░▒▒▓▓▓▓▓▓▓▓▒▒░░░░
            ▒▒▒▒▒▒▒▒▒▒░░        ▒▒░░▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒                ▓▓              ▓▓▓▓▓▓▒▒▒▒░░
          ▒▒▒▒▒▒▒▒▒▒▒▒              ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░              ░░▓▓          ▒▒░░░░░░░░░░░░░░
        ░░▒▒▒▒▒▒▓▓▓▓░░                ░░░░  ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒                ▒▒▒▒    ░░▓▓▒▒    ░░░░  ░░░░
        ▒▒▒▒▓▓▒▒▓▓░░                    ░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒                  ░░░░░░
      ▒▒▒▒▓▓▓▓▓▓░░                ░░░░    ░░▒▒░░        ▒▒▒▒▒▒░░
      ▒▒▓▓▓▓▓▓▓▓░░░░░░          ░░▒▒▒▒▓▓    ▒▒▒▒          ▒▒▒▒▒▒░░
    ░░▒▒▓▓▓▓▓▓▓▓░░░░░░░░          ▓▓▒▒  ▒▒  ░░▓▓          ▒▒▒▒▒▒░░
    ▒▒▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░        ░░▓▓    ░░▒▒▒▒        ░░▒▒▒▒▒▒
  ░░▒▒▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░▒▒  ░░      ░░▒▒▒▒      ▒▒▒▒▒▒▒▒▒▒░░
  ▒▒▒▒▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░  ░░          ▒▒▒▒▒▒░░▒▒▒▒▒▒  ▒▒▒▒░░
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░  ░░░░▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▒▒▒▒░░░░░░░░▒▒▓▓░░▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒  ░░
  ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░▒▒░░
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒▒░░
    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░
      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░
      ▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░
        ▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░
        ░░▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░
          ▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░
            ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒
              ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓██████████▓▓▓▓░░
                ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▒▒
                      ▓▓████████████████████▒▒
                      ░░  ▒▒▓▓██████▓▓▒▒░░      PΞPΞ BooM
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract PepeBoom is ERC721A, Ownable {
    
    // Presale parameters
    bool public isPresaleActive; // Presale Active
    bytes32 public claimRoot; // Merkle Root for Claim
    uint256 private claimQuantityAllowed; // Max claim per wallet
    mapping(address => uint256) private claimRedeemedCount; // Tracks redeem for claim

    uint256 public presalePrice; // Price
    uint256 private presaleMaxPerWallet; // Max per wallet for presale
    bytes32 public presaleRoot; // Merkle Root for Presale
    mapping(address => uint256) private presaleRedeemedCount; // Tracks redeem for presale

    // Public sale parameters
    bool public isSaleActive; // Sale Active
    uint256 public salePrice; // Price
    uint256 private saleMaxPerWallet; // Max per wallet for public sale
    mapping(address => uint256) private saleRedeemedCount; // Tracks redeem for sale

    uint256 public tokenSupply; // Max Amount
    string private baseURI; // Base URI

    uint256 private immutable maxBatchSize; // Max batch size for minting

    constructor(
        uint256 claimQuantityAllowed_,
        uint256 presalePrice_,
        uint256 presaleMaxPerWallet_,
        uint256 salePrice_,
        uint256 saleMaxPerWallet_,
        uint256 tokenSupply_,
        uint256 maxBatchSize_
    )
        ERC721A("Pepe Boom", "PPB")
    {
        claimQuantityAllowed = claimQuantityAllowed_;
        presalePrice = presalePrice_;
        presaleMaxPerWallet = presaleMaxPerWallet_;
        salePrice = salePrice_;
        saleMaxPerWallet = saleMaxPerWallet_;
        tokenSupply = tokenSupply_;
        maxBatchSize = maxBatchSize_;
        isPresaleActive = false;
        isSaleActive = false;
    }

    function claim(uint256 quantity, bytes32[] calldata proof) external {
        require(isPresaleActive, "Presale Not Active");
        require(MerkleProof.verify(proof, claimRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");
        require(claimQuantityAllowed >= claimRedeemedCount[_msgSender()] + quantity, "Exceeded Max Claim" );

        claimRedeemedCount[_msgSender()] = claimRedeemedCount[_msgSender()] + quantity;

        _mintToken(_msgSender(), quantity);
    }

    function mint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(isPresaleActive, "Presale Not Active");
        require(msg.value >= presalePrice * quantity, "Insufficient funds");
        require(MerkleProof.verify(proof, presaleRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");
        require(presaleMaxPerWallet >= presaleRedeemedCount[_msgSender()] + quantity, "Max Minted");
        require(quantity <= presaleMaxPerWallet, "Exceeded Max Quantity");

        presaleRedeemedCount[_msgSender()] = presaleRedeemedCount[_msgSender()] + quantity;

        _mintToken(_msgSender(), quantity);
    }

    function mint(uint256 quantity) external payable {
        require(isSaleActive, "Public Sale Not Active");
        require(msg.value >= salePrice * quantity, "Insufficient funds");
        require(saleMaxPerWallet >= saleRedeemedCount[_msgSender()] + quantity, "Max Minted");

        saleRedeemedCount[_msgSender()] = saleRedeemedCount[_msgSender()] + quantity;

        _mintToken(_msgSender(), quantity);
    }

    function isEligiblePresale(bytes32[] calldata proof, address address_) external view returns (bool)
    {
        return MerkleProof.verify(proof, presaleRoot, keccak256(abi.encodePacked(address_)));
    }

    /*
        Owner functions
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setTokenSupply(uint256 supply) external onlyOwner {
        require(supply > totalSupply(), "Can't be less than totalSupply");
        tokenSupply = supply;
    }

    // Claim functions
    function setClaimRoot(bytes32 root) external onlyOwner {
        claimRoot = root;
    }

    // Presale functions
    function setPresaleRoot(bytes32 root) external onlyOwner {
        presaleRoot = root;
    }

    function setPresalePrice(uint256 price) external onlyOwner {
        presalePrice = price;
    }

    function setPresaleMaxPerWallet(uint256 maxPresaleTokensPerWallet) external onlyOwner {
        presaleMaxPerWallet = maxPresaleTokensPerWallet;
    }
    
    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    // Public sale functions
    function setSalePrice(uint256 price) external onlyOwner {
        salePrice = price;
    }

    function setSaleMaxPerWallet(uint256 maxSaleTokensPerWallet) external onlyOwner {
        saleMaxPerWallet = maxSaleTokensPerWallet;
    }

    function toggleSaleActive() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    // Owner direct mint to address
    function mintTokens(address to, uint256 quantity) external onlyOwner {
        _mintToken(to, quantity);
    }

    // Withdraw funds
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to whitdraw funds");
    }

    // Private functions
    function _mintToken(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= tokenSupply, "Exceeded Max");
        require(quantity <= maxBatchSize, "Exceeded Max Batch Size");

        _safeMint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}