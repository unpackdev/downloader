// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Raffle.sol";

import "./console.sol";

contract Fintica is ERC721A, Ownable, Raffle {
    constructor() ERC721A("fintica", "FINTICA") {}

    string public _contractBaseURI;
    uint256 public MAX_NFT_PUBLIC = 100;
    uint256 public NFTPrice = 200000000000000000; // 0.2 ETH;
    uint256 public maxPerWalletPresale = 6;
    uint256 public maxPerTransaction = 10;
    bool public isActive;
    bool public isPresaleActive;
    bool public isPublicSaleActive;
    bool public isFreeMintActive;
    bytes32 public root;

    mapping(address => uint256) public whiteListClaimed;
    mapping(address => bool) private giveawayMintClaimed;

    modifier isContractPublicSale() {
        require(isActive == true, "Contract is not active");
        require(isPublicSaleActive == true, "PublicSale is not active");
        require(isPresaleActive == false, "Presale is still active");
        _;
    }
    modifier isContractPresale() {
        require(isActive == true, "Contract is not active");
        require(isPresaleActive == true, "Presale is not opened yet");
        require(isPublicSaleActive == false, "PublicSale is still active");
        _;
    }

    /*
     * Function to mint new NFTs during the public sale
     */
    function mintNFT(uint256 _numOfTokens)
        external
        payable
        isContractPublicSale
    {
        require(_numOfTokens <= maxPerTransaction, "Cannot mint above limit");
        require(
            totalSupply() + _numOfTokens + totalRaffleMinted <=
                MAX_NFT_PUBLIC - raffleSupply,
            "Purchase would exceed max public supply of NFTs"
        );
        require(
            NFTPrice * _numOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        _safeMint(msg.sender, _numOfTokens);
    }

    /*
     * Function to mint new NFTs during the public sale
     */
    function mintNFTDuringRaffle(uint256 _numOfTokens)
        external
        payable
        raffleCheck
    {
        require(isActive, "Contract is not active");
        require(_numOfTokens <= maxPerTransaction, "Cannot mint above limit");
        require(
            (totalRaffleMinted + _numOfTokens) <= raffleSupply,
            "Purchase would exceed max raffle supply of NFTs "
        );
        _safeMint(msg.sender, _numOfTokens);
        subscribedToRaffle[msg.sender] == false;
    }

    /*
     * Function to mint new NFTs during the presale
     */
    function mintNFTDuringPresale(uint256 _numOfTokens, bytes32[] memory _proof)
        external
        payable
        isContractPresale
    {
        require(
            MerkleProof.verify(_proof, root, keccak256(abi.encode(msg.sender))),
            "Not whitelisted"
        );
        require(
            totalSupply() < MAX_NFT_PUBLIC,
            "All public tokens have been minted"
        );
        require(
            totalSupply() + _numOfTokens <= MAX_NFT_PUBLIC,
            "Purchase would exceed max public supply of NFTs"
        );

        if (!isFreeMintActive) {
            require(
                whiteListClaimed[msg.sender] + _numOfTokens <=
                    maxPerWalletPresale,
                "Purchase exceeds max whitelisted"
            );
            require(
                totalSupply() + _numOfTokens <= MAX_NFT_PUBLIC,
                "Purchase would exceed max public supply of NFTs"
            );
            require(
                NFTPrice * _numOfTokens <= msg.value,
                "Ether value sent is not correct"
            );
            whiteListClaimed[msg.sender] += _numOfTokens;
            _safeMint(msg.sender, _numOfTokens);
        } else {
            require(_numOfTokens == 1, "Cannot purchase this many tokens");
            require(
                !giveawayMintClaimed[msg.sender],
                "Already claimed giveaway"
            );
            giveawayMintClaimed[msg.sender] = true;
            _safeMint(msg.sender, _numOfTokens);
        }
    }

    /*
     * Function to mint NFTs for giveaway and partnerships
     */
    function mintByOwner(address _to) public onlyOwner {
        require(
            totalSupply() + 1 <= MAX_NFT_PUBLIC,
            "Tokens number to mint cannot exceed number of MAX tokens category 1"
        );
        _safeMint(_to, 1);
    }

    /*
     * Function to mint all NFTs for giveaway and partnerships
     */
    function mintMultipleByOwner(address[] memory _to) public onlyOwner {
        require(
            totalSupply() + _to.length <= MAX_NFT_PUBLIC,
            "Tokens number to mint cannot exceed number of tokens"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    /*
     * Function to withdraw collected amount during minting by the owner
     */
    function withdraw(address _to) public onlyOwner {
        require(address(this).balance > 0, "Balance should be more than zero");
        uint256 balance = address(this).balance;
        (bool sent1, ) = _to.call{value: balance}("");
        require(sent1, "Failed to send Ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    /*
     * Function to set Base URI
     */
    function setURI(string memory _URI) external onlyOwner {
        _contractBaseURI = _URI;
    }

    /*
     * Function to set NFT Price
     */
    function setNFTPrice(uint256 _price) external onlyOwner {
        NFTPrice = _price;
    }

    /*
     * Function to set NFT Supply
     */
    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        MAX_NFT_PUBLIC = _totalSupply;
    }

    /*
     * Function to set the merkle root
     */
    function setRoot(uint256 _root) external onlyOwner {
        root = bytes32(_root);
    }

    /*
     * Function toggleActive to activate/desactivate the smart contract
     */
    function toggleActive() external onlyOwner {
        isActive = !isActive;
    }

    /*
     * Function togglePublicSale to activate/desactivate public sale
     */
    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    /*
     * Function togglePresale to activate/desactivate  presale
     */
    function togglePresale() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    /*
    Function to activate/desactivate the free mint
    */
    function toggleFreeMint() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }
}
