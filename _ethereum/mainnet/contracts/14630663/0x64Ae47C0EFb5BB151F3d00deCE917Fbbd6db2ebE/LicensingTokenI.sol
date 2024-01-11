// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./ERC721.sol";

struct LicenseProps {
    string licenseType;
    uint256 licenseTerm;
    uint256 licensePrice;
    bool exclusive;
    uint256 tokenId;
    address tokenContractAddress;
    address tokenOwnerAddress;
    bytes32 databaseId;
    uint256 signatureTimeOut;
    bytes sellerSignature;
    bytes adminSignature;
    bool sellerRepresentation;
    address approvedBuyer;
    uint256 approvedFee;
}

struct License {
    string licenseType;
    uint256 buyerTokenId;
    uint256 expirationDate;
    bool exclusive;
}

struct LicenseTypeDetail {
    bool ignoreTimeout;
    uint256 maxExpirationDate;
    bool isExclusive;
}

struct MasterLicenseTypeDetail {
    bool ignoreTimeout;
    uint256 regularMaxExpirationDate;
    uint256 regularExclusiveMaxExpirationDate;
    uint256 masterMaxExpirationDate;
    uint256 masterExclusiveMaxExpirationDate;
}

interface LicensingTokenI is IERC721 {
    function safeMint(
        address _to,
        string memory licenseType,
        uint256 expirationDate,
        bool exclusive,
        uint256 _tokenId,
        address _tokenContractAddress,
        address _tokenOwnerAddress,
        bytes32 _databaseId
    ) external;

    function getMasterLicenseTypeDetails(address _address, uint256 _tokenId) external;
    
    function getLicenseTypeDetails(address _address, uint256 _tokenId, string memory _licenseType) external;

    function getLicenses(address _address, uint256 _tokenId, uint256 _offset, uint256 _to) external;
}
