// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract UrbanApesGenesis is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    uint256 public maxSupply;

    bool public paused = true;
    bool public revealed = false;

    uint256[2] public pricePerMint;
    uint256[2] public maxMintAmountPerTier;
    uint256 public currentTier = 0;   

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256[2] memory _pricePerMint,
        uint256[2] memory _maxMintAmountPerTier,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        setPricePerMint(_pricePerMint);
        setMaxMintAmountPerTier(_maxMintAmountPerTier);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }    


    function setPricePerMint(uint256[2] memory _pricePerMint) public onlyOwner {
        pricePerMint = _pricePerMint;
    }

    // A mapping to store how many tokens each address has minted in each tier
    mapping(address => mapping(uint256 => uint256)) private _mintsPerTier;

function mint(uint256 _mintAmount) public payable {
    // Ensures the function cannot be called if the contract is paused
    require(!paused, "The contract is paused!");

    require(currentTier < pricePerMint.length, "All tiers are exhausted.");
    require(_mintAmount <= maxMintAmountPerTier[currentTier], string(
        abi.encodePacked(
            "Not enough Urban Apes left in the current tier. Available: ",
            uint2str(maxMintAmountPerTier[currentTier])
        )
    ));

    

    uint256 mintsInCurrentTier = _mintsPerTier[msg.sender][currentTier];

    // Existing logic for non-owners
    if (msg.sender != owner()) {
        if (currentTier == 1) {
            require(mintsInCurrentTier == 0, "You can only mint 1 FREE Urban Ape per wallet address");
            require(_mintAmount == 1, "You can only mint 1 FREE Urban Ape per wallet address");
        } else {
            require(mintsInCurrentTier + _mintAmount <= 10, "Cannot mint more than 10 Urban Apes");
            require(_mintAmount <= 10, "Cannot mint more than 10 Urban Apes");               
        }
    }

    require(msg.value >= pricePerMint[currentTier] * _mintAmount, "Insufficient funds!");    

    // Decrease the number of tokens available for minting in the current tier
    maxMintAmountPerTier[currentTier] -= _mintAmount;

    // If all tokens in the current tier have been minted and there is a next tier, increment the current tier
    if (maxMintAmountPerTier[currentTier] == 0 && currentTier < pricePerMint.length - 1) {
        currentTier += 1;
    }

    // Update the number of tokens the caller has minted in the current tier
    _mintsPerTier[msg.sender][currentTier] += _mintAmount;

    // Mint the requested number of tokens
    _mint(msg.sender, _mintAmount);

    
if (msg.sender == owner()) {        
    (bool success, ) = payable(msg.sender).call{value: msg.value}("");
    require(success, "Transfer failed.");        
}

}
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTier(
        uint256[2] memory _maxMintAmountPerTier
    ) public onlyOwner {
        maxMintAmountPerTier = _maxMintAmountPerTier;
    }

    function setMaxMintForSpecificTier(
        uint256 _tier,
        uint256 _maxMintAmountPerTier
    ) public onlyOwner {
        require(_tier >= 0 && _tier <= 1, "Invalid tier!");
        maxMintAmountPerTier[_tier] = _maxMintAmountPerTier;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function getCurrentCost() public view returns (uint256) {
        return pricePerMint[currentTier];
    }

    function getMintsAvailableInCurrentTier() public view returns (uint256) {
        return maxMintAmountPerTier[currentTier];
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawAmount(
        uint256 _amountInWei
    ) public onlyOwner nonReentrant {
        require(address(this).balance >= _amountInWei, "Not enough funds");
        (bool success, ) = payable(owner()).call{value: _amountInWei}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function getPricePerMintAtIndex(
        uint256 index
    ) public view returns (uint256) {
        require(index < 2, "Invalid index");
        return pricePerMint[index];
    }

    function getMaxMintAmountPerTxAtIndex(
        uint256 index
    ) public view returns (uint256) {
        require(index < 2, "Invalid index");
        return maxMintAmountPerTier[index];
    }
}
