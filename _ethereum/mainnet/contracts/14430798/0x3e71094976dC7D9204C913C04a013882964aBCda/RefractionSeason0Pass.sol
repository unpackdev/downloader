// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/*

      ___           ___           ___         ___           ___           ___                                   ___           ___                    ___           ___           ___           ___           ___           ___                                           ___           ___                       ___           ___          _____    
     /  /\         /  /\         /  /\       /  /\         /  /\         /  /\          ___       ___          /  /\         /__/\                  /  /\         /  /\         /  /\         /  /\         /  /\         /__/\                                         /  /\         /__/\          ___        /  /\         /  /\        /  /::\   
    /  /::\       /  /:/_       /  /:/_     /  /::\       /  /::\       /  /:/         /  /\     /  /\        /  /::\        \  \:\                /  /:/_       /  /:/_       /  /::\       /  /:/_       /  /::\        \  \:\                                       /  /::\        \  \:\        /__/|      /  /::\       /  /::\      /  /:/\:\  
   /  /:/\:\     /  /:/ /\     /  /:/ /\   /  /:/\:\     /  /:/\:\     /  /:/         /  /:/    /  /:/       /  /:/\:\        \  \:\              /  /:/ /\     /  /:/ /\     /  /:/\:\     /  /:/ /\     /  /:/\:\        \  \:\                      ___     ___    /  /:/\:\        \  \:\      |  |:|     /  /:/\:\     /  /:/\:\    /  /:/  \:\ 
  /  /:/~/:/    /  /:/ /:/_   /  /:/ /:/  /  /:/~/:/    /  /:/~/::\   /  /:/  ___    /  /:/    /__/::\      /  /:/  \:\   _____\__\:\            /  /:/ /::\   /  /:/ /:/_   /  /:/~/::\   /  /:/ /::\   /  /:/  \:\   _____\__\:\                    /__/\   /  /\  /  /:/~/::\   _____\__\:\     |  |:|    /  /:/~/::\   /  /:/~/:/   /__/:/ \__\:|
 /__/:/ /:/___ /__/:/ /:/ /\ /__/:/ /:/  /__/:/ /:/___ /__/:/ /:/\:\ /__/:/  /  /\  /  /::\    \__\/\:\__  /__/:/ \__\:\ /__/::::::::\          /__/:/ /:/\:\ /__/:/ /:/ /\ /__/:/ /:/\:\ /__/:/ /:/\:\ /__/:/ \__\:\ /__/::::::::\                   \  \:\ /  /:/ /__/:/ /:/\:\ /__/::::::::\  __|__|:|   /__/:/ /:/\:\ /__/:/ /:/___ \  \:\ /  /:/
 \  \:\/:::::/ \  \:\/:/ /:/ \  \:\/:/   \  \:\/:::::/ \  \:\/:/__\/ \  \:\ /  /:/ /__/:/\:\      \  \:\/\ \  \:\ /  /:/ \  \:\~~\~~\/          \  \:\/:/~/:/ \  \:\/:/ /:/ \  \:\/:/__\/ \  \:\/:/~/:/ \  \:\ /  /:/ \  \:\~~\~~\/                    \  \:\  /:/  \  \:\/:/__\/ \  \:\~~\~~\/ /__/::::\   \  \:\/:/__\/ \  \:\/:::::/  \  \:\  /:/ 
  \  \::/~~~~   \  \::/ /:/   \  \::/     \  \::/~~~~   \  \::/       \  \:\  /:/  \__\/  \:\      \__\::/  \  \:\  /:/   \  \:\  ~~~            \  \::/ /:/   \  \::/ /:/   \  \::/       \  \::/ /:/   \  \:\  /:/   \  \:\  ~~~                      \  \:\/:/    \  \::/       \  \:\  ~~~     ~\~~\:\   \  \::/       \  \::/~~~~    \  \:\/:/  
   \  \:\        \  \:\/:/     \  \:\      \  \:\        \  \:\        \  \:\/:/        \  \:\     /__/:/    \  \:\/:/     \  \:\                 \__\/ /:/     \  \:\/:/     \  \:\        \__\/ /:/     \  \:\/:/     \  \:\                           \  \::/      \  \:\        \  \:\           \  \:\   \  \:\        \  \:\         \  \::/   
    \  \:\        \  \::/       \  \:\      \  \:\        \  \:\        \  \::/          \__\/     \__\/      \  \::/       \  \:\                  /__/:/       \  \::/       \  \:\         /__/:/       \  \::/       \  \:\                           \__\/        \  \:\        \  \:\           \__\/    \  \:\        \  \:\         \__\/    
     \__\/         \__\/         \__\/       \__\/         \__\/         \__\/                                 \__\/         \__\/                  \__\/         \__\/         \__\/         \__\/         \__\/         \__\/                                         \__\/         \__\/                     \__\/         \__\/                  

                                                                                                                                                                        
                                                                                                                                                                        
*/
                                                                                                                                                        
contract RefractionSeason0Pass is ERC1155, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public cost;
    uint256 public maxMintAmountPerTx;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public reserveSize;
    uint256 public totalMinted = 0;
    string public hiddenMetadataUri;
    mapping(address => uint256) private totalMintedPerWallet;
    
    string public tokenName;
    string public tokenSymbol;

    bytes32 public merkleRoot;
    mapping(address => bool) public greenlistClaimed;

    bool public paused = true;
    bool public greenlistMintEnabled = false;
    bool public revealed = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _reserveSize,
        uint256 _maxMintAmountPerTx,
        string memory _metadataUri,
        string memory _hiddenMetadataUri
        
    ) ERC1155(_metadataUri) {
            tokenName = _tokenName;
            tokenSymbol = _tokenSymbol;
            cost = _cost;
            maxSupply = _maxSupply;
            maxPerWallet = _maxPerWallet;
            reserveSize = _reserveSize;
            maxMintAmountPerTx = _maxMintAmountPerTx; 
            hiddenMetadataUri = _hiddenMetadataUri;                 
    }  

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalMinted + _mintAmount <= (maxSupply - reserveSize), 'Max supply exceeded!');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }

    function greenlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
        // Verify greenlist requirements
        require(greenlistMintEnabled, 'The greenlistist sale is not enabled!');
        require(tx.origin == msg.sender && msg.sender != address(0), "No contracts!");
        require(!greenlistClaimed[_msgSender()], 'Address already claimed.');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof.');
        greenlistClaimed[_msgSender()] = true;
        totalMintedPerWallet[_msgSender()] += _mintAmount;
        totalMinted += _mintAmount;
        _mint(msg.sender, 1, _mintAmount,"" );  
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
        require(!paused, 'The contract is paused!');
        require(tx.origin == msg.sender && msg.sender != address(0), "No contracts.");
        require(totalMintedPerWallet[msg.sender] < maxPerWallet, "Wallet has minted too many.");
        totalMintedPerWallet[msg.sender] += _mintAmount;
        totalMinted += _mintAmount;
        _mint(msg.sender, 1, _mintAmount, "" );
    }

    function reserve(uint _mintAmount, address _receiver ) public onlyOwner {    
        require(_receiver != address(0), "Don't mint to zero address.");
        require((reserveSize - _mintAmount) >= 0, "Not enough reserve.");
        require(totalMinted + _mintAmount <= maxSupply, "No more editions left.");
        reserveSize -= _mintAmount;
        totalMinted += _mintAmount;
        _mint(_receiver, 1, _mintAmount, "");
    }

    function setBaseURI(string memory newUri) public onlyOwner {
        _setURI(newUri);
    }

    function getTotalMinted() public view returns(uint256){
        return totalMinted;
    }
    
    function getMaxSupply() public view returns(uint256){
        return maxSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        require(_cost != cost, 'New price is identical to old price.');
        cost = _cost;
    } 

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setGreenlistMintEnabled(bool _state) public onlyOwner {
        greenlistMintEnabled = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function withdraw() public onlyOwner nonReentrant {  
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}