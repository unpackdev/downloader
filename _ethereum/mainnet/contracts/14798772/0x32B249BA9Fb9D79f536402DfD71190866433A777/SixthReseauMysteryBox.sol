//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";

/// @title SixthRéseau - MysteryBox Contract
/// @author SphericonIO
contract SixthReseauMysteryBox is ERC1155, Ownable, ERC1155Burnable {
    address public srli;
    address public migrationContract;

    string public name = "SixthReseau: Mystery Box";
    string public symbol = "SRMB";


    bool public migrationActive = false;

    string public tokenUri;

    constructor(string memory _tokenURI) ERC1155("") {
        tokenUri = _tokenURI;
    }
    
    function mint(address _to) public {
        require(msg.sender == srli, "SixthReseau: Mystery Box: Only main contract can mint!");
        _mint(_to, 1, 1, "");
    }

    function migrateToken(address _account) public {
        require(migrationActive, "SixthReseau: Mystery Box: Migration is not active!");
        require(msg.sender == migrationContract, "SixthReseau: Mystery Box: Only migration contract can migrate!");
        require(balanceOf(_account, 1) > 0, "SixthReseau: Mystery Box: Account does not have any tokens!");
        burn(_account, 1, 1);
    }

    function setSRLI(address _srli) external onlyOwner {
        srli = _srli;
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        tokenUri = newUri;
    }

    function toggleMigration() public onlyOwner {
        migrationActive = !migrationActive;
    }

    /// @notice Metadata of each token
    /// @param _tokenId Token id to get metadata of
    /// @return Metadata URI of the token
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(tokenUri, Strings.toString(_tokenId)));
    }
}