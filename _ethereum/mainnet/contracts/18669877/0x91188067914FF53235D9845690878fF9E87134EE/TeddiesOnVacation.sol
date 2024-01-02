//  _____         _     _ _                                                _   _             
// /__   \___  __| | __| (_) ___  ___     ___  _ __    /\   /\__ _  ___ __ _| |_(_) ___  _ __  
//   / /\/ _ \/ _` |/ _` | |/ _ \/ __|   / _ \| '_ \   \ \ / / _` |/ __/ _` | __| |/ _ \| '_ \ 
//  / / |  __/ (_| | (_| | |  __/\__ \  | (_) | | | |   \ V / (_| | (_| (_| | |_| | (_) | | | |
//  \/   \___|\__,_|\__,_|_|\___||___/   \___/|_| |_|    \_/ \__,_|\___\__,_|\__|_|\___/|_| |_|
// // // // // // // //                             =########             
// // // // // // // //       :********.   :**********#######**.          
// // // // // // // //     -+*********+++++*************====##.          
// // // // // // // //   -+*#*****====******************++--##.          
// // // // // // // //   +##****==--++********************++--           
// // // // // // // //   +##****--++************************             
// // // // // // // //   -=+##**==**************************--           
// // // // // // // //     -++##***************##*******##****.          
// // // // // // // //       :+****************%%*******%%****.          
// // // // // // // //         .##*************##=-----=##****.          
// // // // // // // //         .##*************-------======**.          
// // // // // // // //         .##***********--------*%%%%%%--           
// // // // // // // //         .##***********----------=%#----           
// // // // // // // //            ##***********---------=---             
// // // // // // // //            ..*#**********************             
// // // // // // // //              *######**************+..             
// // // // // // // //            ==*##########***********++             
// // // // // // // //          --****###########*********##====.        
// // // // // // // //       .--********#########***********####+-:      
// // // // // // // //     .:=********#########***************####+-:    
// // // // // // // //     =**********#######*****************######*::  
// // // // // // // //   ..=**********#######*******************#######  
// // // // // // // //   +**********#######*********************#######  
// // // // // // // //   +**********#######*********************#########
// // // // // // // // ***********#########*********************#########
/**
 * @title TeddiesOnVacation
 * @author numo <@numo_0> <info@numo.art>
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SignedAllowance.sol";
import "./ToVInfos.sol";
import "./Base64.sol";
import "./ITeddiesOnVacationRenderer.sol";

contract TeddiesOnVacation is ERC721Enumerable, Ownable, ReentrancyGuard, SignedAllowance {
    
    error MintNotActive();
    error IncorrectAmountOfEtherSent();
    error InvalidMintCount();
    error MintAllowanceReached();
    error MintAllowanceReachedSignature();
    error SeasonSupplyReached();
    error FinalSeasonReached();
    error InvalidSeason();
    error AnySeasonMintNotActive();
    error NonExistentToken();
    error WithdrawalFailed();
    
    struct Counters {
        uint64 tokenIds;
        uint64 founderMinted;
        uint64 currentSeason;
    }

    uint256 public constant MAX_SEASONS = 4;
    uint256 public FOUNDER_RESERVE_AMOUNT = 60;
    uint256 public MAX_SUPPLY_PER_SEASON = 1222;
    uint256 public MAX_SUPPLY_LAST_SEASON = 366;
    uint256 public MAX_PER_ADDRESS_PUBLIC = 8;
    
    Counters public counters;
    mapping(uint64 => uint256) public seasonNFTsMinted;

    address public rendererContractAddress;

    ToVInfos.ContractData public contractData = ToVInfos.ContractData(
        unicode"ToV",
        unicode"Teddies on Vacation",
        unicode"Teddies on Vacation (ToV) is a collection of Teddies relishing their free time in the Grand Teddy Hotel by @numo_0.\\n  \\nAs the sun rises on a beautiful morning, excitement is in the air as not one, not two, but three groups of teddies are preparing for their arrival.\\nTeddies love relaxation, good food, partying and enjoying their lives as much as we do.\\nSo, join the ToVs and be part of a funny, cute and beautiful community.\\n\\nAll the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain.",
        "https://cryptoteddies.xyz/base.png",
        "https://cryptoteddies.xyz/banner.png",
        "https://cryptoteddies.xyz",
        "750",
        "0xd42bd96B117dd6BD63280620EA981BF967A7aD2B"
    );
    
    // After contract sealed, no changes are possible anymore
    bool public isContractSealed;
    bool public isMintingPaused;
    bool public isCryptoTeddiesMintActive;
    bool public isAllowListMintActive;
    bool public isPublicMintActive;
    bool public isAnySeasonMintActive;

    uint256 public mintPrice = 0.025 ether;
    uint256 public mintPriceForCryptoTeddies = 0.01 ether;

    mapping(bytes32 => uint256) public allowancesMinted;
    mapping(bytes32 => uint256) public allowancesMintedLastSeason;
    mapping(address => uint256) public addressPublicMintedCounts;

    mapping(uint256 => ToVInfos.ToV) public tovs;

    constructor(address _allowancesSigner) ERC721("Teddies on Vacation", "TOV") {
        // Start with Season 1
        counters.currentSeason = 1;
        _setAllowancesSigner(_allowancesSigner);
    }

    /**
     * Checks if a mint phase is active.
     * @param mintPhase Value of a phase
     */
    modifier mintActive(bool mintPhase) {
        if (!isMintActive(mintPhase)) revert MintNotActive();
        _;
    }

    /**
     * Checks if the contract is sealed.
     */
    modifier whenUnsealed() {
        require(!isContractSealed, "Contract is sealed");
        _;
    }

    /**
     * Verifies different condition of a mint is eligible.
     * @param count Amount of mints
     * @param price The price of the mint
     * @param maxPerAddress Amount allowed to mint
     */
    modifier verifyMintConditions(uint256 count, uint256 price, uint256 maxPerAddress) {
        if (count == 0) revert InvalidMintCount();
        if (count > maxPerAddress) revert MintAllowanceReached();
        if (count * price != msg.value) revert IncorrectAmountOfEtherSent();

        uint64 currentSeason = counters.currentSeason;
        uint256 currentSeasonMinted = seasonNFTsMinted[currentSeason];
        uint256 maxSeasonSupply = MAX_SUPPLY_PER_SEASON;
        if (currentSeason >= MAX_SEASONS) {
            maxSeasonSupply = MAX_SUPPLY_LAST_SEASON;
        }
        if (currentSeasonMinted + count > maxSeasonSupply) revert SeasonSupplyReached();
        _;
    }

    /**
     * The actual mint funtion which creates the NFT.
     * @param _tokenId The tokenID of the new NFT
     * @param _season Determines the season 
     */
    function _mint(uint256 _tokenId, uint64 _season) internal {
        ToVInfos.ToV memory tov;
        tov.dna = uint256(keccak256(abi.encodePacked(
                _tokenId,
                msg.sender,
                block.prevrandao,
                block.timestamp
            )));

        tov.season = _season;

        super._mint(msg.sender, _tokenId);

        tovs[_tokenId] = tov;
    }

    /**
     * Checks if a certain signature is eligable to mint and updates the counter.
     * @param _count Amount of mints
     * @param _nonce The nonce using to validate the signature
     * @param _signature The signature to check if it is eligable to mint
     */
    function _checkSignature(uint256 _count, uint256 _nonce, bytes memory _signature) internal {
        uint64 currentSeason = counters.currentSeason;
        // this will throw if the signature is not the right one
        bytes32 signatureId;
        uint256 alreadyMinted;

        signatureId = validateSignature(msg.sender, currentSeason >= MAX_SEASONS ? _nonce + currentSeason : _nonce, _signature);
        alreadyMinted = currentSeason >= MAX_SEASONS ? allowancesMintedLastSeason[signatureId] : allowancesMinted[signatureId];
        
        // verify we don't ask for too many
        if (alreadyMinted + _count > _nonce) revert MintAllowanceReachedSignature();
        // increment the counter of how many were minted for this signature
        unchecked {
            if (currentSeason >= MAX_SEASONS) {
                allowancesMintedLastSeason[signatureId] += _count;
            } else {
                allowancesMinted[signatureId] += _count;
            }
        }
    }

    /**
     * Mint function for the founder.
     * @param _count Amount of mint
     */
    function mintFounder(uint64 _count) external onlyOwner nonReentrant {
        uint64 founderMinted = counters.founderMinted;
        uint64 currentSeason = counters.currentSeason;
        uint256 currentSeasonMinted = seasonNFTsMinted[currentSeason];

        if (_count == 0) revert InvalidMintCount();
        if (founderMinted + _count > FOUNDER_RESERVE_AMOUNT) revert MintAllowanceReached();

        uint256 maxSeasonSupply = currentSeason >= MAX_SEASONS ? MAX_SUPPLY_LAST_SEASON : MAX_SUPPLY_PER_SEASON;
        if (currentSeasonMinted + _count > maxSeasonSupply) revert SeasonSupplyReached();

        uint64 currentTokenId = counters.tokenIds;

        // increment once to save gas
        unchecked {
            counters.founderMinted = founderMinted + _count;
            seasonNFTsMinted[currentSeason] = currentSeasonMinted + _count;
            counters.tokenIds = currentTokenId + _count;
        }

        for (uint256 i; i < _count; ) {
            unchecked {
                ++currentTokenId;
                ++i;
            }
            _mint(currentTokenId, currentSeason);
        }
    }

    /**
     * The mint function for CryptoTeddies holder.
     * @param _count Amount of mints
     * @param _nonce Nonce used for validating the signature and determine the max amount of mints
     * @param _signature Signature to check if eligible
     */
    function mintCryptoTeddiesHolder(uint64 _count, uint256 _nonce, bytes memory _signature)
        external
        payable
        nonReentrant
        mintActive(isCryptoTeddiesMintActive)
        verifyMintConditions(_count, mintPriceForCryptoTeddies, _nonce) 
    {
        _checkSignature(_count, _nonce, _signature);

        uint64 currentSeason = counters.currentSeason;
        uint256 currentSeasonMinted = seasonNFTsMinted[currentSeason];
        uint64 currentTokenId = counters.tokenIds;

        // increment once to save gas
        unchecked {
            seasonNFTsMinted[currentSeason] = currentSeasonMinted + _count;
            counters.tokenIds = currentTokenId + _count;
        }

        for (uint256 i; i < _count; ) {
            unchecked {
                ++currentTokenId;
                ++i;
            }
            _mint(currentTokenId, currentSeason);
        }
    }

    /**
     * The mint function for allowlist wallets.
     * @param _count Amount of mints
     * @param _nonce Nonce used for validating the signature and determine the max amount of mints
     * @param _signature Signature to check if eligible
     */
    function mintAllowList(uint64 _count, uint256 _nonce, bytes memory _signature)
        external
        payable
        nonReentrant
        mintActive(isAllowListMintActive)
        verifyMintConditions(_count, mintPrice, _nonce) 
    {
        _checkSignature(_count, _nonce, _signature);

        uint64 currentSeason = counters.currentSeason;
        uint256 currentSeasonMinted = seasonNFTsMinted[currentSeason];
        uint64 currentTokenId = counters.tokenIds;

        // increment once to save gas
        unchecked {
            seasonNFTsMinted[currentSeason] = currentSeasonMinted + _count;
            counters.tokenIds = currentTokenId + _count;
        }

        for (uint256 i; i < _count; ) {
            unchecked {
                ++currentTokenId;
                ++i;
            }
            _mint(currentTokenId, currentSeason);
        }
    }

    /**
     * The mint function for public mint.
     * @param _count Amount of mints
     */
    function mintPublic(uint64 _count)
        external
        payable
        nonReentrant
        mintActive(isPublicMintActive)
        verifyMintConditions(_count, mintPrice, MAX_PER_ADDRESS_PUBLIC) 
    {
        uint256 currentAddressPublicMintedCount = addressPublicMintedCounts[msg.sender];

        if (_count + currentAddressPublicMintedCount > MAX_PER_ADDRESS_PUBLIC) revert MintAllowanceReached();

        uint64 currentSeason = counters.currentSeason;
        uint256 currentSeasonMinted = seasonNFTsMinted[currentSeason];
        uint64 currentTokenId = counters.tokenIds;

        // increment once to save gas
        unchecked {
            seasonNFTsMinted[currentSeason] = currentSeasonMinted + _count;
            counters.tokenIds = currentTokenId + _count;
            // increment the counter of how many were minted for this address
            addressPublicMintedCounts[msg.sender] = currentAddressPublicMintedCount + _count;
        }

        for (uint256 i; i < _count; ) {
            unchecked {
                ++currentTokenId;
                ++i;
            }
            _mint(currentTokenId, currentSeason);
        }
    }

    /**
     * The mint function to mint a certain season NFT.
     * @param _count Amount of mints
     * @param _season Determines the season
     */
    function mintSeason(uint64 _count, uint64 _season) 
        external
        payable
        nonReentrant
        mintActive(isPublicMintActive) 
    {
        if (!isAnySeasonMintActive) revert AnySeasonMintNotActive();
        if (_season == 0 || _season > MAX_SEASONS) revert InvalidSeason();
        
        uint64 currentTokenId = counters.tokenIds;
        uint256 currentSeasonMinted = seasonNFTsMinted[_season];
        uint256 currentAddressPublicMintedCount = addressPublicMintedCounts[msg.sender];

        if (_count == 0 || _count + currentAddressPublicMintedCount > MAX_PER_ADDRESS_PUBLIC) revert MintAllowanceReached();
        if (_count * mintPrice != msg.value) revert IncorrectAmountOfEtherSent();
        
        uint256 maxSeasonSupply = MAX_SUPPLY_PER_SEASON;
        if (_season >= MAX_SEASONS) {
            maxSeasonSupply = MAX_SUPPLY_LAST_SEASON;
        }
        if (currentSeasonMinted + _count > maxSeasonSupply) revert SeasonSupplyReached();

        // increment once to save gas
        unchecked {
            seasonNFTsMinted[_season] = currentSeasonMinted + _count;
            counters.tokenIds = currentTokenId + _count;
            // increment the counter of how many were minted for this address
            addressPublicMintedCounts[msg.sender] = currentAddressPublicMintedCount + _count;
        }
        
        for (uint256 i; i < _count; ) {
            unchecked {
                ++currentTokenId;
                ++i;
            }
            _mint(currentTokenId, _season);
        }
    }

    /**
     * Funtion to get the DNA of a ToV.
     * @param _tokenId The tokenID to get the DNA for.
     */
    function getDna(uint256 _tokenId) public view returns (uint256) {
        return tovs[_tokenId].dna;
    }

    /**
     * Checks if a mint phase is active.
     * @param _mintPhase State of a certain mint phase.
     */
    function isMintActive(bool _mintPhase) public view returns (bool) {
        return !isMintingPaused && (_mintPhase || msg.sender == owner());
    }

    /**
     * Function to retrieve the metadata & art for a given token. Reverts for tokens that don't exist.
     * @param _tokenId The tokenID to get the uri for.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistentToken();

        if (rendererContractAddress == address(0)) {
            return '';
        }

        // Use of a external renderer. 
        IToVRenderer renderer = IToVRenderer(rendererContractAddress);
        return renderer.tokenURI(_tokenId, tovs[_tokenId], contractData);
    }

    /**
     * Funtion to retrieve the metadata for a given token.
     * @param _tokenId The tokenID to get the metadata for.
     */
    function getMetaData(uint256 _tokenId) public view returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistentToken();

        if (rendererContractAddress == address(0)) {
            return '';
        }

        // Use of a external renderer. 
        IToVRenderer renderer = IToVRenderer(rendererContractAddress);
        return renderer.getMetaDataFromTokenID(_tokenId, tovs[_tokenId]);
    }

    /**
     * Function to provide contract information.
     */
    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        contractData.collectionName,
                        '","description":"',
                        contractData.description,
                        '","image":"',
                        contractData.image,
                        '","banner":"',
                        contractData.banner,
                        '","external_link":"',
                        contractData.website,
                        '","seller_fee_basis_points":',
                        contractData.royalties,
                        ',"fee_recipient":"',
                        contractData.royaltiesRecipient,
                        '"}'
                    )
                )
            )
        );
    }

    // =========================================================================
    //                             Owner Functions
    // =========================================================================

    /**
     * Starts the next season.
     */
    function startNextSeason() external onlyOwner {
        uint64 currentSeason = counters.currentSeason;

        if (currentSeason >= MAX_SEASONS) revert FinalSeasonReached();
        unchecked {
            counters.currentSeason = currentSeason + 1;
            // reset mint phases for each new seasons
            isAllowListMintActive = false;
            isPublicMintActive = false;            
        }
    }

    /**
     * Sets a specific season.
     * @param _season The season which should run.
     */
    function setSeason(uint64 _season) external onlyOwner {
        if (_season == 0 || _season > MAX_SEASONS) revert InvalidSeason();
        unchecked {
            counters.currentSeason = _season;
        }
    } 
    
    function setRendererContractAddress(address _rendererContractAddress) public whenUnsealed onlyOwner {
        rendererContractAddress = _rendererContractAddress;
    }
    function setFounderReserveAmount(uint256 _max) public whenUnsealed onlyOwner {
        FOUNDER_RESERVE_AMOUNT = _max;
    }
    function setMaxSupplyPerSeason(uint256 _max) public whenUnsealed onlyOwner {
        MAX_SUPPLY_PER_SEASON = _max;
    }
    function setMaxSupplyLastSeason(uint256 _max) public whenUnsealed onlyOwner {
        MAX_SUPPLY_LAST_SEASON = _max;
    }
    function setMaxPerAddressPublic(uint256 _max) public onlyOwner {
        MAX_PER_ADDRESS_PUBLIC = _max;
    }
    function setContractData(ToVInfos.ContractData calldata _data) external onlyOwner {
        contractData = _data;
    }
    function setMintPrice(uint _price) external onlyOwner {
        mintPrice = _price;
    }
    function setMintPriceForCryptoTeddies(uint _price) external onlyOwner {
        mintPriceForCryptoTeddies = _price;
    }
    
    /**
     * Sets allowance signer, this can be used to revoke all unused allowances already out there
     * @param _newSigner The new signer
     */
    function setAllowancesSigner(address _newSigner) external onlyOwner {
        _setAllowancesSigner(_newSigner);
    }

    /**
     * Seals the contract, so no changes are possible anymore.
     */
    function sealContract() external whenUnsealed onlyOwner {
        isContractSealed = true;
    }

    function toggleMintingPaused() external onlyOwner {
        isMintingPaused = !isMintingPaused;
    }
     function toggleCryptoTeddiesMint() external onlyOwner {
        isCryptoTeddiesMintActive = !isCryptoTeddiesMintActive;
    }
     function toggleAllowListMint() external onlyOwner {
        isAllowListMintActive = !isAllowListMintActive;
    }
    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }
    function toggleAnySeasonMintActive() external onlyOwner {
        isAnySeasonMintActive = !isAnySeasonMintActive;
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721Enumerable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        if (!success) revert WithdrawalFailed();
    }
}