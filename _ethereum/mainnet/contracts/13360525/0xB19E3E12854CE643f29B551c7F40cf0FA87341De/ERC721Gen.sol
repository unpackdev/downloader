// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IERC721GenMint.sol";
import "./RoyaltiesV2GenImpl.sol";
import "./ERC721GenDefaultApproval.sol";
import "./ERC721GenOperatorRole.sol";
import "./HasContractURI.sol";

import "./TraitsManager.sol";

contract ERC721Gen is OwnableUpgradeable, ERC721GenDefaultApproval, HasContractURI, RoyaltiesV2GenImpl, TraitsManager, ERC721GenOperatorRole {
    using SafeMathUpgradeable for uint;
    using StringsUpgradeable for uint;

    event GenArtTotal(uint total);
    event GenArtMint(uint indexed tokenId, uint number);

    //max amount of tokens in existance
    uint public total;

    //max amount of tokens to be minted in one transaction
    uint public maxValue;

    //amount of minted tokens
    uint minted;

    function __ERC721Gen_init(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _transferProxy,
        address _operatorProxy,
        LibPart.Part[] memory _royalties,
        Trait[] memory _traits,
        uint _total,
        uint _maxValue
    ) external initializer {
        __HasContractURI_init_unchained(_baseURI);
        __RoyaltiesV2Upgradeable_init_unchained();
        __RoyaltiesV2GenImpl_init_unchained(_royalties);
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        __TraitsManager_init_unchained(_traits);
        __ERC721GenDefaultApproval_init_unchained(_transferProxy);
        __ERC721GenOperatorRole_init_unchained(_operatorProxy);
        __ERC721Gen_init_unchained(_total, _maxValue);
    }

    function __ERC721Gen_init_unchained(uint _total, uint _maxValue) internal initializer {
        maxValue = _maxValue;
        total = _total;
        emit GenArtTotal(total);
    }

    //mint "value" amount of tokens and transfer them to "to" address
    function mint(address artist, address to, uint value) onlyOperator() public {
        require(value > 0 && value <= maxValue, "incorrect value of tokens to mint");
        require(artist == owner(), "artist is not an owner");

        uint totalSupply = minted;
        require(totalSupply.add(value) <= total, "all minted");

        for (uint i = 0; i < value; i ++) {
            mintSingleToken(i, totalSupply + i, to);
        }
        minted = totalSupply.add(value);
    }

    //mint one token
    function mintSingleToken(uint seed, uint totalSupply, address to) internal {
        uint tokenId = random(seed, totalSupply, to);
        _mint(to, tokenId);
        emit GenArtMint(tokenId, totalSupply + 1);
    }

    function _emitMintEvent(address to, uint tokenId) internal virtual override {
        address _owner = owner();
        emit Transfer(address(0), _owner, tokenId);
        emit Transfer(_owner, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(contractURI, "/", tokenId.toString()));
    }

    function getTokenTraits(uint tokenId) public view returns (uint[] memory) {
        uint[] memory result = new uint[](traits.length);
        for (uint i = 0; i < traits.length; i++) {
            result[i] = getTraitValue(traits[i], getRandom(tokenId, i));
        }
        return result;
    }

    uint256[50] private __gap;
}
