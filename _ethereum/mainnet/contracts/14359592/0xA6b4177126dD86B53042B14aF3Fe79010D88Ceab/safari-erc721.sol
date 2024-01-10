// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "./UUPSUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./Strings.sol";

import "./IReserve.sol";
import "./token-metadata.sol";
import "./safari-token-meta.sol";


contract SafariErc721 is UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafariToken for SafariToken.Metadata;

    string public baseURI;

    // reference to the Reserve for staking and choosing random Poachers
    IReserve public reserve;

    SafariTokenMeta public rhinoMeta;
    SafariTokenMeta public poacherMeta;

    // contracts allowed to mint
    mapping(address => bool) public minter;

    //Keep track of data
    mapping(uint256 => SafariToken.Metadata) public tokenMetadata;

    //Data for Stats
    uint16 public numPoachers;
    uint16 public numAnimals;
    uint16 public numAPR;
    uint32 public numCaptured;

    uint32 lastMinted;

    function initialize(address _minter) public initializer {
        __ERC721Enumerable_init_unchained();
        __ERC721_init_unchained('Safari Battle', 'SBTLE');
        __Ownable_init_unchained();
	__Pausable_init_unchained();
	minter[_minter] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    function setRhinoMeta(address _rhino) external onlyOwner {
        rhinoMeta = SafariTokenMeta(_rhino);
    }

    function setPoacherMeta(address _poacher) external onlyOwner {
        poacherMeta = SafariTokenMeta(_poacher);
    }

    function setMinter(address _minter, bool enabled) external onlyOwner {
        minter[_minter] = enabled;
    }


    /** EXTERNAL READ */

    function tokensOfOwner(address tokenOwner) external view returns(uint256[] memory) {
        uint256 balance = balanceOf(tokenOwner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 i;
        for (i=0; i<balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(tokenOwner, i);
        }
        return tokenIds;
    }

    function isAnimal(uint256 tokenId) external view returns(bool) {
        checkExists(tokenId);
        return tokenMetadata[tokenId].isAnimal();
    }

    function isRhino(uint256 tokenId) external view returns(bool) {
        checkExists(tokenId);
        return tokenMetadata[tokenId].isRhino();
    }

    function isPoacher(uint256 tokenId) external view returns(bool) {
        checkExists(tokenId);
        return tokenMetadata[tokenId].isPoacher();
    }

    function tokenAlpha(uint256 tokenId) external view returns(uint8) {
        checkExists(tokenId);
        return tokenMetadata[tokenId].getAlpha();
    }

    function getTokenData(uint256 tokenId) external view returns (uint8,uint8,uint8,bool,bytes29) {
        checkExists(tokenId);
        SafariToken.Metadata memory meta = tokenMetadata[tokenId];
	return (meta.getCharacterType(), meta.getCharacterSubtype(), meta.getAlpha(), meta.isSpecial(), meta.getReserved());
    }

    function getTokenRaw(uint256 tokenId) external view returns(bytes32) {
        checkExists(tokenId);
        SafariToken.Metadata memory meta = tokenMetadata[tokenId];
        return meta.getRaw();
    }

    function isStaked(uint256 tokenId) external view returns(bool) {
        checkExists(tokenId);
        return ownerOf(tokenId) == address(reserve);
    }

    function getStats() external view returns(uint256, uint256, uint256, uint256){
        return(numPoachers, numAnimals, numAPR, numCaptured);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        checkExists(tokenId);

        SafariToken.Metadata memory meta = tokenMetadata[tokenId];
	if (meta.isRhino()) {
            return rhinoMeta.getMeta(meta, tokenId, baseURI);
        } else if (meta.isPoacher()) {
            return poacherMeta.getMeta(meta, tokenId, baseURI);
        }
    }

    /** EXTERNAL WRITE */

    function batchMint(address recipient, SafariToken.Metadata[] memory _tokenMetadata, uint16[] memory tokenIds) external {
        require(_tokenMetadata.length == tokenIds.length, 'invalid arguments');
        require(minter[_msgSender()], 'not the minter');

        for (uint256 i=0; i<tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            SafariToken.Metadata memory meta = _tokenMetadata[i];
            if (meta.isPoacher()) {
                numPoachers++;
            } else if (meta.isAnimal()) {
                numAnimals++;
            } else if (meta.isAPR()) {
                numAPR++;
            }
            tokenMetadata[tokenIds[i]] = meta;
            _mint(recipient, tokenIds[i]);
	}
    }

    function batchStake(address from, uint16[] calldata tokenIds) external {
        require(_msgSender() == address(reserve), 'must be the reserve');
	for (uint256 i=0; i<tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }
            require(from == ownerOf(tokenIds[i]), "not the token owner");
            _transfer(from, address(reserve), tokenIds[i]);
	}
    }

    /** INTERNAL */

   /*
    * called after deployment so that the contract can get random Poachers
    * @param _reserve the address of the Reserve
    */
    function setReserve(address _reserve) external onlyOwner {
        reserve = IReserve(_reserve);
    }

    function setBaseUri(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function checkExists(uint256 tokenId) internal view {
        require(
            _exists(tokenId),
            "token does not exist"
        );
    }
}

