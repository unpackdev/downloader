// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz + @quentinmerabet

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC1155Receiver.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

import "./IResources.sol";
import "./IDeed.sol";

contract Deed is ERC721, IDeed, IERC1155Receiver, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private constant MAX_UINT64 = 0xFFFFFFFFFFFFFFFF;
    // Resources contract address
    address public immutable RESOURCES_ADDRESS;

    // Token id counter
    uint256 private _currentTokenId;
    // Mint trigger
    bool private _mintEnabled;

    // Metadata
    string private _metadataDescription = "Loading...";
    string private _metadataImageBaseURI = "https://deed.lvcidia.xyz/viewer/";

    // Resource id to contribution state
    mapping(uint256 => ContributionState) private _contribution;
    // User to resource id to contribution count
    mapping(address => mapping(uint256 => uint256))
        private _userContributionCount;
    // Deed token id to resource id to contribution count
    mapping(uint256 => mapping(uint256 => uint256))
        private _deedContributionCount;

    // Set of resource id's
    EnumerableSet.UintSet private _resources;

    // Royalty configuration
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address resourcesAddress) ERC721("LVCIDIA// DEED", "DEED") {
        RESOURCES_ADDRESS = resourcesAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IDeed-updateContribution}.
     */
    function updateContribution(
        uint256[] calldata resourceIds,
        Contribution[] calldata resourceContributions
    ) external override onlyOwner {
        require(
            resourceIds.length == resourceContributions.length,
            "Invalid input"
        );
        for (uint i = 0; i < resourceIds.length; ) {
            Contribution memory contribution = resourceContributions[i];
            _contribution[resourceIds[i]] = ContributionState({
                name: contribution.name,
                perUnit: contribution.perUnit,
                maxUnits: contribution.maxUnits,
                totalUnits: _contribution[resourceIds[i]].totalUnits
            });
            if (contribution.maxUnits == 0) {
                _resources.remove(resourceIds[i]);
            } else {
                _resources.add(resourceIds[i]);
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev See {IDeed-getContributionState}
     */
    function getContributionState(
        uint256 resourceId
    ) external view override returns (ContributionState memory) {
        return _contribution[resourceId];
    }

    /**
     * @dev See {IDeed-getUserContributions}
     */
    function getUserContributions(
        address user
    )
        public
        view
        override
        returns (
            ContributionInfo[] memory contributions,
            uint256 totalContributions
        )
    {
        contributions = new ContributionInfo[](_resources.length());
        for (uint i; i < _resources.length(); ) {
            uint256 resourceId = _resources.at(i);
            ContributionState memory contribution = _contribution[resourceId];
            uint256 units = _userContributionCount[user][resourceId];
            contributions[i] = ContributionInfo({
                resourceId: resourceId,
                resourceName: contribution.name,
                units: units,
                perUnit: contribution.perUnit
            });
            totalContributions += units;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IDeed-getDeedContributions}
     */
    function getDeedContributions(
        uint256 tokenId
    )
        public
        view
        override
        returns (
            ContributionInfo[] memory contributions,
            uint256 totalContributions
        )
    {
        contributions = new ContributionInfo[](_resources.length());
        for (uint i; i < _resources.length(); ) {
            uint256 resourceId = _resources.at(i);
            contributions[i] = ContributionInfo({
                resourceId: resourceId,
                resourceName: _contribution[resourceId].name,
                units: _deedContributionCount[tokenId][resourceId],
                perUnit: _contribution[resourceId].perUnit
            });
            totalContributions += _deedContributionCount[tokenId][resourceId];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IDeed-setMintEnabled}.
     */
    function setMintEnabled(bool enabled) external override onlyOwner {
        require(enabled != _mintEnabled, "should be a different value");
        _mintEnabled = enabled;
    }

    /**
     * @dev See {IDeed-mint}.
     */
    function mint() external override {
        if (!_mintEnabled) revert("Mint not open yet");
        uint256 tokenId = ++_currentTokenId;
        bool hasContributed = false;
        for (uint i = 0; i < _resources.length(); ) {
            uint256 resourceId = _resources.at(i);
            uint256 userContribution = _userContributionCount[msg.sender][
                resourceId
            ];
            _deedContributionCount[tokenId][resourceId] = userContribution;
            _userContributionCount[msg.sender][resourceId] = 0;
            if (
                _deedContributionCount[tokenId][resourceId] > 0 &&
                !hasContributed
            ) {
                hasContributed = true;
            }
            unchecked {
                i++;
            }
        }
        require(hasContributed, "No contributions yet");
        _mint(msg.sender, tokenId);
    }

    /**
     * @dev See {IDeed-merge}.
     */
    function merge(uint256[] calldata tokenIds) external override nonReentrant {
        uint256 newToken = ++_currentTokenId;
        uint256 resourcesLength = _resources.length();
        uint256 tokensLength = tokenIds.length;
        require(
            tokenIds.length > 1,
            "At least two tokens are required for merging"
        );
        for (uint i = 0; i < tokensLength; ) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Nonexistent or duplicated token");
            require(ownerOf(tokenId) == msg.sender, "Not owner");

            for (uint j = 0; j < resourcesLength; ) {
                uint256 resourceId = _resources.at(j);
                uint256 contribution = _deedContributionCount[tokenId][
                    resourceId
                ];
                if (contribution > 0) {
                    delete _deedContributionCount[tokenId][resourceId];
                }
                _deedContributionCount[newToken][resourceId] += contribution;
                unchecked {
                    j++;
                }
            }
            _burn(tokenId);
            unchecked {
                i++;
            }
        }
        _mint(msg.sender, newToken);
    }

    /**
     * @dev See {IDeed-split}.
     */
    function split(
        uint256 tokenA,
        uint256[] calldata tokenBUnits
    ) external override nonReentrant {
        require(_exists(tokenA), "Nonexistent token");
        require(ownerOf(tokenA) == msg.sender, "Not owner");
        uint256 resourcesLength = _resources.length();
        require(
            tokenBUnits.length == resourcesLength,
            "Invalid ressources info"
        );
        uint256 tokenB = ++_currentTokenId;
        uint256 tokenC = ++_currentTokenId;
        bool hasContributionsB;
        bool hasContributionsC;
        for (uint i = 0; i < resourcesLength; ) {
            uint256 resourceId = _resources.at(i);
            uint256 contributionA = _deedContributionCount[tokenA][resourceId];
            uint256 contributionB = tokenBUnits[i];
            require(
                contributionA >= contributionB,
                "Not enough resources to split"
            );
            uint256 contributionC = contributionA - tokenBUnits[i];
            if (contributionA > 0) {
                delete _deedContributionCount[tokenA][resourceId];
            }
            _deedContributionCount[tokenB][resourceId] = contributionB;
            _deedContributionCount[tokenC][resourceId] = contributionC;
            if (contributionB > 0) hasContributionsB = true;
            if (contributionC > 0) hasContributionsC = true;
            unchecked {
                i++;
            }
        }

        require(
            hasContributionsB && hasContributionsC,
            "A new deed must have contributions"
        );
        _burn(tokenA);
        _mint(msg.sender, tokenB);
        _mint(msg.sender, tokenC);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        require(!_mintEnabled, "Cannot contribute anymore");
        ContributionState storage contribution = _contribution[id];
        require(
            msg.sender == RESOURCES_ADDRESS && contribution.maxUnits > 0,
            "Invalid resource"
        );
        uint256 unitsAvailable = contribution.maxUnits -
            contribution.totalUnits;
        require(unitsAvailable > 0, "Contribution limit reached");
        require(value % contribution.perUnit == 0, "Invalid amount");
        uint256 unitsRequested = value / contribution.perUnit;
        uint256 units;
        if (unitsRequested > unitsAvailable) {
            units = unitsAvailable;
        } else {
            units = unitsRequested;
        }
        require(units > 0 && units <= MAX_UINT64, "Invalid units");
        _userContributionCount[from][id] += units;
        emit Contribute(id, from, uint64(units));
        contribution.totalUnits += uint64(units);

        uint256[] memory resourceIds = new uint256[](1);
        resourceIds[0] = id;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = units * contribution.perUnit;
        IResources(RESOURCES_ADDRESS).burn(address(this), resourceIds, amounts);
        if (units != unitsRequested) {
            IResources(RESOURCES_ADDRESS).safeTransferFrom(
                address(this),
                from,
                id,
                (unitsRequested - units) * contribution.perUnit,
                ""
            );
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        require(!_mintEnabled, "Cannot contribute anymore");
        uint256 resourceLength = ids.length;
        require(
            msg.sender == RESOURCES_ADDRESS && resourceLength == values.length,
            "Invalid resource"
        );
        bool hasContribution = false;
        bool hasExcess = false;
        uint256[] memory refundAmounts = new uint256[](resourceLength);
        uint256[] memory burnAmounts = new uint256[](resourceLength);
        for (uint i = 0; i < resourceLength; i++) {
            ContributionState storage contribution = _contribution[ids[i]];
            uint256 unitsAvailable = contribution.maxUnits -
                contribution.totalUnits;
            if (unitsAvailable == 0 || values[i] % contribution.perUnit != 0) {
                hasExcess = true;
                refundAmounts[i] = values[i];
                continue;
            }
            uint256 unitsRequested = values[i] / contribution.perUnit;
            uint256 units;
            if (unitsRequested > unitsAvailable) {
                units = unitsAvailable;
            } else {
                units = unitsRequested;
            }
            require(units <= MAX_UINT64, "Invalid amount");
            _userContributionCount[from][ids[i]] += units;
            emit Contribute(ids[i], from, uint64(units));
            contribution.totalUnits += uint64(units);
            burnAmounts[i] = units * contribution.perUnit;
            hasContribution = true;
            if (units != unitsRequested) {
                hasExcess = true;
                refundAmounts[i] =
                    (unitsRequested - units) *
                    contribution.perUnit;
            }
        }
        IResources(RESOURCES_ADDRESS).burn(address(this), ids, burnAmounts);
        if (hasExcess) {
            IResources(RESOURCES_ADDRESS).safeBatchTransferFrom(
                address(this),
                from,
                ids,
                refundAmounts,
                ""
            );
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IDeed-setMetadata}.
     */
    function setMetadata(
        string calldata description,
        string calldata imageBaseURI
    ) external override onlyOwner {
        if (bytes(description).length > 0) _metadataDescription = description;
        if (bytes(imageBaseURI).length > 0)
            _metadataImageBaseURI = imageBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        (
            ContributionInfo[] memory contributions,
            uint256 totalContributions
        ) = getDeedContributions(tokenId);

        string memory traits;
        // Ownership
        traits = string(
            abi.encodePacked(
                traits,
                '{"trait_type":"Planet Ownership","value":"',
                _unitToPercentage(totalContributions),
                '%"},'
            )
        );
        // Material
        traits = string(
            abi.encodePacked(
                traits,
                '{"trait_type":"Background Material","value":"',
                _getDeedMaterial(totalContributions, false),
                '"}'
            )
        );
        // Ressources yes/no
        for (uint i = 0; i < _resources.length(); ) {
            string memory activated;
            contributions[i].units > 0 ? activated = "YES" : activated = "NO";
            traits = string(
                abi.encodePacked(
                    traits,
                    ',{"trait_type":"',
                    contributions[i].resourceName,
                    '","value":"',
                    activated,
                    '"}'
                )
            );
            unchecked {
                i++;
            }
        }
        // Ressources levels
        for (uint i = 0; i < _resources.length(); ) {
            traits = string(
                abi.encodePacked(
                    traits,
                    ',{"trait_type":"',
                    contributions[i].resourceName,
                    '","value":',
                    (contributions[i].units * contributions[i].perUnit)
                        .toString(),
                    "}"
                )
            );
            unchecked {
                i++;
            }
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    '{"name":"',
                    _getDeedMaterial(totalContributions, true),
                    " DEED// #",
                    tokenId.toString(),
                    '","created_by":"LVCIDIA","description":"',
                    _metadataDescription,
                    '","image":"',
                    _metadataImageBaseURI,
                    tokenId.toString(),
                    '.png","attributes":[',
                    traits,
                    "]}"
                )
            );
    }

    /**
     * @dev Helper to convert deed unit to a string percentage
     */
    function _unitToPercentage(
        uint256 unit
    ) private pure returns (string memory) {
        string memory result = Strings.toString(unit / 1000);
        string memory decimal = Strings.toString(unit % 1000);
        while (bytes(decimal).length < 3) {
            decimal = string(abi.encodePacked("0", decimal));
        }
        result = string(abi.encodePacked(result, ".", decimal));
        return result;
    }

    /**
     * @dev Returns the material of the deed based on the total contributions
     */
    function _getDeedMaterial(
        uint256 totalContributions,
        bool caps
    ) private pure returns (string memory) {
        if (totalContributions < 10) {
            if (caps) {
                return "BLACK";
            } else {
                return "Black";
            }
        } else if (totalContributions < 50) {
            if (caps) {
                return "MARBLE";
            } else {
                return "Marble";
            }
        } else if (totalContributions < 200) {
            if (caps) {
                return "CHROME";
            } else {
                return "Chrome";
            }
        } else if (totalContributions < 1000) {
            if (caps) {
                return "JADE";
            } else {
                return "Jade";
            }
        } else {
            if (caps) {
                return "GOLD";
            } else {
                return "Gold";
            }
        }
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(
        address payable recipient,
        uint256 bps
    ) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(
        uint256
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(
        uint256
    ) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(
        uint256,
        uint256 value
    ) external view returns (address, uint256) {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }
}
