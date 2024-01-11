// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

import "./IMigrateContract.sol";

import "./LaCollectionAccess.sol";

interface INewContract {
    function migrateTokens(uint256[] calldata tokenIds, address to) external;
}

/**
 * @title LaCollectionAnnaRidler
 */
contract LaCollectionAnnaRidler is ERC721URIStorage, ERC721Burnable, Pausable, LaCollectionAccess {
    using SafeMath for uint256;

    uint256 genesisDate = 0;
    bool wasFlowered = false;

    INewContract public newContract;

    // Emitted on StartFlowering
    event StartFlowering(
        uint256 indexed tokenId
    );
     // Emitted on EndFlowering
    event EndFlowering(
        uint256 indexed tokenId
    );
    constructor() ERC721("LaCollectionAnnaRidler", "LCAR") {
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function getTimestamp() public view returns (uint256) {
        return  block.timestamp;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function startFlowering(address _to, string memory _tokenURI) external whenNotPaused onlyMinter {
        require(
            genesisDate == 0,
            "LaCollectionAnnaRidler: Flowering already did"
        );
        // Prevent missing token URI
        require(
            bytes(_tokenURI).length != 0,
            "LaCollectionAnnaRidler: Token URI is missing"
        );
        genesisDate = block.timestamp;
        // Genesis of the flower
        super._mint(_to, 1);
        super._setTokenURI(1,  _tokenURI);
        emit StartFlowering(1);
    }

    function endFlowering(string memory _tokenURI) external whenNotPaused onlyMinter {
        require(
            genesisDate > 0,
            "LaCollectionAnnaRidler: Flowering not started"
        );
        require(
            wasFlowered == false,
            "LaCollectionAnnaRidler: Flowering already happened"
        );
        // Prevent missing token URI
        require(
            bytes(_tokenURI).length != 0,
            "LaCollectionAnnaRidler: Token URI is missing"
        );
        genesisDate = block.timestamp;
        super._setTokenURI(1,  _tokenURI);
        emit EndFlowering(1);
         wasFlowered = true;
    }

    function burn(uint256 tokenId) public override whenNotPaused onlyOwner {
        genesisDate = 0;
        super._burn(1);
     }
    
    /// @dev Set the potential next version contract
    function setNewContract(address newContractAddress) external onlyOwner {
        require(
            address(newContract) == address(0),
            "LaCollection: NewContract already set"
        );
        newContract = INewContract(newContractAddress);
    }

    /// @dev Migrates tokens to a potential new version of this contract
    /// @param tokenIds - list of tokens to transfer
    function migrateTokens(uint256[] calldata tokenIds) external {
        require(
            address(newContract) != address(0),
            "LaCollection: New contract not set"
        );

        for (uint256 index = 0; index < tokenIds.length; index++) {
            transferFrom(_msgSender(), address(this), tokenIds[index]);
        }

        newContract.migrateTokens(tokenIds, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
