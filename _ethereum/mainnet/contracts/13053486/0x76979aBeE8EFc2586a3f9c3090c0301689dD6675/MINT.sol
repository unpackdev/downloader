//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";

contract MINT is ERC721PresetMinterPauserAutoIdUpgradeable {

    mapping (uint256 => address) private _tokenCreators;

    // TODO: 継承元のinitializeを削除
    function initialize(string memory _name, string memory _symbol, string memory _baseURI) public override initializer {
        __ERC721PresetMinterPauserAutoId_init(_name, _symbol, _baseURI);
        setOwner(_msgSender());
    }

    // TODO: 継承元のmintを削除
    function mint(address _to, uint256 _tokenId, string memory _tokenURI, address _creator) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINT: must have minter role to mint");

        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _tokenCreators[_tokenId] = _creator;
    }

    function creatorOf(uint256 _tokenId) public view returns (address) {
        address creator = _tokenCreators[_tokenId];
        require(creator != address(0), "MINT: creator query for nonexistent token");
        return creator;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // Ownable: Imitation using AccessControl
    // NOTE: OWNER_ROLEはsetOwner経由で設定する！直接設定しない！
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {
        bytes32 ownerRole = keccak256("OWNER_ROLE");
        require(getRoleMemberCount(ownerRole) > 0, "MINT: there is no owenr");

        uint256 representativeOwnerIndex = 0;
        return getRoleMember(ownerRole, representativeOwnerIndex);
    }
    function setOwner(address _newOwner) public {
        bytes32 ownerRole = keccak256("OWNER_ROLE");
        uint256 owenrCount = getRoleMemberCount(ownerRole);
        require(owenrCount == 0 || owenrCount == 1, "MINT: invalid owenr count");

        if (owenrCount == 0) {
            grantRole(ownerRole, _newOwner);
            emit OwnershipTransferred(address(0), _newOwner);
        }
        else { // owenrCount == 1
            uint256 representativeOwnerIndex = 0;
            address oldOwner = getRoleMember(ownerRole, representativeOwnerIndex);
            revokeRole(ownerRole, oldOwner);
            grantRole(ownerRole, _newOwner);
            emit OwnershipTransferred(oldOwner, _newOwner);
        }
    }

    uint256[49] private __gap;
}
