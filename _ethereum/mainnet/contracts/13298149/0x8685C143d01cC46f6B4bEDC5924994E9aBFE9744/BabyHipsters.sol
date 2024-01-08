// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 
 * /$$$$$$$            /$$                       /$$   /$$ /$$                       /$$                                  
 *| $$__  $$          | $$                      | $$  | $$|__/                      | $$                                  
 *| $$  \ $$  /$$$$$$ | $$$$$$$  /$$   /$$      | $$  | $$ /$$  /$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$   /$$$$$$$
 *| $$$$$$$  |____  $$| $$__  $$| $$  | $$      | $$$$$$$$| $$ /$$__  $$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$ /$$_____/
 *| $$__  $$  /$$$$$$$| $$  \ $$| $$  | $$      | $$__  $$| $$| $$  \ $$|  $$$$$$   | $$    | $$$$$$$$| $$  \__/|  $$$$$$ 
 *| $$  \ $$ /$$__  $$| $$  | $$| $$  | $$      | $$  | $$| $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$       \____  $$
 *| $$$$$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$$      | $$  | $$| $$| $$$$$$$/ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$       /$$$$$$$/
 *|_______/  \_______/|_______/  \____  $$      |__/  |__/|__/| $$____/ |_______/    \___/   \_______/|__/      |_______/ 
 *                               /$$  | $$                    | $$                                                        
 *                              |  $$$$$$/                    | $$                                                        
 *                               \______/                     |__/                                                    
 *                                                                                                       
 * 
 * Baby Hipsters are Crypto Punks offspring.
 *
 * In order to breed a Baby Hipster, you have to be the owner of two Crypto Punks, Wrapped Punks, 
 * or Crypto Punk Breeding Certificates (or any combination of them).
 *
 * Baby Hipsters are generated on-chain from the parents' attributes,
 * with new species resulting from the mix (like Alien Ape or Human Zombie Albino).
 * Their attributes and images are fully stored on-chain.
 *
 * Inspired by CryptoPunks, CryptoPunksData, Avastars and Loot,
 * but not affiliated with any of them.
 *
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**************************/
/***     Interfaces     ***/
/**************************/

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

interface IBreedingCertificates {
    function getPunkIndexFromCertificateId(uint256 _certificateId) external view returns (uint256);
    function useCertificate(uint _certificateId) external;
}

interface IBabyHipsterBuilder {
    function buildBabyHipster(uint256 tokenId, uint256 parent1, uint256 parent2) external returns (string[9] memory thisBabyHipsterAttributes);
    function buildBabyHipsterImage(string[9] memory thisBabyHipsterAttributes) external view returns (string memory svg);
}

contract BabyHipsters is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address internal constant CRYPTO_PUNKS_ADDR = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal constant WRAPPED_CRYPTO_PUNKS_ADDR = 0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6;
    address internal breedingCertificatesAddr;
    address internal babyHipsterBuilderAddr;

    uint internal constant PRICE_INCREMENT = 100000000 gwei;

    struct BabyHipster {
        string species;
        string ears;
        string topHead;
        string eyes;
        string neck;
        string face;
        string mouth;
        string mouthAccessory; 
        string facialHair;
    }

    mapping(uint256 => BabyHipster) public babyHipsterIdToAttributes;

    mapping(uint256 => uint256[2]) public babyHipsterIdToParents;

    constructor() ERC721("BabyHipsters", "BBPNKS") Ownable() payable {
    }

    function setBCertAddr(address contractAddr) public onlyOwner{
        breedingCertificatesAddr = contractAddr;
    }
    function setBabyHipsterBuilderAddr(address contractAddr) public onlyOwner{
        babyHipsterBuilderAddr = contractAddr;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function checkCryptoPunksIndexToAddress(uint256 punkIndex) internal view returns (address) {
        return ICryptoPunks(CRYPTO_PUNKS_ADDR).punkIndexToAddress(punkIndex);
    }

    function checkWrappedCryptoPunks(uint256 punkIndex) internal view returns (address owner) {
        return ERC721(WRAPPED_CRYPTO_PUNKS_ADDR).ownerOf(punkIndex);
    }

    function checkBreedingCertificateOwner(address owner, uint256 punkIndex) internal returns (bool) {
        uint balance = ERC721(breedingCertificatesAddr).balanceOf(owner);
        for (uint i = 0; i < balance; i++) {
            uint certId = ERC721Enumerable(breedingCertificatesAddr).tokenOfOwnerByIndex(owner, i);
            uint punkWithBCERT = IBreedingCertificates(breedingCertificatesAddr).getPunkIndexFromCertificateId(certId);
            if (punkIndex == punkWithBCERT) {
                IBreedingCertificates(breedingCertificatesAddr).useCertificate(certId);
                return true;
            }
        }
        return false;
    }

    function checkOwnership(uint256 punkIndex) internal returns (bool) {
        address cPunkOwner = checkCryptoPunksIndexToAddress(punkIndex);

        if (cPunkOwner == WRAPPED_CRYPTO_PUNKS_ADDR) {
            address wCPunkOwner = checkWrappedCryptoPunks(punkIndex);
            if (msg.sender == wCPunkOwner) {
                return true;
            } else {
                if (checkBreedingCertificateOwner(msg.sender, punkIndex)) {
                    return true;
                } else {
                    return false;
                }
            }
        } else {
            if (msg.sender == cPunkOwner) {
                return true;
            } else {
                if (checkBreedingCertificateOwner(msg.sender, punkIndex)) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getBabyHipsterStruct(uint256 tokenId) internal view returns (string[9] memory thisBabyHipsterAttributes) {
        thisBabyHipsterAttributes[0] = babyHipsterIdToAttributes[tokenId].species;
        thisBabyHipsterAttributes[1] = babyHipsterIdToAttributes[tokenId].ears;
        thisBabyHipsterAttributes[2] = babyHipsterIdToAttributes[tokenId].topHead;
        thisBabyHipsterAttributes[3] = babyHipsterIdToAttributes[tokenId].eyes;
        thisBabyHipsterAttributes[4] = babyHipsterIdToAttributes[tokenId].neck;
        thisBabyHipsterAttributes[5] = babyHipsterIdToAttributes[tokenId].face;
        thisBabyHipsterAttributes[6] = babyHipsterIdToAttributes[tokenId].mouth;
        thisBabyHipsterAttributes[7] = babyHipsterIdToAttributes[tokenId].mouthAccessory;
        thisBabyHipsterAttributes[8] = babyHipsterIdToAttributes[tokenId].facialHair;
        
        return thisBabyHipsterAttributes;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function getPrice() public view returns(uint) {
        return ((_tokenIdTracker.current() + 1 ) * PRICE_INCREMENT);
    }

    function withdraw(address _to) public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function breedBabyHipster(address to, uint256 parent1, uint256 parent2) public payable nonReentrant {
        require(parent1 != parent2, "BabyHipstersBreedBabyHipster: Must be different punks");
        require(msg.value >= getPrice(), "BabyHipstersBreedBabyHipster: Transaction value below current price");
        require(checkOwnership(parent1) && checkOwnership(parent2), "BabyHipstersBreedBabyHipster: You must own two Crypto Punks or Breeding Certificates");

        uint256 id = _tokenIdTracker.current();

        BabyHipster memory thisBabyHipster;

        string[9] memory thisBabyHipsterAttributes = IBabyHipsterBuilder(babyHipsterBuilderAddr).buildBabyHipster(id, parent1, parent2);

        thisBabyHipster.species = thisBabyHipsterAttributes[0];
        thisBabyHipster.ears = thisBabyHipsterAttributes[1];
        thisBabyHipster.topHead = thisBabyHipsterAttributes[2];
        thisBabyHipster.eyes = thisBabyHipsterAttributes[3];
        thisBabyHipster.neck = thisBabyHipsterAttributes[4];
        thisBabyHipster.face = thisBabyHipsterAttributes[5];
        thisBabyHipster.mouth = thisBabyHipsterAttributes[6];
        thisBabyHipster.mouthAccessory = thisBabyHipsterAttributes[7];
        thisBabyHipster.facialHair = thisBabyHipsterAttributes[8];
        
        babyHipsterIdToAttributes[id] = thisBabyHipster;

        babyHipsterIdToParents[id] = [parent1, parent2];

        safeMint(to, id);

        _tokenIdTracker.increment();
    }

    /**************************/
    /***      ERC-721       ***/
    /**************************/

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        require(_exists(tokenId), "BabyHipstersTokenURI: query for nonexistent token");
        string[9] memory thisPunkAttributes = getBabyHipsterStruct(tokenId);
        string memory babyHipsterSvg = IBabyHipsterBuilder(babyHipsterBuilderAddr).buildBabyHipsterImage(thisPunkAttributes);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Baby Hipster #', uint2str(tokenId), '", "description": "Baby Hipsters are generated from the parents attributes", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(babyHipsterSvg)), '"}'))));
        string memory metadata = string(abi.encodePacked("data:application/json;base64,", json));
        return metadata;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
