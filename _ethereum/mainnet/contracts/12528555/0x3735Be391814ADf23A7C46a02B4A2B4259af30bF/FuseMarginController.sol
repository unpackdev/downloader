// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IFuseMarginController.sol";

/// @author Ganesh Gautham Elango
/// @title Core contract for controlling the Fuse margin trading protocol
contract FuseMarginController is IFuseMarginController, ERC721, Ownable {
    /// @dev Gets a position address given an index (index = tokenId)
    address[] public override positions;
    /// @dev List of supported FuseMargin contracts
    address[] public override marginContracts;
    /// @dev Check if FuseMargin contract address is approved
    mapping(address => bool) public override approvedContracts;
    /// @dev Check if Connector contract address is approved
    mapping(address => bool) public override approvedConnectors;

    /// @dev Number of FuseMargin contracts
    uint256 private marginContractsNum = 0;
    /// @dev URL for position metadata
    string private metadataBaseURI;

    /// @param _metadataBaseURI URL for position metadata
    constructor(string memory _metadataBaseURI) ERC721("Fuse Margin Trading", "FUSE") {
        metadataBaseURI = _metadataBaseURI;
        emit SetBaseURI(_metadataBaseURI);
    }

    /// @dev Ensures functions are called from approved FuseMargin contracts
    modifier onlyMargin() {
        require(approvedContracts[msg.sender], "FuseMarginController: Not approved contract");
        _;
    }

    /// @dev Creates a position NFT, to be called only from FuseMargin
    /// @param user User to give the NFT to
    /// @param position The position address
    /// @return tokenId of the position
    function newPosition(address user, address position) external override onlyMargin returns (uint256) {
        positions.push(position);
        uint256 positionIndex = positions.length - 1;
        _safeMint(user, positionIndex);
        return positionIndex;
    }

    /// @dev Burns the position at the index, to be called only from FuseMargin
    /// @param tokenId tokenId of position to close
    function closePosition(uint256 tokenId) external override onlyMargin returns (address) {
        _burn(tokenId);
        return positions[tokenId];
    }

    /// @dev Adds support for a new FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function addMarginContract(address contractAddress) external override onlyOwner {
        require(!approvedContracts[contractAddress], "FuseMarginController: FuseMargin already exists");
        marginContracts.push(contractAddress);
        approvedContracts[contractAddress] = true;
        marginContractsNum++;
        emit AddMarginContract(contractAddress, msg.sender);
    }

    /// @dev Removes support for a FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function removeMarginContract(address contractAddress) external override onlyOwner {
        require(approvedContracts[contractAddress], "FuseMarginController: FuseMargin does not exist");
        approvedContracts[contractAddress] = false;
        marginContractsNum--;
        emit RemoveMarginContract(contractAddress, msg.sender);
    }

    /// @dev Adds support for a new Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function addConnectorContract(address contractAddress) external override onlyOwner {
        require(!approvedConnectors[contractAddress], "FuseMarginController: Connector already exists");
        approvedConnectors[contractAddress] = true;
        emit AddConnectorContract(contractAddress, msg.sender);
    }

    /// @dev Removes support for a Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function removeConnectorContract(address contractAddress) external override onlyOwner {
        require(approvedConnectors[contractAddress], "FuseMarginController: Connector does not exist");
        approvedConnectors[contractAddress] = false;
        emit RemoveConnectorContract(contractAddress, msg.sender);
    }

    /// @dev Modify NFT URL, to be called only from owner
    /// @param _metadataBaseURI URL for position metadata
    function setBaseURI(string memory _metadataBaseURI) external override onlyOwner {
        metadataBaseURI = _metadataBaseURI;
        emit SetBaseURI(_metadataBaseURI);
    }

    /// @dev Transfers token balance
    /// @param token Token address
    /// @param to Transfer to address
    /// @param amount Amount to transfer
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @dev Gets all approved margin contracts
    /// @return List of the addresses of the approved margin contracts
    function getMarginContracts() external view override returns (address[] memory) {
        address[] memory approvedMarginContracts = new address[](marginContractsNum);
        uint256 i = 0;
        for (uint256 j = 0; j < marginContracts.length; j++) {
            if (approvedContracts[marginContracts[j]]) {
                approvedMarginContracts[i] = marginContracts[j];
            }
            i++;
        }
        return approvedMarginContracts;
    }

    /// @dev Gets all tokenIds and positions a user holds, dont call this on chain since it is expensive
    /// @param user Address of user
    /// @return List of tokenIds the user holds
    /// @return List of positions the user holds
    function tokensOfOwner(address user) external view override returns (uint256[] memory, address[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(user));
        address[] memory addresses = new address[](balanceOf(user));
        uint256 i;
        for (uint256 j = 0; j < positions.length; j++) {
            if ((_exists(j)) && (user == ownerOf(j))) {
                tokens[i] = j;
                addresses[i] = positions[j];
            }
        }
        return (tokens, addresses);
    }

    /// @dev Returns number of positions created
    /// @return Length of positions array
    function positionsLength() external view override returns (uint256) {
        return positions.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURI;
    }
}
