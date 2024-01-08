//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./IMetaDataGenerator.sol";
import "./ICryptoPiggies.sol";

/**
 * @dev Implementation of the Non-Fungible Token CryptoPiggies which uses a MetaDataGenerator to generate MetaData fully on-chain
 * Each piggy stores some eth, which can be redeemed by breaking the piggie, so there is a hard floor for sellers.
 */

contract CryptoPiggies is ERC721, ICryptoPiggies {
    address payable public override treasury;
    IMetaDataGenerator public immutable override METADATAGENERATOR;

    mapping(uint256 => Piggy) piggies;

    uint256 public constant MINT_MASK = 0xfffff;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MINT_VALUE = MINT_PRICE / 2;
    uint256 public constant FLIP_MIN_COST = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT = 20;

    uint256 internal _supply = 0;
    uint256 internal _broken = 0;

    constructor(address payable treasury_, IMetaDataGenerator generator)
        ERC721('CryptoPiggies', 'CPig')
    {
        treasury = treasury_;
        METADATAGENERATOR = generator;
    }

    function setTreasury(address payable treasury_) public {
        require(treasury == msg.sender, 'caller not treasury');
        treasury = treasury_;
    }

    /**
     * @dev Mints CryptoPiggies to the msg.sender when receiving ETH directly.
     *      Computes the number of CryptoPiggies from the msg.value
     */
    receive() external payable override {
        uint256 piggiesToMint = msg.value / MINT_PRICE;
        giftPiggies(piggiesToMint > MAX_MINT ? MAX_MINT : piggiesToMint, msg.sender);
    }

    /**
     * @dev Mints CryptoPiggies to the msg.sender
     * @param piggiesToMint the amount of CryptoPiggies to mint
     */
    function mintPiggies(uint256 piggiesToMint) public payable override {
        giftPiggies(piggiesToMint, msg.sender);
    }

    /**
     * @dev Minting CryptoPiggies to another account than msg.sender
     * @param piggiesToMint the amount of CryptoPiggies to mint
     * @param to the address to receive those CryptoPiggies
     */
    function giftPiggies(uint256 piggiesToMint, address to) public payable override {
        uint256 supply = _supply;
        require(piggiesToMint > 0, 'cannot mint 0 piggies');
        require(piggiesToMint <= MAX_MINT, 'exceeds max mint');
        require(supply + piggiesToMint <= MAX_SUPPLY, 'exceeds max supply');
        require(msg.value >= MINT_PRICE * piggiesToMint, 'insufficient eth');
        _supply = _supply + piggiesToMint;
        for (uint256 i = 0; i < piggiesToMint; i++) {
            _mintPiggie(to, supply + i);
        }
        treasury.transfer(MINT_VALUE * piggiesToMint);
        uint256 refundAmount = msg.value - piggiesToMint * MINT_PRICE;
        payable(msg.sender).transfer(refundAmount);
    }

    /**
     * @dev Destroy CryptoPiggies to redeem the ETH they hold
     * @param tokenIds the CryptoPiggies to destroy
     * @param to the receiver of the funds
     */
    function breakPiggies(uint256[] memory tokenIds, address payable to) external override {
        uint256 fundsInBroken = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            fundsInBroken += _breakPiggie(tokenId);
        }
        _broken += tokenIds.length;
        to.transfer(fundsInBroken);

        emit Break(tokenIds.length, fundsInBroken, to);
    }

    /**
     * @dev Resets the trait mask to the initial mask
     * @param tokenId the CryptoPiggy to reset
     */
    function resetTraitMask(uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        piggies[tokenId].traitMask = MINT_MASK;
        piggies[tokenId].flipCost = FLIP_MIN_COST;
        emit ResetMask(tokenId);
    }

    /**
     * @dev Update multiple traits at once
     * @param tokenId the CryptoPiggy to update traits on
     * @param positions the traits to flip
     * @param onOffs whether to turn the trait on or off
     */
    function updateMultipleTraits(
        uint256 tokenId,
        uint256[] memory positions,
        bool[] memory onOffs
    ) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        require(positions.length == onOffs.length, 'length mismatch');
        uint256 costOfFlipping = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            costOfFlipping += piggies[tokenId].flipCost * (2**i);
        }
        require(msg.value >= costOfFlipping, 'insufficient eth');

        Piggy memory piggie = piggies[tokenId];
        for (uint256 i = 0; i < positions.length; i++) {
            require(positions[i] > 4, 'cannot flip piggy or colors');
            if (onOffs[i]) {
                piggie.traitMask = newMask(piggie.traitMask, 15, positions[i]);
                emit TurnTraitOn(tokenId, positions[i]);
            } else {
                piggie.traitMask = newMask(piggie.traitMask, 0, positions[i]);
                emit TurnTraitOff(tokenId, positions[i]);
            }
        }

        piggie.flipCost = piggie.flipCost * (2 * (positions.length));
        piggie.balance += msg.value / 2;
        piggies[tokenId] = piggie;

        treasury.transfer(msg.value / 2);
    }

    /**
     * @dev Turn on a nibble (4 bits) in the trait mask.
     * @param tokenId the CryptoPiggy to update mask for
     * @param position nibble index from the right to flip
     */
    function turnTraitOn(uint256 tokenId, uint256 position) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        _updateTraitMask(tokenId, 15, position);
        emit TurnTraitOn(tokenId, position);
    }

    /**
     * @dev Turn off a nibble (4 bits) in the trait mask.
     * @param tokenId the CryptoPiggy to update mask for
     * @param position nibble index from the right to flip
     */
    function turnTraitOff(uint256 tokenId, uint256 position) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        _updateTraitMask(tokenId, 0, position);
        emit TurnTraitOff(tokenId, position);
    }

    /**
     * @dev Donates ETH from msg.value directly to a CryptoPiggy
     * @param tokenId the CryptoPiggy to donate to
     */

    function deposit(uint256 tokenId) public payable override {
        require(_exists(tokenId), 'cannot deposit to non-existing piggy');
        piggies[tokenId].balance += msg.value;
        emit Deposit(tokenId, msg.value);
    }

    /**
     * @dev Generates SVG image for CryptoPiggy with the activeGene and balance
     * @param tokenId the CryptoPiggy to generate image for
     * @return SVG contents
     */
    function getSVG(uint256 tokenId) public view override returns (string memory) {
        return METADATAGENERATOR.getSVG(activeGeneOf(tokenId), piggyBalance(tokenId));
    }

    /**
     * @dev Generates MetaData for a specific CryptoPiggy using its activeGene and balance
     * @param tokenId the CryptoPiggy to generate metadata for
     * @return Base64 encoded MetaData for the CryptoPiggy
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IMetaDataGenerator.MetaDataParams memory params = IMetaDataGenerator.MetaDataParams(
            tokenId,
            activeGeneOf(tokenId),
            piggyBalance(tokenId),
            ownerOf(tokenId)
        );
        return METADATAGENERATOR.tokenURI(params);
    }

    function totalSupply() external view returns (uint256) {
        return _supply;
    }

    function broken() external view override returns (uint256) {
        return _broken;
    }

    function geneOf(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].gene;
    }

    function traitMaskOf(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].traitMask;
    }

    function activeGeneOf(uint256 tokenId) public view override returns (uint256) {
        return piggies[tokenId].gene & piggies[tokenId].traitMask;
    }

    function piggyBalance(uint256 tokenId) public view override returns (uint256) {
        return piggies[tokenId].balance;
    }

    function flipCost(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].flipCost;
    }

    function getPiggy(uint256 tokenId) external view override returns (Piggy memory) {
        return piggies[tokenId];
    }

    // Internal functions

    function _mintPiggie(address to, uint256 tokenId) internal {
        // Semi gameable gene
        uint256 gene = uint256(
            keccak256(
                abi.encode(
                    blockhash(block.number),
                    // blockhash(block.number - 50), // This is why coverage is fuckeds
                    gasleft(),
                    msg.sender,
                    to,
                    tokenId,
                    _supply,
                    _broken
                )
            )
        );
        piggies[tokenId] = Piggy(gene, MINT_MASK, MINT_VALUE, FLIP_MIN_COST);
        _mint(to, tokenId);
    }

    function _breakPiggie(uint256 tokenId) internal returns (uint256 balance) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'caller is not approved nor owner');
        balance = piggies[tokenId].balance;
        delete piggies[tokenId];
        _burn(tokenId);
    }

    function _updateTraitMask(
        uint256 tokenId,
        uint256 replaceValue,
        uint256 position
    ) internal {
        require(position > 4, 'cannot flip piggy or colors');
        Piggy memory piggie = piggies[tokenId];
        require(msg.value >= piggie.flipCost, 'insufficient eth');
        piggie.traitMask = newMask(piggie.traitMask, replaceValue, position);
        piggie.flipCost += piggie.flipCost;
        piggie.balance += msg.value / 2;
        piggies[tokenId] = piggie;

        treasury.transfer(msg.value / 2);
    }

    function newMask(
        uint256 mask,
        uint256 replacement,
        uint256 position
    ) internal pure virtual returns (uint256) {
        uint256 rhs = position > 0 ? mask % 16**position : 0;
        uint256 lhs = (mask / (16**(position + 1))) * (16**(position + 1));
        uint256 insert = replacement * 16**position;
        return lhs + insert + rhs;
    }
}
