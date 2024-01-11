// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC1155.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title GrayBoys_Factions
 * @author @ScottMitchell18
 * @notice An NFT that is ERC1155 compliant and represents a faction association. Cannot be transferred unless revoked and can only be reassigned after 30 days regardless of revocation.
 */
contract GrayBoys_Factions is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// @notice Gray Boys contract
    IERC721 public immutable grayBoysContract;

    /// @dev Track the faction association
    struct Faction {
        uint256 faction;
        uint256 claimedAt;
    }

    /// @notice Base URI for metadata
    string public baseURI;

    /// @notice Sapen faction Id
    uint256 constant SAPEN = 1;

    /// @notice Enzeru faction Id
    uint256 constant ENZERU = 2;

    /// @notice Gorun faction Id
    uint256 constant GORUN = 3;

    /// @dev Valid faction type mapping
    mapping(uint256 => bool) public validFactions;

    /// @dev Faction count
    mapping(uint256 => uint256) public factionCounts;

    /// @dev Pledged faction mapping
    mapping(address => Faction) public factions;

    /// @dev Thrown on approval
    error CannotApproveAll();

    /// @dev Thrown on transfer
    error Nontransferable();

    constructor(address _grayBoysContractAddress) ERC1155("") {
        validFactions[SAPEN] = true;
        validFactions[ENZERU] = true;
        validFactions[GORUN] = true;
        grayBoysContract = IERC721(_grayBoysContractAddress);
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Claims association to a faction. Must own Gray Boy at time of claim. Mints an NFT representing a faction.
     * @param _factionId The faction type id (e.g 1, 2, 3)
     */
    function claim(uint256 _factionId) external nonReentrant {
        require(validFactions[_factionId], "Invalid faction.");
        require(
            factions[msg.sender].faction == 0,
            "Already part of faction. Must revoke."
        );
        uint256 claimedAt = factions[msg.sender].claimedAt;
        require(
            claimedAt == 0 || block.timestamp > claimedAt + 30 days,
            "Can only claim after 30 days."
        );
        uint256 gbBalance = grayBoysContract.balanceOf(msg.sender);
        require(gbBalance > 0, "Must own Gray Boy.");
        // Assign faction via mint
        _mint(msg.sender, _factionId, 1, "");
    }

    /**
     * @notice Revokes a faction association by burning the NFT
     */
    function revoke() external {
        Faction storage instance = factions[msg.sender];
        require(instance.faction > 0, "Not part of faction.");
        _burn(msg.sender, instance.faction, 1);
    }

    /**
     * @notice Returns address faction details
     * @param _address The address to look up faction
     */
    function getFactionInfo(address _address)
        public
        view
        returns (Faction memory)
    {
        return factions[_address];
    }

    /**
     * @notice Returns faction id of an address
     * @param _address The address to look up faction
     */
    function getFaction(address _address) public view returns (uint256) {
        return factions[_address].faction;
    }

    /**
     * @notice Returns faction count by faction Id
     * @param _factionId The address to look up faction
     */
    function getFactionCount(uint256 _factionId) public view returns (uint256) {
        return factionCounts[_factionId];
    }

    /**
     * @notice Returns faction id of sender
     */
    function myFaction() public view returns (uint256) {
        return factions[msg.sender].faction;
    }

    /**
     * @notice Returns the NFT name
     */
    function name() external pure returns (string memory) {
        return "Gray Boys Factions";
    }

    /**
     * @notice Returns the NFT symbol
     */
    function symbol() external pure returns (string memory) {
        return "GBF";
    }

    /**
     * @notice Returns the uri symbol
     */
    function uri(uint256 _factionId)
        public
        view
        override
        returns (string memory)
    {
        require(validFactions[_factionId], "URI request for invalid faction");
        return
            string(abi.encodePacked(baseURI, _factionId.toString(), ".json"));
    }

    /**
     * @dev Prevent approvals of token
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert CannotApproveAll();
    }

    /**
     * @dev Prevent token transfer unless burning
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        // Can only burn to AddressZero
        if (to != address(0) && from != address(0)) {
            revert Nontransferable();
        } else if (to != address(0)) {
            // Handle faction association when not going to AddressZero
            uint256 factionId = ids[0];
            factions[to].faction = factionId;
            factions[to].claimedAt = block.timestamp;
            factionCounts[factionId] = factionCounts[factionId] + 1;
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Address token association
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        // Remove faction association from wallet `from` if burning to address 0 and decrease count
        // Note: Does not reset the claimable timestamp, as you can only take action every X days
        if (from != address(0) && to == address(0)) {
            uint256 factionId = ids[0];
            factionCounts[factionId] = factionCounts[factionId] - 1;
            factions[from].faction = 0;
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
