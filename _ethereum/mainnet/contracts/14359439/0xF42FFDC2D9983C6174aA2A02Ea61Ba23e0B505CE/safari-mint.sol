// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./Pausable.sol";

import "./IReserve.sol";
import "./whitelist.sol";
import "./safari-erc20.sol";
import "./isafari-erc721.sol";
import "./token-metadata.sol";
import "./safari-token-meta.sol";

uint256 constant GEN0 = 0;
uint256 constant GEN1 = 1;

contract SafariMint is Ownable, Pausable {
    using SafariToken for SafariToken.Metadata;

    struct WhitelistInfo {
        uint8 origAmount;
        uint8 amountRemaining;
        uint240 cost;
    }

    // mint price
    uint256 public constant MINT_PRICE = .07 ether;
    uint256 public constant WHITELIST_MINT_PRICE = .04 ether;

    uint256 public MAX_GEN0_TOKENS = 7777;
    uint256 public MAX_GEN1_TOKENS = 6667;

    uint256 public constant GEN1_MINT_PRICE = 40000 ether;

    mapping(uint256 => SafariToken.Metadata[]) internal special;

    uint256 public MAX_MINTS_PER_TX = 10;

    // For Whitelist winners
    mapping(address => WhitelistInfo) public whiteList;

    // For lions/zebras holders
    SafariOGWhitelist ogWhitelist;

    // reference to the Reserve for staking and choosing random Poachers
    IReserve public reserve;

    // reference to $RUBY for burning on mint
    SafariErc20 public ruby;

    // reference to the rhino metadata generator
    SafariTokenMeta public rhinoMeta;

    // reference to the poacher metadata generator
    SafariTokenMeta public poacherMeta;

    // reference to the main NFT contract
    ISafariErc721 public safari_erc721;

    // is public mint enabled
    bool public publicMint;

    // is gen1 mint enabled
    bool public gen1MintEnabled;

    constructor(address _ruby, address _ogWhitelist) {
        ogWhitelist = SafariOGWhitelist(_ogWhitelist);
	ruby = SafariErc20(_ruby);
    }

    function setReserve(address _reserve) external onlyOwner {
        reserve = IReserve(_reserve);
    }

    function setRhinoMeta(address _rhino) external onlyOwner {
        rhinoMeta = SafariTokenMeta(_rhino);
    }

    function setPoacherMeta(address _poacher) external onlyOwner {
        poacherMeta = SafariTokenMeta(_poacher);
    }

    function setErc721(address _safariErc721) external onlyOwner {
        safari_erc721 = ISafariErc721(_safariErc721);
    }

    function addSpecial(bytes32[] calldata value) external onlyOwner {
        for (uint256 i=0; i<value.length; i++) {
            SafariToken.Metadata memory v = SafariToken.create(value[i]);
	    v.setSpecial(true);
            uint8 kind = v.getCharacterType();
            special[kind].push(v);
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
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintGen0(uint256 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenPublicMint {
        require(amount * MINT_PRICE == msg.value, "Invalid payment amount");

        _mintGen0(amount, boostPercent, stake);
    }

    /**
    * public mint tokens
    * @param amount the number of tokens that are being paid for
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintGen1(uint256 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenGen1Mint {
        _mintGen1(amount, boostPercent, stake);
    }

    /**
    * mint tokens using the whitelist
    * @param amount the number of tokens that are being paid for or claimed
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintWhitelist(uint8 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenWhitelistMint {
        WhitelistInfo memory wlInfo = whiteList[_msgSender()];

	require(wlInfo.origAmount > 0, "you are not on the whitelist");

	uint256 amountAtCustomPrice = min(amount, wlInfo.amountRemaining);
	uint256 amountAtWhitelistPrice = amount - amountAtCustomPrice;
	uint256 totalPrice = amountAtCustomPrice * wlInfo.cost + amountAtWhitelistPrice * WHITELIST_MINT_PRICE;

        require(totalPrice == msg.value, "wrong payment amount");

        wlInfo.amountRemaining -= uint8(amountAtCustomPrice);
        whiteList[_msgSender()] = wlInfo;

        _mintGen0(amount, boostPercent, stake);
    }

    /**
    * mint tokens using the OG Whitelist
    * @param amountPaid the number of tokens that are being paid for
    * @param amountFree the number of free tokens being claimed
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintOGWhitelist(uint256 amountPaid, uint256 amountFree, uint256 boostPercent, bool stake) external payable whenNotPaused whenWhitelistMint {
        require(amountPaid * WHITELIST_MINT_PRICE == msg.value, "wrong payment amount");

        uint16 offset;
        uint8 bought;
        uint8 claimed;
        uint8 lions;
        uint8 zebras;

	uint256 packedInfo = ogWhitelist.getInfoPacked(_msgSender());
        offset = uint16(packedInfo >> 32);
        bought = uint8(packedInfo >> 24);
        claimed = uint8(packedInfo >> 16);
        lions = uint8(packedInfo >> 8);
        zebras = uint8(packedInfo);

        uint256 totalBought = amountPaid + bought;
        uint256 totalClaimed = amountFree + claimed;

        uint256 totalCredits = freeCredits(totalBought, lions, zebras);

        require(totalClaimed <= totalCredits, 'not enough free credits');

        if (totalBought > 255) {
            totalBought = 255;
        }

        uint16 boughtAndClaimed = uint16((totalBought << 8) + totalClaimed);
        ogWhitelist.setBoughtAndClaimed(offset, boughtAndClaimed);

        uint256 amount = amountPaid + amountFree;

        _mintGen0(amount, boostPercent, stake);
    }

    /** 
    * calculate how many RUBIES are needed to increase the
    * odds of minting a Poacher or APR
    * @param boostPercent the number of zebras owned by the user
    * @return the amount of RUBY that is needed
    */
    function boostPercentToCost(uint256 boostPercent, uint256 gen) internal pure returns(uint256) {
        if (boostPercent == 0) {
	    return 0;
	}
	uint256 boostCost;

        if (gen == GEN0) {
            assembly {
	        switch boostPercent
	        case 20 {
	            boostCost := 50000
	        }
	        case 25 {
	            boostCost := 60000
	        }
	        case 30 {
	            boostCost := 100000
	        }
	        case 100 {
	            boostCost := 500000
	        }
	    }
	} else {
            assembly {
	        switch boostPercent
	        case 20 {
	            boostCost := 50000
	        }
	        case 25 {
	            boostCost := 60000
	        }
	        case 30 {
	            boostCost := 100000
	        }
	        case 100 {
	            boostCost := 1000000
	        }
	    }
	}
        require(boostCost > 0, 'Invalid boost amount');
	return boostCost * 1 ether;
    }

    function getStakedPoacherBoost() internal view returns(uint256) {
        uint256 numStakedPoachers = reserve.numDepositedPoachersOf(tx.origin);
	if (numStakedPoachers >= 5) {
	    return 15;
	} else if (numStakedPoachers >= 4) {
	    return 10;
	} else if (numStakedPoachers >= 2) {
	    return 5;
	}
	return 0;
    }

    function _mintGen0(uint256 amount, uint256 boostPercent, bool stake) internal {
        require(tx.origin == _msgSender(), "Only EOA");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        uint256 m = safari_erc721.totalSupply();
        require(m < MAX_GEN0_TOKENS, "All Gen 0 tokens minted");

        uint256 totalRubyCost = boostPercentToCost(boostPercent, GEN0) * amount;
	require(ruby.balanceOf(_msgSender()) >= totalRubyCost, 'not enough RUBY for boost');

	uint256 poacherChance = boostPercent == 0 ? 10 : boostPercent;

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 randomVal;

	address recipient = stake ? address(reserve) : _msgSender();

        for (uint i = 0; i < amount; i++) {
            m++;
            randomVal = random(m);
            tokenMetadata[i] = generate0(randomVal, poacherChance, m);
            tokenIds[i] = uint16(m);
        }

        if (totalRubyCost > 0) {
	    ruby.burn(_msgSender(), totalRubyCost);
	}

	safari_erc721.batchMint(recipient, tokenMetadata, tokenIds);

        if (stake) {
	    reserve.stakeMany(_msgSender(), tokenIds);
	}
    }

    function selectRecipient(uint256 seed, address origRecipient) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return origRecipient;
        address thief = reserve.randomPoacherOwner(seed >> 144);
        if (thief == address(0x0)) return origRecipient;
        return thief;
    }

    function _mintGen1(uint256 amount, uint256 boostPercent, bool stake) internal {
        require(tx.origin == _msgSender(), "Only EOA");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        uint256 m = safari_erc721.totalSupply();
        require(m < MAX_GEN0_TOKENS + MAX_GEN1_TOKENS, "All Gen 1 tokens minted");

        uint256 totalRubyCost = boostPercentToCost(boostPercent, GEN1) * amount;
	totalRubyCost += amount * GEN1_MINT_PRICE;
	require(ruby.balanceOf(_msgSender()) >= totalRubyCost, 'not enough RUBY owned');

	uint256 aprChance = boostPercent == 0 ? 10 : boostPercent;
	if (aprChance != 100) {
	    aprChance += getStakedPoacherBoost();
	}

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        SafariToken.Metadata[] memory singleTokenMetadata = new SafariToken.Metadata[](1);
        uint16[] memory tokenIds = new uint16[](amount);
        uint16[] memory singleTokenId = new uint16[](1);
        uint256 randomVal;

	address recipient = stake ? address(reserve) : _msgSender();
	address thief;

        for (uint i = 0; i < amount; i++) {
            m++;
            randomVal = random(m);

            singleTokenMetadata[0] = generate1(randomVal, aprChance, m);
	    if (!singleTokenMetadata[0].isAPR() && (thief = selectRecipient(randomVal, recipient)) != recipient) {
	        singleTokenId[0] = uint16(m);
	        safari_erc721.batchMint(thief, singleTokenMetadata, singleTokenId);
	    } else {
	        tokenMetadata[i] = singleTokenMetadata[0];
                tokenIds[i] = uint16(m);
	    }
        }

        if (totalRubyCost > 0) {
	    ruby.burn(_msgSender(), totalRubyCost);
	}

	safari_erc721.batchMint(recipient, tokenMetadata, tokenIds);

        if (stake) {
	    reserve.stakeMany(_msgSender(), tokenIds);
	}
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param randomVal a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate0(uint256 randomVal, uint256 poacherChance, uint256 tokenId) internal returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;

        uint8 characterType = (randomVal % 100 < poacherChance) ? POACHER : ANIMAL;

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
    * generates traits for a specific token, checking to make sure it's unique
    * @param randomVal a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate1(uint256 randomVal, uint256 aprChance, uint256 tokenId) internal returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;

        newData.setCharacterType((randomVal % 100 < aprChance) ? APR : ANIMAL);

        if (newData.isAPR()) {
	    SafariToken.Metadata[] storage specials = special[APR];
	    if (randomVal % (MAX_GEN0_TOKENS + MAX_GEN1_TOKENS - min(tokenId, MAX_GEN0_TOKENS + MAX_GEN1_TOKENS) + 1) < specials.length) {
	        newData.setSpecial(specials);
	    } else {
                newData.setAlpha(uint8(((randomVal >> 7) % (MAX_ALPHA - MIN_ALPHA + 1)) + MIN_ALPHA));
            }
        } else {
	    SafariToken.Metadata[] storage specials = special[CHEETAH];
	    if (randomVal % (MAX_GEN0_TOKENS + MAX_GEN1_TOKENS - min(tokenId, MAX_GEN0_TOKENS + MAX_GEN1_TOKENS) + 1) < specials.length) {
	        newData.setSpecial(specials);
	    } else {
	        newData.setCharacterSubtype(CHEETAH);
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

    function setPublicMint(bool allowPublicMint) external onlyOwner {
        publicMint = allowPublicMint;
    }

    function setGen1Mint(bool allowGen1Mint) external onlyOwner {
        gen1MintEnabled = allowGen1Mint;
    }

    function addToWhitelist(address[] calldata toWhitelist, uint8[] calldata amount, uint240[] calldata cost) external onlyOwner {
        require(toWhitelist.length == amount.length && toWhitelist.length == cost.length, 'all arguments were not the same length');

	WhitelistInfo storage wlInfo;
        for(uint256 i = 0; i < toWhitelist.length; i++){
            address idToWhitelist = toWhitelist[i];
	    wlInfo = whiteList[idToWhitelist];
	    wlInfo.origAmount += amount[i];
	    wlInfo.amountRemaining += amount[i];
	    wlInfo.cost = cost[i];
        }
    }

    /** 
    * calculate how many free tokens can be redeemed by a user
    * based on how many tokens the user has bought
    * @param bought the number of tokens bought
    * @param lions the number of lions owned by the user
    * @param zebras the number of zebras owned by the user
    * @return the number of free tokens that the user can claim
    */
    function freeCredits(uint256 bought, uint256 lions, uint256 zebras) internal pure returns(uint256) {
        uint256 used_lions = min(bought, lions);
        lions -= used_lions;
        bought -= used_lions;
        uint256 used_zebras = min(bought, zebras);
        return used_lions * 2 + used_zebras;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a <= b ? a : b;
    }

    modifier whenPublicMint() {
        require(publicMint == true, 'public mint is not activated');
	_;
    }

    modifier whenWhitelistMint() {
        require(publicMint == false, 'whitelist mint is over');
	_;
    }

    modifier whenGen1Mint() {
        require(gen1MintEnabled == true, 'gen1 mint is not activated');
	_;
    }
}
