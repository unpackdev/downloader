// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./Pausable.sol";

import "./IReserve.sol";
import "./safari-erc20.sol";
import "./isafari-erc721.sol";
import "./token-metadata.sol";
import "./safari-token-meta.sol";

contract SafariMintFreeGen0 is Ownable, Pausable {
    using SafariToken for SafariToken.Metadata;

    uint256 public MAX_GEN0_TOKENS = 7777;

    mapping(uint256 => SafariToken.Metadata[]) internal special;

    uint256 constant MAX_FREE_MINTS = 10;
    uint256 constant MAX_MINTS_PER_TX = 10;

    // reference to the main NFT contract
    ISafariErc721 public safari_erc721;

    // reference to the Reserve for staking and choosing random Poachers
    IReserve public reserve;

    // reference to the rhino metadata generator
    SafariTokenMeta public rhinoMeta;

    // reference to the poacher metadata generator
    SafariTokenMeta public poacherMeta;

    mapping(address => uint256) public minted;

    constructor(address _safari_erc721, address _reserve, address _rhino, address _poacher, bytes32[] memory _specials) {
        safari_erc721 = ISafariErc721(_safari_erc721);
        reserve = IReserve(_reserve);
        rhinoMeta = SafariTokenMeta(_rhino);
        poacherMeta = SafariTokenMeta(_poacher);
	_addSpecial(_specials);
    }

    function addSpecial(bytes32[] memory value) external onlyOwner {
	_addSpecial(value);
    }

    function _addSpecial(bytes32[] memory value) internal {
        for (uint256 i=0; i<value.length; i++) {
            SafariToken.Metadata memory v = SafariToken.create(value[i]);
	    v.setSpecial(true);
            uint8 kind = v.getCharacterType();
            special[kind].push(v);
	}
    }

    function clearSpecials() external onlyOwner {
	clearSpecials(ANIMAL);
        clearSpecials(POACHER);
    }

    function clearSpecials(uint256 kind) internal {
    	SafariToken.Metadata[] storage specials = special[kind];
	while (specials.length > 0) {
            specials.pop();
        }
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * public mint tokens
    * @param amount the number of tokens that are being paid for
    * @param stake stake the tokens if true
    */
    function mintGen0(uint256 amount, bool stake) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
	require(amount + minted[_msgSender()] <= MAX_FREE_MINTS, "exceeded allowed free mints");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        uint256 m = safari_erc721.totalSupply();
        require(m < MAX_GEN0_TOKENS, "All Gen 0 tokens minted");

	minted[_msgSender()] += amount;

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 randomVal;

	address recipient = stake ? address(reserve) : _msgSender();

        for (uint i = 0; i < amount; i++) {
            m++;
            randomVal = random(m);
            tokenMetadata[i] = generate0(randomVal, m);
            tokenIds[i] = uint16(m);
        }

	safari_erc721.batchMint(recipient, tokenMetadata, tokenIds);

        if (stake) {
	    reserve.stakeMany(_msgSender(), tokenIds);
	}
    }

    function mintSpecials(address to) external onlyOwner {
        mintSpecials(to, POACHER);
	mintSpecials(to, ANIMAL);
    }

    function mintSpecials(address to, uint256 kind) internal {
        uint256 m = safari_erc721.totalSupply();

	SafariToken.Metadata[] storage specials = special[kind];
	uint256 amount = specials.length;

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        uint16[] memory tokenIds = new uint16[](amount);

        for (uint i = 0; i < amount; i++) {
            m++;
            tokenMetadata[i].setSpecial(specials);
            tokenIds[i] = uint16(m);
        }
	require(specials.length == 0, 'your logic is flawed');

	safari_erc721.batchMint(to, tokenMetadata, tokenIds);
    }

    function generate0(uint256 randomVal, uint256 tokenId) internal returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;

        uint8 characterType = (randomVal % 100 < 10) ? POACHER : ANIMAL;

        if (characterType == POACHER) {
            SafariToken.Metadata[] storage specials = special[POACHER];
            if (randomVal % (MAX_GEN0_TOKENS/10 - min(tokenId, MAX_GEN0_TOKENS/10) + 1) < specials.length) {
                newData.setSpecial(specials);
            } else {
                newData = poacherMeta.generateProperties(randomVal, tokenId);
                newData.setAlpha(uint8(((randomVal >> 7) % (MAX_ALPHA - MIN_ALPHA + 1)) + MIN_ALPHA));
                newData.setCharacterType(characterType);
            }
        } else {
            SafariToken.Metadata[] storage specials = special[ANIMAL];
            if (randomVal % (MAX_GEN0_TOKENS - min(tokenId, MAX_GEN0_TOKENS) + 1) < specials.length) {
                newData.setSpecial(specials);
            } else {
                newData = rhinoMeta.generateProperties(randomVal, tokenId);
                newData.setCharacterType(characterType);
            }
        }

        return newData;
    }

    /**
    * updates the number of tokens for primary mint
    */
    function setGen0Max(uint256 _gen0Tokens) external onlyOwner {
        MAX_GEN0_TOKENS = _gen0Tokens;
    }

    /**
    * generates a pseudorandom number
    * @param seed a value ensure different outcomes for different sources in the same block
    * @return a pseudorandom value
    */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(
	  keccak256(
	    abi.encodePacked(
              blockhash(block.number - 1),
              seed
            )
	  )
	);
    }

    /** ADMIN */

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a <= b ? a : b;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

}
