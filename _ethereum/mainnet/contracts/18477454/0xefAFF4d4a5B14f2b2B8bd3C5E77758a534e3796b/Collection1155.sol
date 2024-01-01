// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./ERC2981Royalties.sol";

contract Collection1155 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC2981Royalties
{
    mapping(uint256 => RoyaltyInfo) internal _royalties;
    /// @custom:oz-upgrades-unsafe-allow constructor

     event BatchMintedWithoutBytes(
        address indexed account,
        uint256[] ids,
        uint256[] amounts,
        uint256[] royaltyValues
    );

    event AirDropEnabled(address account, bool enabled);

    string public name;
    string public symbol;

    constructor() {}

    function initialize(
        address newOwner,
        string memory metadataUri,
        string memory _name,
        string memory _symbol
    ) public initializer {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(metadataUri);
        __Ownable_init();
        transferOwnership(newOwner);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatchWithoutBytes(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory royaltyValues,
        address airdropContract
    ) public onlyOwner {
        require( ids.length == amounts.length && ids.length == royaltyValues.length, 'CollectionERC1155: Arrays length mismatch');
         _mintBatch(to, ids, amounts, "");
         for (uint256 i; i < ids.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    to, 
                    royaltyValues[i]
                );
            }
        }
        emit BatchMintedWithoutBytes(to, ids, amounts, royaltyValues);
        if(airdropContract != address(0)){
            setApprovalForAll(airdropContract, true);
            emit AirDropEnabled(airdropContract, true);
        }
    }
    
    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 1000, 'ERC2981Royalties: Too high');
        // Value is in basis points so 10000 = 100% , 100 = 1% etc
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (salePrice * royalties.amount) / 10000;
        return (receiver, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, ERC2981Royalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
