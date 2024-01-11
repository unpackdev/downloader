// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Base.sol";
import "./IAllowlist.sol";

import "./console.sol";

/**
 * @dev
 */
contract Allowlist is
    IAllowlist,
    Base {

    constructor() {}

    IAllowlist.Allowlist[] public allowlists;

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Base) returns (bool) {
        return interfaceId == type(IAllowlist).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev see {IAllowlist-createAllowlist}
    */
    function createAllowlist(IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        // typedata should be an address if Allowlist.Type is set to ERC721 or ERC1155
        if (_allowlist.type_ == IAllowlist.Type.ERC721 || _allowlist.type_ == IAllowlist.Type.ERC1155)
            _revertOnInvalidTypeAddress(_allowlist.type_, _allowlist.typedata);
        allowlists.push(_allowlist);
        emit AllowlistCreated(allowlists.length - 1);
    }

    /**
    * @dev see {IAllowlist-updateAllowlist}
    */
    function updateAllowlist(uint256 _allowlistId, IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        _revertOnAllowlistNotExists(_allowlistId);
        allowlists[_allowlistId] = _allowlist;
        emit AllowlistUpdated(_allowlistId);
    }

    /**
    * @dev see {IAllowlist-getAllowlist}
    */
    function getAllowlist(uint256 _allowlistId) external view returns (IAllowlist.Allowlist memory) {
        _revertOnAllowlistNotExists(_allowlistId);
        return allowlists[_allowlistId];
    }

    /**
    * @dev see {IAllowlist-getAllowlists}
    */
    function getAllowlists() external view returns (IAllowlist.Allowlist[] memory) {
        return allowlists;
    }

    /**
    * @dev see {IAllowlist-isAllowed}
    */
    function isAllowed(address _address, bytes32[][] calldata _proofs) public virtual view returns (bool) {
        return isAllowedAtLeast(_address, _proofs, 1);
    }

    /**
    * @dev see {IAllowlist-isAllowedArbitrary} | @bitcoinski
    */
    function isAllowedArbitrary(address _address, bytes32[] calldata _proof, IAllowlist.Allowlist memory _allowlist, uint256 _quantity) public virtual view returns (bool) {
        return _allowedArbitrary(_address, _proof, _allowlist, _quantity);
    }

    /**
    * @dev see {IAllowlist-isAllowedAll}
    */
    function isAllowedAll(address _address, bytes32[][] calldata _proofs) public virtual view returns (bool) {
        return isAllowedAtLeast(_address, _proofs, allowlists.length);
    }

    /**
    * @dev see {IAllowlist-isAllowedAtLeast}
    */
    function isAllowedAtLeast(address _address, bytes32[][] calldata _proofs, uint256 _quantity) public virtual view returns (bool) {
        // there are no allowlists so there's nothing to check
        if (allowlists.length == 0 || _quantity == 0) {
            return true;
        }

        // iterate over all existing allowlists and keep track of how many _address is on
        unchecked {
            uint256 allowed = 0;
            for (uint i = 0; i < allowlists.length; i++) {
                if (!allowlists[i].isActive) {
                    // inactive allowlists shouldn't be checked against so we treat them as allowed
                    //TODO: @bitcoinski if we deactivate an allowlist, then would any address automatically get +1 allocation here?
                    allowed++;
                }
                /*
                else if(allowlists[i].hasArbitraryAllocation){
                     if (_allowedArbitrary(_address, _proofs, allowlists[i], _quantity)) allowed++;
                }
                */
                else {
                    if (_allowed(_address, _proofs, allowlists[i])) allowed++;
                }

                // exit now if quantity has been satisfied
                if (allowed >= _quantity) return true;
            }
        }
        return false;
    }

    /**
    * @dev see {IAllowlist-isAllowedOn}
    */
    function isAllowedOn(uint256 _allowlistId, address _address, bytes32[][] calldata _proofs) public virtual view returns (bool) {
        return _allowed(_address, _proofs, allowlists[_allowlistId]);
    }

    /**
    * @dev verifies whether or not _address is on an individual list
    */
    function _allowed(address _address, bytes32[][] calldata _proofs, IAllowlist.Allowlist memory _allowlist) private view returns (bool) {
        if (_allowlist.type_ == IAllowlist.Type.Merkle) {
            // is _address on a list with the root stored in allowlists[].typedata?
            unchecked {
                uint256 allowed = 0;
                for (uint j = 0; j < _proofs.length; j++) {
                    if (MerkleProof.verify(_proofs[j], _allowlist.typedata, keccak256(abi.encodePacked(_address)))) allowed++;
                }
                if (allowed > 0) return true;
            }
        } else if (_allowlist.type_ == IAllowlist.Type.ERC721) {
            // is _address a holder of the ERC721 token stored in allowlists[].typedata?
            if (IERC721(_bytes32ToAddress(_allowlist.typedata)).balanceOf(_address) > 0) return true;
        } else if (_allowlist.type_ == IAllowlist.Type.ERC1155) {
            // is _address a holder of the ERC1155 token stored in allowlists[].typedata?
            unchecked {
                uint256 allowed = 0;
                for (uint j = 0; j < _allowlist.tokenTypeIds.length; j++) {
                    if (IERC1155(_bytes32ToAddress(_allowlist.typedata)).balanceOf(_address, _allowlist.tokenTypeIds[j]) > 0) allowed++;
                }
                if (allowed > 0) return true;
            }
        } else {
            // this condition should never be reached unless an Allowlist.Type has not been fully implemented
            return false;
        }
        return false;
    }

    /**
    * @dev verifies whether or not _address is on an individual list with a stated arbitrary allocation | @bitcoinski
    */
    function _allowedArbitrary(address _address, bytes32[] calldata _proof, IAllowlist.Allowlist memory _allowlist, uint256 _quantity) private view returns (bool) {
        // Public Sale List
        if(_allowlist.typedata == 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45 || _allowlist.typedata == '0x' || _allowlist.typedata == 0x0000000000000000000000000000000000000000000000000000000000000000) return true;
        string memory leaf = makeLeaf(_address, _quantity);
        bytes32 node = keccak256(abi.encode(leaf));
        if (MerkleProof.verify(_proof, _allowlist.typedata, node)) return true;
        return false;
    }

     function makeLeaf(address _addr, uint amount) public view returns (string memory) {
        return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
    }

     function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
    * @dev convert bytes32 value to address
    */
    function _bytes32ToAddress(bytes32 _bytes32) private pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }

    /**
    * @dev revert transaction if the typedata address isn't a ERC721 or ERC1155 contract
    */
    function _revertOnInvalidTypeAddress(IAllowlist.Type _type, bytes32 _typedata) private view {
        if (_type == IAllowlist.Type.ERC721) {
            if (!IERC721(_bytes32ToAddress(_typedata)).supportsInterface(type(IERC721).interfaceId))
                revert TypeAddressInvalid(_typedata);
        } else if (_type == IAllowlist.Type.ERC1155) {
            if (!IERC1155(_bytes32ToAddress(_typedata)).supportsInterface(type(IERC1155).interfaceId))
                revert TypeAddressInvalid(_typedata);
        }
    }

    /**
    * @dev revert transaction if the allowlist does not exist
    */
    function _revertOnAllowlistNotExists(uint256 _allowlistId) internal virtual view {
        if(allowlists.length == 0) revert AllowlistNotFound();
        if(!(allowlists.length > _allowlistId)) revert AllowlistNotFound();
    }

}
