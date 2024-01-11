// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./LicensingTokenI.sol";
import "./AccessControl.sol";

/**
 * @title LicensingToken
 * @dev This contract allows minting licenses for other ERC721 collections.
 * This contract is managed by the LicenseOps contract.
 */
contract LicensingToken is ERC721, AccessControl {
    // the current tokenId
    uint256 public tokenId;

    // baseURI is the base URI for the license.
    string internal baseUri;

    // Emmited when a new buyer token is minted
    event MintBuyerToken(uint256 indexed _tokenId, bytes32 indexed _databaseId);
    // Emmited when a new seller token is minted
    event MintSellerToken(uint256 indexed _tokenId, bytes32 indexed _databaseId);

    // Role who can mint on this contract, the address is the licenseOps
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 private constant OPERATIONS_ROLE = keccak256("OPERATIONS_ROLE");

    // License - > expiration date - store always the biggest value
    mapping(bytes32 => LicenseTypeDetail) private licenseTypeDetails;

    //
    mapping(bytes32 => MasterLicenseTypeDetail) private masterLicenseTypeDetails;

    // Mapping from licensor contract address + licensor tokenid to buyer licenses + licenseType
    mapping(bytes32 => License[]) public registeredLicenses;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor() ERC721("Feature IP Licensing", "FTR-IP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Safe mint two token one for seller and one for the buyer.
     *
     * @param _to the buyer address
     * @param _licenseType type of license
     * @param _expirationDate expiration date of license - timestamp of when it will expire - it is already validated that it is bigger than block.timestamp
     * @param _exclusive if license is exclusive
     * @param _tokenId licensor tokenid
     * @param _tokenContractAddress licensor contract address
     * @param _tokenOwnerAddress licensor wallet address
     * @param _databaseId license database id
     */
    function safeMint(
        address _to,
        string calldata _licenseType,
        uint256 _expirationDate,
        bool _exclusive,
        uint256 _tokenId,
        address _tokenContractAddress,
        address _tokenOwnerAddress,
        bytes32 _databaseId
    ) external onlyRole(MINTER_ROLE) {
        MasterLicenseTypeDetail memory masterLicenseTypeDetail = masterLicenseTypeDetails[
            concatenateLicenseTypeHash(
                concatenateLicenseHash(_tokenContractAddress, _tokenId),
                "MASTER"
            )
        ];

        // If it's going to mint any license, it shouldnt exist a exclusive master license.
        require(masterLicenseTypeDetail.masterExclusiveMaxExpirationDate <= block.timestamp,
            "LT: Cannot mint. It has a valid exclusive master license."
        );

        if (keccak256(abi.encodePacked(_licenseType)) == keccak256(abi.encodePacked("MASTER"))) {
            // it is going to mint a master so it cannot have an exclusive license that is not expired
            // check for other exclusive licenses TV, DISPLAY
            require(masterLicenseTypeDetail.regularExclusiveMaxExpirationDate <= block.timestamp,
                "LT: Cannot mint Master. It has a exclusive license and is not expired."
            );

            if (_exclusive == true) {
                // if exclusive, it cannot have a master license that is valid
                // ex. there is a non master exlcusive license that is not expired, and we try to mint an exclusive master license
                require(masterLicenseTypeDetail.masterMaxExpirationDate <= block.timestamp,
                    "LT: Cannot mint exclusive Master. It has a valid Master license."
                );

                // if exclusive, it cannot have a non master license that is valid
                // any licenses that is not exclusive
                require(masterLicenseTypeDetail.regularMaxExpirationDate <= block.timestamp,
                    "LT: Cannot mint exclusive Master. It has a valid regular license."
                );
                masterLicenseTypeDetail.masterExclusiveMaxExpirationDate = _expirationDate;
            } else {
                // it isn't a Master exclusive, so update max expiration date
                if (masterLicenseTypeDetail.masterMaxExpirationDate <= _expirationDate) {
                    masterLicenseTypeDetail.masterMaxExpirationDate = _expirationDate;
                }
            }

            // update storage
            masterLicenseTypeDetails[
                concatenateLicenseTypeHash(
                    concatenateLicenseHash(_tokenContractAddress, _tokenId),
                    "MASTER"
                )
            ] = masterLicenseTypeDetail;
            ///
        } else {
            LicenseTypeDetail memory licenseTypeDetail = licenseTypeDetails[
                concatenateLicenseTypeHash(
                    concatenateLicenseHash(_tokenContractAddress, _tokenId),
                    _licenseType
                )
            ];
            if (_exclusive == true) {
                // if it is exclusive, it cannot have another license of the same type valid,
                require(licenseTypeDetail.maxExpirationDate <= block.timestamp,
                    "LT: Cannot mint exclusive license. It has a valid license."
                );

                // it cannot have a Master that is valid.
                require(masterLicenseTypeDetail.masterMaxExpirationDate <= block.timestamp,
                    "LT: Cannot mint exclusive license. It has a valid Master licenses."
                );

                if (!licenseTypeDetail.isExclusive) {
                    licenseTypeDetail.isExclusive = true;
                }

                if (masterLicenseTypeDetail.regularExclusiveMaxExpirationDate <= _expirationDate
                ) {
                    masterLicenseTypeDetail.regularExclusiveMaxExpirationDate = _expirationDate;

                    // update storage
                    masterLicenseTypeDetails[
                        concatenateLicenseTypeHash(
                            concatenateLicenseHash(_tokenContractAddress, _tokenId),
                            "MASTER"
                        )
                    ] = masterLicenseTypeDetail;
                }
            } else {
                // check if there was an exclusive license and it should be expired to be able to mint a non exclusive license
                if (licenseTypeDetail.isExclusive) {
                    require(licenseTypeDetail.maxExpirationDate <= block.timestamp,
                        "LT: Cannot mint a license. It has a valid exclusive license."
                    );

                    // it was exclusive, but is expired, so set to false
                    licenseTypeDetail.isExclusive = false;
                }

                // store the max
                if (masterLicenseTypeDetail.regularMaxExpirationDate <= _expirationDate
                ) {
                    masterLicenseTypeDetail.regularMaxExpirationDate = _expirationDate;

                    // update storage
                    masterLicenseTypeDetails[
                        concatenateLicenseTypeHash(
                            concatenateLicenseHash(_tokenContractAddress, _tokenId),
                            "MASTER"
                        )
                    ] = masterLicenseTypeDetail;
                }
            }

            // update expiration date if this new non exclusive license has a longer expiration date
            // _expirationDate is always greater than block.timestamp
            if (licenseTypeDetail.maxExpirationDate < _expirationDate
            ) {
                licenseTypeDetail.maxExpirationDate = _expirationDate;
            }

            // update storage
            licenseTypeDetails[
                concatenateLicenseTypeHash(
                    concatenateLicenseHash(_tokenContractAddress, _tokenId),
                    _licenseType
                )
            ] = licenseTypeDetail;
        }

        // Buyer Token
        unchecked {
            ++tokenId;
        }

        uint256 buyerTokenId = tokenId;

        //seller token
        unchecked {
            ++tokenId;
        }

        _safeMint(_to, buyerTokenId);
        emit MintBuyerToken(buyerTokenId, _databaseId);

        _safeMint(_tokenOwnerAddress, tokenId);
        emit MintSellerToken(tokenId, _databaseId);

        License memory newLicense = License(
            _licenseType,
            buyerTokenId,
            _expirationDate,
            _exclusive
        );

        // Return the license hash if the license is already registered
        License[] storage licenses = registeredLicenses[
            concatenateLicenseHash(_tokenContractAddress, _tokenId)
        ];
        licenses.push(newLicense);

        registeredLicenses[concatenateLicenseHash(_tokenContractAddress, _tokenId)] = licenses;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721) {
        // all buyer token has a seller token.
        //if it is equal to zero, it is a seller token and only admin can transfer it.
        if (_tokenId % 2 == 0) {
            require(
                hasRole(OPERATIONS_ROLE, msg.sender),
                "LT: Only admin can transfer a licensor token"
            );
        }
        else {
            //solhint-disable-next-line max-line-length
            require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        }

        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Join the licensor contract address and tokenID to a bytes32 value
     *
     * @param _tokenContractAddress the licensor contract address ex: ape contract address
     * @param _tokenId the licensor tokenId ex: ape tokenId
     */
    function concatenateLicenseHash(address _tokenContractAddress, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenContractAddress, _tokenId));
    }

    /**
     * @dev Join the licensor contract address and tokenID to a bytes32 value
     *
     * @param _licenseHash the licensor contract address hashed by concatenateLicenseHash
     * @param _licenseType the licensor type ex: TV, DISPLAY, MASTER
     */
    function concatenateLicenseTypeHash(bytes32 _licenseHash, string memory _licenseType)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_licenseHash, _licenseType));
    }

    /**
     * @dev Returns a Master license details to control expiration dates
     *
     * @param _tokenContractAddress the licensor contract address
     * @param _tokenId the licensor tokenId
     */
    function getMasterLicenseTypeDetails(address _tokenContractAddress, uint256 _tokenId)
        external
        view
        returns (MasterLicenseTypeDetail memory)
    {
        return
            masterLicenseTypeDetails[
                concatenateLicenseTypeHash(concatenateLicenseHash(_tokenContractAddress, _tokenId), "MASTER")
            ];
    }

    /**
     * @dev Returns a regular license details based on licensor contract address and licensor tokenId
     *      to control expiration dates
     *
     * @param _tokenContractAddress the licensor contract address
     * @param _tokenId the licensor tokenId
     * @param _licenseType type of license
     */
    function getLicenseTypeDetails(
        address _tokenContractAddress,
        uint256 _tokenId,
        string memory _licenseType
    ) external view returns (LicenseTypeDetail memory) {
        return
            licenseTypeDetails[
                concatenateLicenseTypeHash(
                    concatenateLicenseHash(_tokenContractAddress, _tokenId),
                    _licenseType
                )
            ];
    }

    /**
     * @dev Returns a buyer license based on licensor contract address and licensor tokenId.
     * To get all licenses, _offset should be 0 and _to shoud be equal to length. ie: It has 10 licenses
     * so _offset is 0 and _to is 10. If you want licenses 5, 6 and 7, _offset is 4 and _to is 7 and it will
     * return licenses[4], * return licenses[5] and licenses[6].
     *
     * @param _tokenContractAddress the licensor contract address
     * @param _tokenId the licensor tokenId
     * @param _offset initial index of the list to get license (can be from 0 until the last license index)
     * @param _to end index of the list to get license (cannot be greater than length of the array)
     */
    function getLicenses(
        address _tokenContractAddress,
        uint256 _tokenId,
        uint256 _offset,
        uint256 _to
    ) external view returns (License[] memory _resultArr) {
        License[] memory licenses = registeredLicenses[concatenateLicenseHash(_tokenContractAddress, _tokenId)];
        uint256 size = _to - _offset;
        _resultArr = new License[](size);

        for (uint256 i = _offset; i < _to; i++) {
            License memory _license = licenses[i];
            _resultArr[i - _offset] = _license;
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @dev Sets new minter address. Only Owner can call this function.
    function updateMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _minter);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseUri;
    }

    /// @dev Sets baseURI of the license tokens.
    function setBaseURI(string memory _baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_baseUri).length > 0, "Base URI was not set");
        baseUri = _baseUri;
    }

    /// @dev Updates the admin role of this contract
    function setAdminRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /// @dev Updates the operation role of this contract
    function setOperationsRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(OPERATIONS_ROLE, _address);
    }
}
