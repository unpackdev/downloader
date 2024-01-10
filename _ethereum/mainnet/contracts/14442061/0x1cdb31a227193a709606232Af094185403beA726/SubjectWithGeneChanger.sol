// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./SubjectGeneGenerator.sol";
import "./Subject.sol";
import "./ISubjectWithGeneChanger.sol";

abstract contract SubjectWithGeneChanger is
    ISubjectWithGeneChanger,
    Subject
{
    using SubjectGeneGenerator for SubjectGeneGenerator.Gene;
    using SafeMath for uint256;
    using Address for address;

    mapping(uint256 => uint256) internal _genomeChanges;
    mapping(uint256 => bool) public isNotVirgin;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _maxSupply,
        string memory _arweaveAssetsJSON
    )
        Subject(
            name,
            symbol,
            baseURI,
            _daoAddress,
            _maxSupply,
            _arweaveAssetsJSON
        )
    {
    }

    function _morphGene(uint256 tokenId, uint256 genePosition, uint256 price)
        internal
        nonReentrant
    {
        require(_bossTokens[tokenId] == 0, "Boss character not morphable");
        require(genePosition > 0, "Base character not morphable");
        require(genePosition < 7 || genePosition > 11 , "Rare traits not morphable");
        _beforeGenomeChange(tokenId);

        (bool transferToDaoStatus, ) = daoAddress.call{value: price}("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(price);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        uint256 oldGene = _genes[tokenId];
        uint256 newTrait = geneGenerator.random() % 100;

        // if we scramble base genes (there are no rare characters and backgrounds)
        if (genePosition > 1 && genePosition < 7) {
            // 1. Chance of rare genome change for each trait
            if ((geneGenerator.random() % 100) + 1 <= _rareTraitsChances[genePosition]) {
                // if we're lucky
                // 2. Correct gene position for rare genes
                _genes[tokenId] = replaceGene(oldGene, newTrait, genePosition + 5);
            } else {
                // otherwise just regular gene morphing
                _genes[tokenId] = replaceGene(oldGene, newTrait, genePosition);
                // Clean up rare trait
                _genes[tokenId] = replaceGene(_genes[tokenId], 0, genePosition + 5);
            }
        } else {
            // leaving room for scrambling rest of the genome in future (where genePosition is > 11)
            _genes[tokenId] = replaceGene(oldGene, newTrait, genePosition);
        }

        _genomeChanges[tokenId]++;
        isNotVirgin[tokenId] = true;
        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            price,
            SubjectEventType.MORPH
        );
    }

    function replaceGene(
        uint256 genome,
        uint256 replacement,
        uint256 genePosition
    ) internal pure virtual returns (uint256 newGene) {
        require(genePosition < 38, "Bad gene position");
        uint256 mod = 0;
        if (genePosition > 0) {
            mod = genome.mod(10**(genePosition * 2)); // Each gene is 2 digits long
        }
        uint256 div = genome.div(10**((genePosition + 1) * 2)).mul(
            10**((genePosition + 1) * 2)
        );
        uint256 insert = replacement * (10**(genePosition * 2));
        newGene = div.add(insert).add(mod);
        return newGene;
    }

    function _randomizeGenome(uint256 tokenId, uint256 randomizeGenomePrice)
        internal
        nonReentrant
    {
        require(_bossTokens[tokenId] == 0, "Boss character not morphable");
        _beforeGenomeChange(tokenId);

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: randomizeGenomePrice
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(randomizeGenomePrice);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        uint256 oldGene = _genes[tokenId];
        _genes[tokenId] = setUpRareTraitsInGenome(geneGenerator.random());
        _genomeChanges[tokenId] = 0;
        isNotVirgin[tokenId] = true;
        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            randomizeGenomePrice,
            SubjectEventType.MORPH
        );
    }

    function setUpRareTraitsInGenome(uint256 genome)
        internal
        returns (uint256)
    {
        for (uint256 genePosition = 2; genePosition < 7; genePosition++) {
            // 0. Clean up genome first
            genome = replaceGene(genome, 0, genePosition + 5);
            // 1. Chance of rare genome change for each trait
            // 1.1. There are no rare characters and backgrounds
            if (genePosition > 1 && (geneGenerator.random() % 100) + 1 <= _rareTraitsChances[genePosition]) {
                // 2. Correct gene position for rare genes
                genome = replaceGene(genome, geneGenerator.random() % 100, genePosition + 5);
            }
        }

        return genome;
    }

    function genomeChanges(uint256 tokenId)
        public
        view
        override
        returns (uint256 genomeChnages)
    {
        return _genomeChanges[tokenId];
    }

    function _beforeGenomeChange(uint256 tokenId) internal view {
        require(
            !address(_msgSender()).isContract(),
            "Caller cannot be a contract"
        );
        require(
            _msgSender() == tx.origin,
            "Msg sender should be original caller"
        );

        beforeTransfer(tokenId, _msgSender());
    }

    function beforeTransfer(uint256 tokenId, address owner) internal view {
        require(
            ownerOf(tokenId) == owner,
            "SubjectWithGeneChanger: cannot change genome of token that is not own"
        );
    }

}
