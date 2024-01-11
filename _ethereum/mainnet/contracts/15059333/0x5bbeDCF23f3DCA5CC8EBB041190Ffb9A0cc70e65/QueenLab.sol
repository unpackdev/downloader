// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import "./Address.sol";
import "./Strings.sol";

import "./RoyalLibrary.sol";
import "./IQueenLab.sol";
import "./IQueenTraits.sol";
import "./IQueenE.sol";
import "./IQueenPalace.sol";
import "./QueenLabBase.sol";
import "./Base64.sol";

contract QueenLab is IQueenLab, QueenLabBase {
  /************************** vCONSTRUCTOR REGION *************************************************** */

  constructor(IQueenPalace _queenPalace) {
    //set ERC165 pattern
    //supportedInterfaces[type(IQueenLab).interfaceId] = true;
    _registerInterface(type(IQueenLab).interfaceId);

    queenPalace = _queenPalace;
    //onImplementation = true;
  }

  /**
   *IN
   *_traitsContract: Traits storage contract to use
   *OUT
   *returns: New QueenE's dna
   */
  function buildDna(uint256 _queeneId, bool isSir)
    public
    view
    override
    returns (RoyalLibrary.sDNA[] memory dna)
  {
    RoyalLibrary.sTRAIT[] memory traitsList = queenPalace
      .QueenTraits()
      .getTraits(true);

    dna = new RoyalLibrary.sDNA[](traitsList.length);

    uint256 number;
    for (uint256 idx = 0; idx < traitsList.length; idx++) {
      uint256 rarityWinner = rarityLottery(
        _queeneId,
        traitsList[idx].id,
        isSir
      );

      uint256 pseudoRandomNumber = uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            _queeneId,
            traitsList[idx].id * number,
            blockhash(block.difficulty),
            blockhash(block.timestamp)
          )
        )
      );

      //uint256 qtty = 10;
      uint256 qtty = queenPalace.QueenTraits().getArtCount(
        traitsList[idx].id,
        rarityWinner
      );

      dna[idx] = RoyalLibrary.sDNA({
        traitId: traitsList[idx].id,
        rarityId: rarityWinner,
        trace: pseudoRandomNumber % qtty
      });

      number += 256;
    }

    return dna;
  }

  /**
   *IN
   *_traitId: trait id pooling from the lottery
   *_traitsContract: Traits storage contract
   *OUT
   *winner: Winner rarity
   */
  function rarityLottery(
    uint256 _queeneId,
    uint256 _traitId,
    bool isSir
  ) private view returns (uint256) {
    RoyalLibrary.sRARITY[] memory raritiesList = queenPalace
      .QueenTraits()
      .getRarities(true, _traitId);

    uint256 pseudoRandomNumber = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          _queeneId,
          _traitId * 256,
          blockhash(block.difficulty),
          blockhash(block.timestamp)
        )
      )
    );

    if (_queeneId == 1) {
      //especial event, legendary QueenE with traits from rare to super-rare
      //garanteee legendary
      if (_traitId == 1 || _traitId % 2 == 0)
        return raritiesList[raritiesList.length - 1].id;
      else
        return
          raritiesList[(pseudoRandomNumber % 2) + (raritiesList.length - 2)].id;
    } else if (_queeneId <= 16 || isSir) {
      //first 14 QueenEs after #1 belongs to Queen's Gallery and have increasing chance of been rare
      return raritiesList[(pseudoRandomNumber % 2)].id;
    }

    uint256[] memory rarityPool = queenPalace.QueenTraits().rarityPool();

    uint256 winner = rarityPool[pseudoRandomNumber % rarityPool.length];
    return winner;
  }

  /**
   *IN
   *_dna: dna to produce blood
   *_traitsContract: Traits storage contract
   *OUT
   *returns: QueenE's blood produced from dna
   */
  function produceBlueBlood(RoyalLibrary.sDNA[] memory _dna)
    public
    view
    override
    returns (RoyalLibrary.sBLOOD[] memory blood)
  {
    require(_dna.length > 0, "Can't produce blood without dna!");
    blood = new RoyalLibrary.sBLOOD[](_dna.length);

    for (uint256 idx = 0; idx < _dna.length; idx++) {
      RoyalLibrary.sART memory _art;
      try
        queenPalace.QueenTraits().getArt(
          _dna[idx].traitId,
          _dna[idx].rarityId,
          _dna[idx].trace
        )
      returns (RoyalLibrary.sART memory result) {
        _art = result;
      } catch Error(string memory reason) {
        revert(reason);
      }

      blood[idx] = RoyalLibrary.sBLOOD({
        traitId: _dna[idx].traitId,
        rarityId: _dna[idx].rarityId,
        artName: string(_art.artName),
        artUri: string(_art.uri)
      });
    }

    return blood;
  }

  /**
   *IN
   *_queenId: id da nova queen que receberá o seed
   *_traitsContract: Traits storage contract
   *OUT
   *return: QueenE's new seed
   */
  function generateQueen(uint256 _queeneId, bool isSir)
    external
    view
    override
    returns (RoyalLibrary.sQUEEN memory)
  {
    require(_queeneId > 0, "Invalid QueenE id!");

    RoyalLibrary.sDNA[] memory _dna = buildDna(_queeneId, isSir);
    uint256 checkers;
    while (checkers < 3) {
      if (
        queenPalace.QueenE().dnaMapped(uint256(keccak256(abi.encode(_dna))))
      ) {
        _dna = buildDna(_queeneId, isSir);
        checkers++;
      } else break;
    }

    return
      RoyalLibrary.sQUEEN({
        queeneId: _queeneId,
        description: getQueenEDescriptionIdx(_queeneId, getQueenRarity(_dna)),
        finalArt: "",
        dna: _dna,
        queenesGallery: (_queeneId <= 16 || isSir) ? 1 : 0,
        sirAward: isSir ? 1 : 0
      });
  }

  /**
   *IN
   *_dna: queene dna to assert rarity
   *OUT
   *return: QueenE Rarity
   */
  function getQueenRarity(RoyalLibrary.sDNA[] memory _dna)
    public
    pure
    override
    returns (RoyalLibrary.queeneRarity finalRarity)
  {
    uint256 traitStat = 1;
    for (uint256 idx = 0; idx < _dna.length; idx++) {
      traitStat = traitStat * _dna[idx].rarityId;
    }

    if (traitStat <= 4) return RoyalLibrary.queeneRarity.COMMON;
    else if (traitStat <= 27) return RoyalLibrary.queeneRarity.RARE;
    else if (traitStat < 324) return RoyalLibrary.queeneRarity.SUPER_RARE;
    else return RoyalLibrary.queeneRarity.LEGENDARY;
  }

  /**
   *IN
   *_dna: queene dna to assert rarity
   *OUT
   *return: QueenE's rarity name
   */
  function getQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
    public
    pure
    override
    returns (string memory rarityName)
  {
    uint256 rarityId = uint256(getQueenRarity(_dna));

    if (rarityId == uint256(RoyalLibrary.queeneRarity.LEGENDARY))
      return "Legendary";
    else if (rarityId == uint256(RoyalLibrary.queeneRarity.SUPER_RARE))
      return "Super-Rare";
    else if (rarityId == uint256(RoyalLibrary.queeneRarity.RARE)) return "Rare";
    else return "Common";
  }

  /**
   *IN
   *_dna: queens dna
   *map: map rarityId to value
   *OUT
   *return: value to increment on initial bid
   */
  function getQueenRarityBidIncrement(
    RoyalLibrary.sDNA[] memory _dna,
    uint256[] calldata map
  ) external pure override returns (uint256 value) {
    for (uint256 idx = 0; idx < _dna.length; idx++) {
      value += map[_dna[idx].rarityId - 1];
    }
  }

  function getQueenEDescriptionIdx(
    uint256 _queeneId,
    RoyalLibrary.queeneRarity _rarityId
  ) private view returns (uint256) {
    uint256 pseudoRandomNumber = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          _queeneId,
          uint256(_rarityId),
          blockhash(block.difficulty),
          blockhash(block.timestamp)
        )
      )
    );
    return
      pseudoRandomNumber %
      queenPalace.QueenTraits().getDescriptionsCount(uint256(_rarityId));
  }

  function getQueenEDescription(
    uint256 _descriptionIdx,
    RoyalLibrary.sDNA[] memory _dna
  ) private view returns (string memory) {
    RoyalLibrary.queeneRarity queenRarity = getQueenRarity(_dna);
    return
      string(
        abi.encodePacked(
          getQueenRarityName(_dna),
          " portrait of Our ",
          queenPalace.QueenTraits().getDescriptionByIdx(
            uint256(queenRarity),
            _descriptionIdx
          ),
          " QueenE"
        )
      );
  }

  function getQueeneAttributes(
    RoyalLibrary.sDNA[] memory _dna,
    bool _isSir,
    bool _isQueenGallery
  ) private view returns (string memory) {
    RoyalLibrary.sBLOOD[] memory _blood = produceBlueBlood(_dna);
    string memory attribute = '"attributes": [';
    for (uint256 idx = 0; idx < _blood.length; idx++) {
      if (idx > 0)
        attribute = string(abi.encodePacked(attribute, ',{ "trait_type":"'));
      else attribute = string(abi.encodePacked(attribute, '{ "trait_type":"'));
      attribute = string(
        abi.encodePacked(
          attribute,
          queenPalace.QueenTraits().getTrait(_blood[idx].traitId).traitName
        )
      );
      attribute = string(abi.encodePacked(attribute, '", "value": "'));
      attribute = string(abi.encodePacked(attribute, _blood[idx].artName));
      attribute = string(abi.encodePacked(attribute, '"}'));
    }
    RoyalLibrary.queeneRarity _rarityId = getQueenRarity(_dna);
    if (_rarityId == RoyalLibrary.queeneRarity.COMMON) {
      attribute = string(
        abi.encodePacked(attribute, ', {"trait_type":"Rarity Level","value":1}')
      );
    } else if (_rarityId == RoyalLibrary.queeneRarity.RARE) {
      attribute = string(
        abi.encodePacked(attribute, ', {"trait_type":"Rarity Level","value":2}')
      );
    } else if (_rarityId == RoyalLibrary.queeneRarity.SUPER_RARE) {
      attribute = string(
        abi.encodePacked(attribute, ', {"trait_type":"Rarity Level","value":3}')
      );
    } else {
      attribute = string(
        abi.encodePacked(attribute, ', {"trait_type":"Rarity Level","value":4}')
      );
    }

    if (_isSir) {
      attribute = string(
        abi.encodePacked(
          attribute,
          ', {"trait_type":"Sir Award","value":"Yes"}'
        )
      );
    }

    if (_isQueenGallery) {
      attribute = string(
        abi.encodePacked(
          attribute,
          ', {"trait_type":"QueenE',
          "'s",
          ' Gallery","value":"Yes"}'
        )
      );
    }

    attribute = string(abi.encodePacked(attribute, "]"));
    return attribute;
  }

  function getTokenUriDescriptor(uint256 _queeneId, string memory _ipfsUri)
    external
    view
    returns (string memory)
  {
    RoyalLibrary.sQUEEN memory _queene = queenPalace.QueenE().getQueenE(
      _queeneId
    );

    return
      string(
        abi.encodePacked(
          '{"name":"QueenE ',
          Strings.toString(_queene.queeneId),
          '", "description":"',
          getQueenEDescription(_queene.description, _queene.dna),
          '","image": "',
          _ipfsUri,
          _queene.finalArt,
          '",',
          getQueeneAttributes(
            _queene.dna,
            _queene.sirAward == 1,
            _queene.queenesGallery == 1
          ),
          "}"
        )
      );
  }

  function constructTokenUri(
    RoyalLibrary.sQUEEN memory _queene,
    string memory _ipfsUri
  ) external view override returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"QueenE ',
                Strings.toString(_queene.queeneId),
                '", "description":"',
                getQueenEDescription(_queene.description, _queene.dna),
                '","image": "',
                _ipfsUri,
                _queene.finalArt,
                '",',
                getQueeneAttributes(
                  _queene.dna,
                  _queene.sirAward == 1,
                  _queene.queenesGallery == 1
                ),
                "}"
              )
            )
          )
        )
      );
  }
}
