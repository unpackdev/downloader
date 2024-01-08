//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NoobFriendlyTokenGenerator.sol";

/**
 @author Chiao-Yu Yang, Justa Liang
 @notice Blindbox: hind the NFT until revealed
 */
contract NFTBlindbox is NoobFriendlyTokenTemplate {

    using Strings for uint;

    /// @notice Price of token
    uint public tokenPrice;

    /// @notice Time to reveal the NFT
    uint public revealTimestamp;

    /// @notice Offset of the token ID after revealed
    uint public offsetId;

    /// @notice The baseURI before revealed
    string public coverURI;

    /// @dev Seed to do the hash
    uint private _hashSeed;

    /// @dev Setup the template
    constructor(
        BaseSettings memory baseSettings
    )
        ERC721(baseSettings.name, baseSettings.symbol)
        PaymentSplitter(baseSettings.payees, baseSettings.shares)
        NoobFriendlyTokenTemplate(baseSettings.typeOfNFT, baseSettings.maxSupply)
    {}

    /**
     @notice Initialize the contract details
     @param baseURI_ Base URI of revealed NFT
     @param maxPurchase_ Max number of tokens per time
     @param tokenPrice_ Price per token
     @param startTimestamp_ Time to start sale
     @param revealTimestamp_ Time to reveal
     */
    function initialize(
        string calldata baseURI_,
        uint32 maxPurchase_,
        uint tokenPrice_,
        uint160 startTimestamp_,
        uint160 revealTimestamp_
    ) external onlyOwner onlyOnce {
        baseURI = baseURI_;
        settings.maxPurchase = maxPurchase_;
        tokenPrice = tokenPrice_;
        settings.startTimestamp = startTimestamp_;
        revealTimestamp = revealTimestamp_;
        coverURI = "";
        offsetId = 0;
    }

    /// @notice Reserve NFT by contract owner
    function reserveNFT(
        uint reserveNum
    ) public onlyOwner {   
        uint supply = totalSupply();
        require(
            supply + reserveNum <= settings.maxSupply,
            "Blindbox: exceed max supply"
        );
        for (uint i = 0; i < reserveNum; i++) {
            _safeMint(_msgSender(), supply + i);
            _hashSeed += block.number;
        }
    }

    /// @notice Set the after-revealed URI 
    function setBaseURI(
        string calldata newBaseURI
    ) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Set the before-revealed URI 
    function setCoverURI(
        string calldata newCoverURI
    ) external onlyOwner {
        coverURI = newCoverURI;
    }

    /// @notice Change token price
    function setTokenPrice(
        uint newTokenPrice
    ) external onlyOwner {
        tokenPrice = newTokenPrice;
    }

    /**
     @notice Mint (buy) tokens from contract
     @param  numberOfTokens Number of token to mint (buy)
     */
    function mintToken(
        uint numberOfTokens
    ) external payable {
        uint _maxSupply = settings.maxSupply;
        uint _totalSuppy = totalSupply();
        require(
            isInit,
            "BlindBox: not initialized"
        );
        require(
            block.timestamp > settings.startTimestamp,
            "BlindBox: sale is not start"
        );
        require(
            numberOfTokens <= settings.maxPurchase,
            "BlindBox: exceed max purchase"
        );
        require(
            _totalSuppy + numberOfTokens <= _maxSupply,
            "BlindBox: exceed max supply"
        );
        require(
            msg.value >= tokenPrice*numberOfTokens,
            "BlindBox: payment not enough"
        );

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(owner(), _totalSuppy + i);
            _safeTransfer(owner(), _msgSender(), _totalSuppy + i, "");
            _hashSeed += block.number;
        }
    }

    /// @notice Reveal NFT and shuffle token ID 
    function reveal() external {
        require(
            offsetId == 0, 
            "BlindBox: already revealed"
        );
        require(
            totalSupply() == settings.maxSupply || block.timestamp >= revealTimestamp,
            "BlindBox: not allowed to reveal"
        );
        require(
            bytes(baseURI).length > 0,
            "Blindbox: baseURI not set"
        );

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number > _hashSeed && block.number - _hashSeed > 255) {
            offsetId = uint(blockhash(block.number - 1)) % settings.maxSupply;
        }
        else {
            offsetId = uint(blockhash(_hashSeed)) % settings.maxSupply;
        }

        // Prevent default sequence
        if (offsetId == 0) {
            offsetId = 1;
        }
    }

    /// @notice Override the ERC721-tokenURI()
    function tokenURI(
        uint tokenId
    ) public override view returns (string memory) {
        require(
            _exists(tokenId),
             "ERC721Metadata: URI query for nonexistent token"
        );
        
        if (offsetId > 0) {
            uint tokenIndex = (offsetId + tokenId) % settings.maxSupply;
            return string(abi.encodePacked(baseURI, tokenIndex.toString()));
        }
        else {
            if (bytes(coverURI).length == 0) {
                return string(abi.encodePacked(baseURI, uint(settings.maxSupply).toString()));            
            }
            else {
                return string(abi.encodePacked(coverURI, tokenId.toString()));
            }
        }
    }
}

/**
 @author Justa Liang
 @notice Blindbox generator
 */
contract NFTBlindboxGenerator is NoobFriendlyTokenGenerator {
    
    constructor(
        address adminAddr_,
        uint slottingFee_
    )
        NoobFriendlyTokenGenerator(adminAddr_, slottingFee_)
    {}

    function _genContract(
        BaseSettings calldata baseSettings
    ) internal override returns (address) {
        return address(new NFTBlindbox(baseSettings));
    }
}