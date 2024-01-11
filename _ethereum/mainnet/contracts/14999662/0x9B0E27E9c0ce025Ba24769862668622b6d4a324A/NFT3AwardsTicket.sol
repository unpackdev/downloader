//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Base64.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./AggregatorV3Interface.sol";


contract NFT3AwardsTickets is ERC721Enumerable, Pausable, Ownable {
    AggregatorV3Interface internal priceFeed;

    string baseTokenURI;
    string unrevealedURI;
    string[4] ticketTypes = ["VIP", "VIP PLUS", "Executive VIP", "Founders"];
    bool unrevealedURIFlag = true;
    uint16 public maxSupply = 16130;
    uint16 public publicMaxSupply = 12600;

    uint16 public publicAvaliablSupply = 12600;
    uint16 public earlyAccessAvaliableSupply = 500;
    uint16[4] public giveawayAvaliableSupply = [1600, 0, 400, 30];
    uint16 public jellyzHoldersAvaliableSupply = 1000;
    uint16[4] public rarityTicketsDistribution = [8400, 4200, 400, 100]; // public + whitelist, total 13_000

    uint16 public totalMinted = 0;
    uint public earlyMintPrice = 298; // in USD
    uint public publicMintPrice = 398; // start mint price // in USD
    uint public mintPriceCostStep = 100; // in USD
    uint16 public constant mintPriceChangeStep = 2500; // public mint price change step
    uint8 public constant batchLimit = 10; // mint amount limit
    uint8 public constant earlyBatchLimit = 4; // mint amount limit

    bool public mintStarted = false; // is mint started flag
    bool public mintEarlyStarted = false; // is mint for white list started flag
    bool public mintJellyzWhitelistStarted = false; // is jellyz whitelist mint started flag

    bytes32 public whiteListMerkleRoot; // root of Merkle tree only for white list minters
    bytes32 public jellyzMerkleRoot; // root of Merkle tree only for jellyz holders

    mapping(address => bool) public whitelistMinted; // store if sender is already minted from white list
    mapping(address => bool) public jellyzWhitelistMinted;
    mapping(uint256 => uint8) private tickets; // minted tokens

    constructor(address _agregatorV3Interface) ERC721("NFT3 2022", "NFT32022") {
        priceFeed = AggregatorV3Interface(_agregatorV3Interface);
    }

    function mint(uint8 _mintAmount) public payable {
        require(mintStarted, "Mint is not started");
        require(_mintAmount <= batchLimit, "Not in batch limit");
        require(_mintAmount <= publicAvaliablSupply, "Too much tokens to mint");
        require(msg.value >= getMintPrice(_mintAmount), "Wrong amount of ETH");
        
        mintInternal(msg.sender, _mintAmount);
        publicAvaliablSupply -= _mintAmount;
    }

    function earlyMint(uint8 _mintAmount) public payable {
        require(mintEarlyStarted, "Mint for early access is not started");
        require(_mintAmount <= earlyBatchLimit, "Not in batch limit");
        require(msg.value >= convertToETH(_mintAmount * earlyMintPrice), "Wrong amount of ETH");
        require(_mintAmount <= earlyAccessAvaliableSupply, "Too much tokens to mint");
        require(!whitelistMinted[msg.sender], "Already minted in early access.");

        mintInternal(msg.sender, _mintAmount);
        earlyAccessAvaliableSupply -= _mintAmount;
        whitelistMinted[msg.sender] = true;
    }

    function giveawayMint(address _to, uint8 _mintAmount, uint8 _ticketRarity) public onlyOwner {
        require(_mintAmount <= giveawayAvaliableSupply[_ticketRarity], "Too much tokens to mint");

        mintInternal(_to, _mintAmount, _ticketRarity);
        totalMinted += _mintAmount;
        giveawayAvaliableSupply[_ticketRarity] -= _mintAmount;
    }

    function jellyzWhitelistMint(bytes32[] calldata _merkleProof, uint8 _mintAmount) public {
        require(mintJellyzWhitelistStarted, "Mint for whitelist is not started");
        require(_mintAmount <= batchLimit, "Not in batch limit");
        require(_mintAmount <= jellyzHoldersAvaliableSupply, "Too much tokens to mint");
        require(!jellyzWhitelistMinted[msg.sender], "Already minted from whitelist.");
        require(
            MerkleProof.verify(
                _merkleProof,
                jellyzMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Failed to verify proof."
        );

        mintInternal(msg.sender, _mintAmount, 0);
        jellyzHoldersAvaliableSupply -= _mintAmount;
        jellyzWhitelistMinted[msg.sender] = true;
    }

    function mintInternal(address _to, uint8 _mintAmount) private {
        for (uint i = 0; i < _mintAmount; i++) {
            uint id = totalMinted + i + 1;
            uint8 rarity = generateTicket(random(id));
            tickets[id] = rarity;
            rarityTicketsDistribution[rarity] -= 1;
            
            _mint(_to, id);
        }
        totalMinted += _mintAmount;
    }

    function mintInternal(address _to, uint8 _mintAmount, uint8 _rarity) private {
        for (uint i = 0; i < _mintAmount; i++) {
            uint id = totalMinted + i + 1;
            tickets[id] = _rarity;
            
            _mint(_to, id);
        }
        totalMinted += _mintAmount;
    }

    function generateTicket(uint256 _seed) private view returns (uint8 r) {           
        uint sumCoefficients = rarityTicketsDistribution[0] + rarityTicketsDistribution[1] + rarityTicketsDistribution[2] + rarityTicketsDistribution[3];

        uint rarityPercentage = _seed % sumCoefficients;
        r = 3;
        while(rarityPercentage >= rarityTicketsDistribution[r] && r > 0) {
            rarityPercentage -= rarityTicketsDistribution[r];
            r -= 1;
        }
    }

    function mintPriceInUSD(uint minted, uint8 mintAmount) public view returns (uint totalPrice) {
        uint mintSteps = minted / mintPriceChangeStep;
        totalPrice = (mintSteps * mintPriceCostStep + publicMintPrice) * mintAmount;
        // if part of items crosses step
        if((minted + mintAmount) / mintPriceChangeStep > mintSteps) {
            totalPrice += ((minted + mintAmount) % mintPriceChangeStep) * mintPriceCostStep;
        }
    }

    function getMintPrice(uint8 mintAmount) public view returns (uint totalPrice) {
        totalPrice = convertToETH(mintPriceInUSD(publicMaxSupply - publicAvaliablSupply, mintAmount)); 
    }

    function getLatestRate() public view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    function convertToETH(uint usdAmount) public view returns (uint ethAmount) {
        uint ethRate = getLatestRate(); // price of ETH in USD with 8 decimals
        // eth amount = usd amount 
        ethAmount = usdAmount * (10 ** 26) / ethRate;
    }

    function setPrices(uint _earlyMintPrice, uint _publicMintPrice, uint _publicMintPriceStep) public onlyOwner {
        earlyMintPrice = _earlyMintPrice; // convert to WEI
        publicMintPrice = _publicMintPrice;
        mintPriceCostStep = _publicMintPriceStep;
    } 

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setEarlyMintState(bool _mintState) external onlyOwner {
        mintEarlyStarted = _mintState;
    }

    function setJellyzWhitelistMintState(bool _mintState) external onlyOwner {
        mintJellyzWhitelistStarted = _mintState;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintState(bool _mintState) external onlyOwner {
        mintStarted = _mintState;
    }

    function setJellyzWhitelistRoot(bytes32 _merkleRoot) external onlyOwner {
        jellyzMerkleRoot = _merkleRoot;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setUnrevealedURIFlag(bool _flag) external onlyOwner {
        unrevealedURIFlag = _flag;
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory attributes;
        string memory imageUri;
        string memory animationUri;

        if (unrevealedURIFlag) {
            attributes = '{ "trait_type": "Ticket Type", "value": "Unrevealed"}';
            imageUri = string(abi.encodePacked(unrevealedURI, '0.png'));
            animationUri = string(abi.encodePacked(unrevealedURI, '0.mp4'));
        } else {
            attributes = string(abi.encodePacked(
                '{"trait_type": "Ticket", "value": "', ticketTypes[tickets[tokenId]],'" },',
                '{"trait_type": "Artist", "value": "NFT3" },',
                '{"trait_type": "Location", "value": "Los Angeles, CA" },',
                '{"trait_type": "Venue", "value": "The Millenium Biltmore Hotel"},',
                '{"trait_type": "Dates", "value": "Aug 5-7"},',
                '{"trait_type": "Series", "value": "2022"}'
                ));
            uint256 rarity = uint256(tickets[tokenId]);
            imageUri = string(abi.encodePacked(baseTokenURI, Strings.toString(rarity), '.png'));
            animationUri = string(abi.encodePacked(baseTokenURI, Strings.toString(rarity), '.mp4'));
        }
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{ "name": "Ticket #', Strings.toString(tokenId), '", ',
                '"description": "AWARDS GALA - MUSIC FESTIVAL - EXHIBITION - FASHION SHOW - ART GALLERY. NFT3 brings you the first first-ever 3-day/4-night NFT Music Festival along with a first-of-its-kind red carpet NFT Awards Gala, at the original home of the Academy Award, Exhibition, Fashion show, NFT Art Gallery, and more.", ',
                '"image": "', imageUri,'", ',
                '"animation_url": "', animationUri,'", ',
                '"attributes": [', attributes, ']}'
            ))
        ));
    }
}
