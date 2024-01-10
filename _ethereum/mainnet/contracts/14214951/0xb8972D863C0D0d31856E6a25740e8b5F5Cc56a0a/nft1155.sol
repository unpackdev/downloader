// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract NFT1155 is ERC1155, Ownable, AccessControl, ERC1155Burnable {
    /* Variable */
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public name = "CrazySquirrelMan";
    address public creatorAddress = address(0);

    /* Constructor */
    constructor() ERC1155("https://api.crazysquirrelman.com:8110/contract/item/") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }


    function uri(uint256 _id) public override view returns (string memory) {
        string memory id = uint2str(_id);
        string memory baseURI = super.uri(_id);
        return string(abi.encodePacked(baseURI, id));
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyRole(MINTER_ROLE)
    {
        if (creatorAddress != address(0)) {
            _mint(account, id, amount, abi.encode(creatorAddress));
        } else {
            _mint(account, id, amount, data);
        }
    }

    function airdrop(uint160[] memory to, uint256[] memory ids, bytes memory data)
    public
    onlyRole(MINTER_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            address ss = address(to[i]);
            if (creatorAddress != address(0)) {
                _mint(ss, ids[i], 1, abi.encode(creatorAddress));
            } else {
                _mint(ss, ids[i], 1, data);
            }
        }
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyRole(MINTER_ROLE)
    {
        if (creatorAddress != address(0)) {
            _mintBatch(to, ids, amounts, abi.encode(creatorAddress));
        } else {
            _mintBatch(to, ids, amounts, data);
        }
    }

    function setCreatorAddress(address _creatorAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        creatorAddress = _creatorAddress;
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
