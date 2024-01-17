// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: Grids
// @artist: Kaleb Johnston
// @author: @curatedxyz

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//       _|_|_|  _|_|_|    _|_|_|  _|_|_|      _|_|_|      //
//     _|        _|    _|    _|    _|    _|  _|            //
//     _|  _|_|  _|_|_|      _|    _|    _|    _|_|        //
//     _|    _|  _|    _|    _|    _|    _|        _|      //
//       _|_|_|  _|    _|  _|_|_|  _|_|_|    _|_|_|        //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////

// With smart contract inspiration from ArtBlocks, 0xDeafbeef, and Manifold.
// Thank you to @yungwknd for contract review.
// Please call termsOfUseURI() to get the most updated link to the Terms of Use for the Grids collection.

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./IERC721Upgradeable.sol";

contract Grids is AdminControl, ICreatorExtensionTokenURI {
    
    using Strings for uint;
    mapping(uint => bytes32) public tokenIdToHash;
    mapping(uint => string) public scripts;

    string private baseURI;
    string public termsOfUseURI;
    string public contractMetadataURI;
    address private _creator;
    uint public invocations;
    uint public maxInvocations;
    uint public scriptCount;

    function configure(address creator) public adminRequired {
      _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mintBatch(address _to, uint quantity) public adminRequired returns(uint256[] memory tokenIds) {        
        require(invocations + quantity  <= maxInvocations, "Can't mint beyond max invocations");
        require(maxInvocations > 0, "Max invocations needs to be set");

        for (uint i; i < quantity; i++) {
          invocations += 1;
          bytes32 tokenHash = keccak256(abi.encodePacked(invocations, block.number, blockhash(block.number - 1), block.difficulty, msg.sender));

          tokenIdToHash[invocations] = tokenHash;
        }

        return IERC721CreatorCore(_creator).mintExtensionBatch(_to, uint16(quantity));
    }

    function setBaseURI(string memory _baseURI)public adminRequired {
        baseURI = _baseURI;
    }

    function tokenURI(address creator, uint256 tokenId) public view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        require(tokenId <= invocations, "Token does not exist yet");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function addProjectScript (string memory _script) public adminRequired {
        scripts[scriptCount] = _script;
        scriptCount += 1;
    }

    function updateProjectScript (uint256 _scriptId, string memory _script) public adminRequired {
        require(_scriptId <= scriptCount, "ScriptId does not exist, please use addProjectScript");
        scripts[_scriptId] = _script;
    }

    function setTermsOfUse (string memory _termsOfUseURI) public adminRequired {
        termsOfUseURI = _termsOfUseURI;
    }

    function setMaxInvocations (uint _maxInvocations) public adminRequired {
        require(maxInvocations >= invocations, "Max invocations cannot be less than the current count");
        maxInvocations = _maxInvocations;
    }

    function setContractURI(string memory _contractURI) public adminRequired {
        contractMetadataURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }
}