// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";

interface CryptoPunksMarket {
    function punkIndexToAddress(uint256) external view returns (address);
}

interface LostPunkSociety is IERC721Enumerable {
    function punkAttributes(uint16) external view returns (string memory);
    function mintLostPunk(uint16, uint16) external payable;
}

//  ██╗      ██████╗ ███████╗████████╗██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗███████╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗
//  ██║     ██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██║   ██║████╗  ██║██║ ██╔╝██╔════╝████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝
//  ██║     ██║   ██║███████╗   ██║   ██████╔╝██║   ██║██╔██╗ ██║█████╔╝ ███████╗██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║   
//  ██║     ██║   ██║╚════██║   ██║   ██╔═══╝ ██║   ██║██║╚██╗██║██╔═██╗ ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║   
//  ███████╗╚██████╔╝███████║   ██║   ██║     ╚██████╔╝██║ ╚████║██║  ██╗███████║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║   
//  ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   
                                                                                                                                 
contract LostPunksMarket is Ownable {
    event PriceSet(address indexed from, uint256 indexed tokenId, uint256 priceInWei);
    event PriceCleared(address indexed from, uint256 indexed tokenId);
    event PartnerSet(address indexed from, uint256 indexed tokenId, uint256 indexed partnerTokenId);
    event PartnerCleared(address indexed from, uint256 indexed tokenId);
    event Claimed(address indexed from, address indexed to, uint256 indexed tokenId);

    CryptoPunksMarket private cryptoPunksMarket;
    LostPunkSociety private lostPunkSociety;
    mapping(uint16 => address) private virtualOwners;
    mapping(uint16 => bool) private hasPriceSet;
    mapping(uint16 => uint256) private pricesInWei;
    mapping(uint16 => bool) private hasPartnerSet;
    mapping(uint16 => uint16) private partners;
    
    uint256 private GLOBAL_PRICE_IN_WEI;
    bool private HAS_GLOBAL_PRICE_SET;
    uint16 private constant CRYPTO_PUNKS_COUNT = 10000;

    constructor() {
        cryptoPunksMarket = CryptoPunksMarket(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
        lostPunkSociety = LostPunkSociety(0xa583bEACDF3Ed3808402f8dB4F6628a7E1C6ceC6);
    }
    
//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
    
    function setGlobalPrice(bool hasGlobalPrice, uint256 globalPriceInWei) external onlyOwner {
        HAS_GLOBAL_PRICE_SET = hasGlobalPrice;
        GLOBAL_PRICE_IN_WEI = globalPriceInWei;
    }
    
    address private constant giveDirectlyDonationAddress = 0xc7464dbcA260A8faF033460622B23467Df5AEA42;
    
    function withdraw() external onlyOwner {
        uint256 donation = address(this).balance / 10;
        payable(giveDirectlyDonationAddress).transfer(donation);
        payable(owner()).transfer(address(this).balance); 
    }
    
//  ██████╗ ███████╗ █████╗ ██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██████╔╝█████╗  ███████║██║  ██║    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ██║  ██║███████╗██║  ██║██████╔╝    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

   function punkIndexToAddress(uint256 punkIndex) public view returns (address) {
        require(punkIndex < CRYPTO_PUNKS_COUNT);
        address virtualOwner = virtualOwners[uint16(punkIndex)];
        return (virtualOwner != address(0)) ? virtualOwner : cryptoPunksMarket.punkIndexToAddress(punkIndex);
    }
    
    function numberOfRemainingChildrenToMintForPunk(uint16 punkIndex) public view returns (uint8) {
        uint8 numberOfEmptyChildren = 0;
        bytes memory stringAsBytes = bytes(lostPunkSociety.punkAttributes(punkIndex));
        bytes memory buffer = new bytes(stringAsBytes.length);

        uint j = 0;
        for (uint i = 0; i < stringAsBytes.length; i++) {
            if (stringAsBytes[i] != ",") {
                buffer[j++] = stringAsBytes[i];
            } else {
                if (isEmptyChildAttribute(buffer, j)) {
                    numberOfEmptyChildren++;
                }
                i++; // skip space
                j = 0;
            }
        }
        if ((j > 0) && isEmptyChildAttribute(buffer, j)) {
            numberOfEmptyChildren++;
        }
        return numberOfEmptyChildren;
    }
    
    function isEmptyChildAttribute(bytes memory buffer, uint length) internal pure returns (bool) {
        return (length == 10) 
        && (buffer[0] == bytes1('C')) 
        && (buffer[1] == bytes1('h'))
        && (buffer[2] == bytes1('i'))
        && (buffer[3] == bytes1('l'))
        && (buffer[4] == bytes1('d'));
    }

    function hasPriceSetToMintRemainingChildrenForPunk(uint16 punkIndex) public view returns (bool) {
        require(punkIndex < CRYPTO_PUNKS_COUNT);
        return hasPriceSet[punkIndex] || HAS_GLOBAL_PRICE_SET;
    }

    function getPriceInWeiToMintRemainingChildrenForPunk(uint16 punkIndex) public view returns (uint256) {
        require(hasPriceSetToMintRemainingChildrenForPunk(punkIndex));
        return hasPriceSet[punkIndex] ? pricesInWei[punkIndex] : GLOBAL_PRICE_IN_WEI;
    }

//  ████████╗██████╗  █████╗ ██████╗ ██╗███╗   ██╗ ██████╗ 
//  ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ 
//     ██║   ██████╔╝███████║██║  ██║██║██╔██╗ ██║██║  ███╗
//     ██║   ██╔══██╗██╔══██║██║  ██║██║██║╚██╗██║██║   ██║
//     ██║   ██║  ██║██║  ██║██████╔╝██║██║ ╚████║╚██████╔╝
//     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function setPriceToMintRemainingChildrenForPunk(uint16 punkIndex, uint256 priceInWei) external {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        pricesInWei[punkIndex] = priceInWei;
        hasPriceSet[punkIndex] = true;
        emit PriceSet(punkOwner, punkIndex, priceInWei);
    }

    function clearPriceToMintRemainingChildrenForPunk(uint16 punkIndex) public {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        hasPriceSet[punkIndex] = false;
        pricesInWei[punkIndex] = 0;
        emit PriceCleared(punkOwner, punkIndex);
    }
    
    function claimRightToMintRemainingChildrenForPunk(uint16 punkIndex) external payable {
        require(getPriceInWeiToMintRemainingChildrenForPunk(punkIndex) <= msg.value);
        require(numberOfRemainingChildrenToMintForPunk(punkIndex) > 0);

        uint256 royalties = msg.value / 10;
        address previousOwner = punkIndexToAddress(punkIndex);
        payable(previousOwner).transfer(msg.value - royalties);

        virtualOwners[punkIndex] = msg.sender;
        clearPriceToMintRemainingChildrenForPunk(punkIndex);
        clearPartnerToMintChildrenForPunk(punkIndex);

        emit Claimed(previousOwner, msg.sender, punkIndex);
    }

//  ██████╗  █████╗ ██████╗ ████████╗███╗   ██╗███████╗██████╗ ██╗███╗   ██╗ ██████╗ 
//  ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝████╗  ██║██╔════╝██╔══██╗██║████╗  ██║██╔════╝ 
//  ██████╔╝███████║██████╔╝   ██║   ██╔██╗ ██║█████╗  ██████╔╝██║██╔██╗ ██║██║  ███╗
//  ██╔═══╝ ██╔══██║██╔══██╗   ██║   ██║╚██╗██║██╔══╝  ██╔══██╗██║██║╚██╗██║██║   ██║
//  ██║     ██║  ██║██║  ██║   ██║   ██║ ╚████║███████╗██║  ██║██║██║ ╚████║╚██████╔╝
//  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function setPartnerToMintChildrenForPunk(uint16 punkIndex, uint16 partnerIndex) external {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        partners[punkIndex] = partnerIndex;
        hasPartnerSet[punkIndex] = true;
        emit PartnerSet(punkOwner, punkIndex, partnerIndex);
    }
    
    function clearPartnerToMintChildrenForPunk(uint16 punkIndex) public {
        address punkOwner = punkIndexToAddress(punkIndex);
        require(punkOwner == msg.sender);
        hasPartnerSet[punkIndex] = false;
        partners[punkIndex] = 0;
        emit PartnerCleared(punkOwner, punkIndex);
    }

    function mintDistributedChildrenForPartnerPunks(uint16 fatherIndex, uint16 motherIndex) external {
        require(hasPartnerSet[fatherIndex]);
        require(hasPartnerSet[motherIndex]);
        require(partners[fatherIndex] == motherIndex);
        require(partners[motherIndex] == fatherIndex);
        require(numberOfRemainingChildrenToMintForPunk(fatherIndex) >= 2);
        require(numberOfRemainingChildrenToMintForPunk(motherIndex) >= 2);
        
        address fatherOwner = punkIndexToAddress(fatherIndex);
        address motherOwner = punkIndexToAddress(motherIndex);
        virtualOwners[fatherIndex] = address(this);
        virtualOwners[motherIndex] = address(this);
        
        uint256 child1Index = CRYPTO_PUNKS_COUNT + lostPunkSociety.totalSupply();
        lostPunkSociety.mintLostPunk(fatherIndex, motherIndex);
        uint256 child2Index = CRYPTO_PUNKS_COUNT + lostPunkSociety.totalSupply();
        lostPunkSociety.mintLostPunk(fatherIndex, motherIndex);
        
        lostPunkSociety.safeTransferFrom(address(this), fatherOwner, child1Index);
        lostPunkSociety.safeTransferFrom(address(this), motherOwner, child2Index);
        
        virtualOwners[fatherIndex] = fatherOwner;
        virtualOwners[motherIndex] = motherOwner;
    }
}
