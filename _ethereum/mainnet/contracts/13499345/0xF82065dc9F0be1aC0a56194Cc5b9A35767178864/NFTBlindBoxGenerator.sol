//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NoobFriendlyTokenGenerator.sol";

/**
 @author Chiao-Yu Yang, Justa Liang
 @notice Blindbox: hind the NFT until revealed
 */
contract NFTBlindbox is NoobFriendlyTokenTemplate {

    using Strings for uint;

    struct BlindboxSettings {
        uint32 offsetId;
        uint128 revealTimestamp;
        uint96 tokenPrice;
    }

    /// @notice Detailed settings of blindbox
    BlindboxSettings public blindboxSettings;

    /// @notice The baseURI before revealed
    string public coverURI;

    /// @dev Offset of block number to do the blockhash
    uint private _offsetBlockNumber;

    /// @dev Setup the template
    constructor(
        BaseSettings memory baseSettings
    )
        ERC721(baseSettings.name, baseSettings.symbol)
        PaymentSplitter(baseSettings.payees, baseSettings.shares)
        NoobFriendlyTokenTemplate(baseSettings.typeOfNFT, baseSettings.maxSupply)
    {
        _offsetBlockNumber=0;
    }

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
        uint96 tokenPrice_,
        uint128 startTimestamp_,
        uint128 revealTimestamp_
    ) external onlyOwner onlyOnce {
        baseURI = baseURI_;
        coverURI = "";
        settings.maxPurchase = maxPurchase_;
        settings.startTimestamp = startTimestamp_;
        settings.totalSupply = 0;
        blindboxSettings.offsetId = 0;
        blindboxSettings.tokenPrice = tokenPrice_;
        blindboxSettings.revealTimestamp = revealTimestamp_;
    }

    /// @notice Reserve NFT by contract owner
    function reserveNFT(
        uint32 reserveNum
    ) public onlyOwner {   
        uint32 supply = settings.totalSupply;
        require(
            supply + reserveNum <= settings.maxSupply,
            "Blindbox: exceed max supply"
        );
        for (uint i = 0; i < reserveNum; i++) {
            _safeMint(_msgSender(), supply + i);
        }
        _offsetBlockNumber += 1;
        settings.totalSupply += reserveNum;
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
        uint96 newTokenPrice
    ) external onlyOwner {
        blindboxSettings.tokenPrice = newTokenPrice;
    }

    /**
     @notice Mint (buy) tokens from contract
     @param  numberOfTokens Number of token to mint (buy)
     */
    function mintToken(
        uint32 numberOfTokens
    ) external payable {
        uint _maxSupply = settings.maxSupply;
        uint _totalSuppy = settings.totalSupply;
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
            msg.value >= blindboxSettings.tokenPrice*numberOfTokens,
            "BlindBox: payment not enough"
        );

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(owner(), _totalSuppy + i);
            _safeTransfer(owner(), _msgSender(), _totalSuppy + i, "");
        }
        _offsetBlockNumber += 1;

        settings.totalSupply += numberOfTokens;
    }

    /// @notice Reveal NFT and shuffle token ID 
    function reveal() external {
        uint totalSupply = settings.totalSupply;
        require(
            blindboxSettings.offsetId == 0, 
            "BlindBox: already revealed"
        );
        require(
            totalSupply == settings.maxSupply ||
            block.timestamp >= blindboxSettings.revealTimestamp,
            "BlindBox: not allowed to reveal"
        );
        require(
            bytes(baseURI).length > 0,
            "Blindbox: baseURI not set"
        );

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        blindboxSettings.offsetId = uint32(uint(blockhash(block.number-_offsetBlockNumber%256)) % settings.maxSupply);

        // Prevent default sequence
        if (blindboxSettings.offsetId == 0) {
            blindboxSettings.offsetId = 1;
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
        uint offsetId = blindboxSettings.offsetId;
        if (tokenId > settings.maxSupply) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        else if (offsetId > 0) {
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