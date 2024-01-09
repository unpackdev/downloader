// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";


contract ZazzyZebras is ERC721A, Ownable {
    
    using Strings for uint256;
    address breedingContract;
   
    string public baseApiURI;
    bytes32 private whitelistRoot;
   

    //Inventory
    uint16 public maxMintAmountPerTransaction = 4;
    uint16 public maxMintAmountPerWallet = 4;
    uint16 public maxMintAmountPerWhitelist = 2;
    uint256 public maxSupply = 3579;

    //Prices
    uint256 public cost = 0.6 ether;
    uint256 public whitelistCost = 0.5 ether;

    //Utility
    bool public paused = true;
    bool public whiteListingSale = true;

    //mapping
    mapping(address => uint256) private whitelistedMints;

    constructor(string memory _baseUrl) ERC721A("ZazzyZebras", "Zazz") {
        baseApiURI = _baseUrl;
    }

   

    function setBreedingContractAddress(address _bAddress) public onlyOwner {
        breedingContract = _bAddress;
    }

   

      function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

    function mintExternal(address _address, uint256 _mintAmount) external {
        require(
            msg.sender == breedingContract,
            "Sorry you dont have permission to mint"
        );
        _safeMint(_address, _mintAmount);
    }

    function setWhitelistingRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    

    // Verify that a given leaf is in the tree.
    function _verify(
        bytes32 _leafNode,
        bytes32[] memory proof
    ) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistRoot, _leafNode);
    }

    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    //whitelist mint
    function mintWhitelist(
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) public payable {
        if (msg.sender != owner()) {
            require(!paused);
            require(whiteListingSale, "Whitelisting not enabled");

           require(_verify(_leaf(msg.sender), proof),
                    "Invalid proof"
                );
                require(
                    (whitelistedMints[msg.sender] + _mintAmount) <=
                        maxMintAmountPerWhitelist,
                    "Exceeds Max Mint amount"
                );

            require(
                    msg.value >= (whitelistCost * _mintAmount),
                    "Insuffient funds"
                );
        }

        _mintLoop(msg.sender, _mintAmount);
        whitelistedMints[msg.sender] =
            whitelistedMints[msg.sender] +
            _mintAmount;
    }

     function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

    // public
    function mint(uint256 _mintAmount) public payable {
        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!paused);
            require(!whiteListingSale, "You cant mint on Presale");
            require(_mintAmount > 0, "Mint amount should be greater than 0");
            require(
                _mintAmount <= maxMintAmountPerTransaction,
                "Sorry you cant mint this amount at once"
            );
            require(
                totalSupply() + _mintAmount <= maxSupply,
                "Exceeds Max Supply"
            );
            require(
                (ownerTokenCount + _mintAmount) <= maxMintAmountPerWallet,
                "Sorry you cant mint more"
            );

              require(msg.value >= cost * _mintAmount, "Insuffient funds");
        }

        _mintLoop(msg.sender, _mintAmount);
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        _mintLoop(_to, _mintAmount);
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            _mintLoop(to, 1);
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseApiURI;
    }



    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistingCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    function setMaxMintAmountPerWallet(uint16 _amount) public onlyOwner {
        maxMintAmountPerWallet = _amount;
    }

    function setMaxMintAmountPerWhitelist(uint16 _amount) public onlyOwner {
        maxMintAmountPerWhitelist = _amount;
    }

   

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseApiURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function toggleWhiteSale() public onlyOwner {
        whiteListingSale = !whiteListingSale;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
       _safeMint(_receiver, _mintAmount);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

       function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 share1 = (balance * 25) / 100;
        uint256 share2 = (balance * 25) / 100;
        uint256 share3 = (balance * 10) / 100;

        (bool shareholder3, ) = payable(0x8791D03593AC3b269Bcc8df70762a9305a6807EA).call{value: share1}("");
        require(shareholder3);

        (bool shareholder1, ) = payable(0x3e5F4AC36B2C89777B5D8da55fEB542cCBF80C48).call{value: share2}("");
        require(shareholder1);

        (bool shareholder2, ) = payable(0x366587d3648687Bf6743A7002038aE4559ecd0CF).call{value: share3}("");
        require(shareholder2);

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}