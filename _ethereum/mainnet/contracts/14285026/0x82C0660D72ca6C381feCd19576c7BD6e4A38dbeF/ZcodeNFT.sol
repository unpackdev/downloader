//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract ZcodeNFT is Ownable, ERC721Pausable {
    //financial
    address payable receiver =
        payable(0xa02a075bd90195061cf790E206b7ca7cE0d6afD2);
    address payable dev = payable(0xC5C485fCBF8C8b60Fb395FfEB53BA804e0dCdEe0);

    uint256 priceGold = 0.05 ether;
    uint256 pricePlat = 0.3 ether;
    uint256 priceLegend = 1.0 ether;

    bool public mintIsLive;

    //metadata todo check
    string theBaseURI =
        "ipfs://QmPXFiucDue6CMxmZJPWL4atM6bXrbqBJZ97jFyuk8owkK/";
    bool frozen;

    //reveal type 0: unassigned, 1: gold, 2: plat, 3: legendary
    mapping(uint256 => uint256) tier;

    // nft reserves
    uint256 public currentTotal;
    uint256 public maxSupply = 1050;

    uint256 public currentMintGold;
    uint256 public currentMintPlat;
    uint256 public currentMintLegend;

    uint256 public reserveMintGold = 950 + 3 + 1;
    uint256 public reserveMintPlat = 33 + 2;
    uint256 public reserveMintLegend = 5;

    uint256 public currentAirGold;
    uint256 public currentAirPlat;
    uint256 public currentAirLegend;

    uint256 public reserveAirGold = 50;
    uint256 public reserveAirPlat = 4;
    uint256 public reserveAirLegend = 2;

    uint256 public txLimit = 10;

    constructor() ERC721("ZCode Doge NFT", "ZCODE") {}

    function getTier(uint256 tokenid) external view returns (uint256) {
        return tier[tokenid];
    }

    function isGold(uint256 tokenid) external view returns (bool) {
        return (tier[tokenid] == 1);
    }

    function isPlatinum(uint256 tokenid) external view returns (bool) {
        return (tier[tokenid] == 2);
    }

    function isLegendary(uint256 tokenid) external view returns (bool) {
        return (tier[tokenid] == 3);
    }

    function setBasePrices(
        uint256 goldprice,
        uint256 platprice,
        uint256 legendprice
    ) external onlyOwner {
        priceGold = goldprice;
        pricePlat = platprice;
        priceLegend = legendprice;
    }

    function withdraw() external {
        uint256 amount = address(this).balance;
        uint256 sh97 = (amount * 97) / 100;
        uint256 sh3 = (amount * 3) / 100;
        (bool success1, ) = receiver.call{value: sh97}("");
        require(success1, "Failed to send Ether 1");
        (bool success2, ) = dev.call{value: sh3}("");
        require(success2, "Failed to send Ether 2");
    }

    function getGoldPrice() public view returns (uint256) {
        uint256 ret = priceGold;
        if (reserveMintGold - currentMintGold <= 500) {
            ret *= 2;
        }
        if (reserveMintGold - currentMintGold <= 250) {
            ret *= 2;
        }
        return ret;
    }

    function getPlatPrice() public view returns (uint256) {
        uint256 ret = pricePlat;
        if (reserveMintPlat - currentMintPlat <= 20) {
            ret *= 2;
        }
        if (reserveMintPlat - currentMintPlat <= 10) {
            ret *= 2;
        }
        return ret;
    }

    function getLegendPrice() public view returns (uint256) {
        uint256 ret = priceLegend;
        if (reserveMintLegend - currentMintLegend <= 3) {
            ret *= 2;
        }
        if (reserveMintLegend - currentMintLegend <= 1) {
            ret *= 2;
        }
        return ret;
    }

    function toggleMint() external onlyOwner {
        mintIsLive = !mintIsLive;
    }

    //reserve Update
    function changeReserves(
        uint256 goldair,
        uint256 goldmint,
        uint256 platair,
        uint256 platmint,
        uint256 legendair,
        uint256 legendmint
    ) external onlyOwner {
        require(goldair <= currentAirGold, "Already airdropped more Gold");
        require(goldmint <= currentMintGold, "Already minted more Gold");
        require(platair <= currentAirPlat, "Already airdropped more Platinum");
        require(platmint <= currentMintPlat, "Already minted more Platinum");
        require(
            legendair <= currentAirLegend,
            "Already airdropped more Legendary"
        );
        require(
            legendmint <= currentMintLegend,
            "Already minted more Legendary"
        );
        reserveAirGold = goldair;
        reserveMintGold = goldmint;
        reserveAirPlat = platair;
        reserveMintPlat = platmint;
        reserveAirLegend = legendair;
        reserveMintLegend = legendmint;
    }

    //airdrops
    function airdropGold(address[] calldata winners, uint256[] calldata quanty)
        external
        onlyOwner
    {
        require(
            winners.length == quanty.length,
            "Mismatch of airdrop information"
        );
        for (uint256 i = 0; i < winners.length; i++) {
            require(
                currentAirGold + quanty[i] <= reserveAirGold,
                "Gold Airdrop exhausted"
            );
            currentAirGold += quanty[i];
            for (uint256 j = 0; j < quanty[i]; j++) {
                tier[currentTotal + j] = 1;
            }
            _mint_NFT(winners[i], quanty[i]);
        }
    }

    function airdropPlat(address[] calldata winners, uint256[] calldata quanty)
        external
        onlyOwner
    {
        require(
            winners.length == quanty.length,
            "Mismatch of airdrop information"
        );
        for (uint256 i = 0; i < winners.length; i++) {
            require(
                currentAirPlat + quanty[i] <= reserveAirPlat,
                "Platinum Airdrop exhausted"
            );
            currentAirPlat += quanty[i];
            for (uint256 j = 0; j < quanty[i]; j++) {
                tier[currentTotal + j] = 2;
            }
            _mint_NFT(winners[i], quanty[i]);
        }
    }

    function airdropLegend(
        address[] calldata winners,
        uint256[] calldata quanty
    ) external onlyOwner {
        require(
            winners.length == quanty.length,
            "Mismatch of airdrop information"
        );
        for (uint256 i = 0; i < winners.length; i++) {
            require(
                currentAirLegend + quanty[i] <= reserveAirLegend,
                "Platinum Airdrop exhausted"
            );
            currentAirLegend += quanty[i];
            for (uint256 j = 0; j < quanty[i]; j++) {
                tier[currentTotal + j] = 3;
            }
            _mint_NFT(winners[i], quanty[i]);
        }
    }

    //metadata
    modifier isNotFrozen() {
        require(!frozen, "Metadata is frozen");
        _;
    }

    function freezeMeta() external onlyOwner {
        //Attention: Cannot be reversed
        frozen = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return theBaseURI;
    }

    function setBaseURI(string memory url) external onlyOwner isNotFrozen {
        theBaseURI = url;
    }

    function mintGold(uint256 howmany) external payable {
        require(mintIsLive, "Mint has not started");
        require(howmany <= txLimit, "Transaction limit reached");
        require(
            currentMintGold + howmany <= reserveMintGold,
            "Gold Reserve empty"
        );
        require(
            howmany * getGoldPrice() <= msg.value,
            "Insufficient Funds for Gold"
        );
        currentMintGold += howmany;
        for (uint256 j = 0; j < howmany; j++) {
            tier[currentTotal + j] = 1;
        }
        _mint_NFT(msg.sender, howmany);
    }

    function mintPlat(uint256 howmany) external payable {
        require(mintIsLive, "Mint has not started");
        require(howmany <= txLimit, "Transaction limit reached");
        require(
            currentMintPlat + howmany <= reserveMintPlat,
            "Plat Reserve empty"
        );
        require(
            howmany * getPlatPrice() <= msg.value,
            "Insufficient Funds for Platinum"
        );
        currentMintPlat += howmany;
        for (uint256 j = 0; j < howmany; j++) {
            tier[currentTotal + j] = 2;
        }
        _mint_NFT(msg.sender, howmany);
    }

    function mintLegend(uint256 howmany) external payable {
        require(mintIsLive, "Mint has not started");
        require(howmany <= txLimit, "Transaction limit reached");
        require(
            currentMintLegend + howmany <= reserveMintLegend,
            "Legendary Reserve empty"
        );
        require(
            howmany * getLegendPrice() <= msg.value,
            "Insufficient Funds for Legendary"
        );
        currentMintLegend += howmany;
        for (uint256 j = 0; j < howmany; j++) {
            tier[currentTotal + j] = 3;
        }
        _mint_NFT(msg.sender, howmany);
    }

    //increase tier of Lottery Winners
    function alterTier(uint256[] calldata tokenIds, uint256[] calldata newTier)
        external
        onlyOwner
        isNotFrozen
    {
        require(tokenIds.length == newTier.length, "Mismatch of newtier info");
        for (uint256 j = 0; j < tokenIds.length; j++) {
            tier[tokenIds[j]] = newTier[j];
        }
    }

    //minting
    function _mint_NFT(address who, uint256 howmany) internal {
        require(currentTotal + howmany <= maxSupply, "All NFTs minted");
        for (uint256 j = 0; j < howmany; j++) {
            _mint(who, currentTotal);
            currentTotal += 1;
        }
    }

    function emergencyHalt() external onlyOwner isNotFrozen {
        _pause();
    }

    function emergencyContinue() external onlyOwner {
        _unpause();
    }
}
