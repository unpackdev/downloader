// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./AccessControl.sol";
import "./IERC1155.sol";

interface IRainiNft1155 is IERC1155 {
    struct CardLevel {
        uint64 conversionRate; // number of base tokens required to create
        uint32 numberMinted;
        uint128 tokenId; // ID of token if grouped, 0 if not
        uint32 maxStamina; // The initial and maxiumum stamina for a token
    }

    struct TokenVars {
        uint128 cardId;
        uint32 level;
        uint32 number; // to assign a numbering to NFTs
        bytes1 mintedContractChar;
    }

    function cardLevels(uint256, uint256)
        external
        view
        returns (CardLevel memory);

    function tokenVars(uint256) external view returns (TokenVars memory);
}

contract StaminaPool is AccessControl {

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    uint256 public constant STAMINA_DECIMALS = 1000;

    // contract => tokenId => stamina
    mapping(address => mapping(uint256 => uint32)) public nftStamina;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EDITOR_ROLE, _msgSender());
    }

    modifier onlyEditor() {
        require(
            hasRole(EDITOR_ROLE, _msgSender()),
            "SP: caller is not a editor"
        );
        _;
    }

    function getTokenStaminaTotal(uint256 _tokenId, address _nftContractAddress)
        public
        view
        returns (uint32 stamina)
    {
        return nftStamina[_nftContractAddress][_tokenId];
    }

    function getTokenStamina(uint256 _tokenId, address _nftContractAddress)
        external
        view
        returns (uint256 _stamina)
    {
        uint256 stamina = getTokenStaminaTotal(_tokenId, _nftContractAddress);
        if (stamina == 0) {
            IRainiNft1155 tokenContract = IRainiNft1155(_nftContractAddress);
            IRainiNft1155.TokenVars memory _tv = tokenContract.tokenVars(
                _tokenId
            );
            IRainiNft1155.CardLevel memory _cl = tokenContract.cardLevels(
                _tv.cardId,
                _tv.level
            );
            return _cl.maxStamina;
        }
        return stamina / STAMINA_DECIMALS;
    }

    function setTokenStaminaTotal(
        uint32 _stamina,
        uint256 _tokenId,
        address _nftContractAddress
    ) public onlyEditor {
        nftStamina[_nftContractAddress][_tokenId] = _stamina;
    }

    function mergeTokens(
        uint256 _newTokenId,
        uint256[] memory _tokenIds,
        address _nftContractAddress
    ) external onlyEditor {
        IRainiNft1155 tokenContract = IRainiNft1155(_nftContractAddress);
        IRainiNft1155.TokenVars memory _tv;
        IRainiNft1155.CardLevel memory _cl1;
        IRainiNft1155.CardLevel memory _cl2;
        uint256 _cardId = 0;
        uint256 _stamina = 0;
        uint256 _conversionRateSum = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tv = tokenContract.tokenVars(_tokenIds[i]);
            if (_cardId == 0) {
                _cardId = _tv.cardId;
                _cl1 = tokenContract.cardLevels(_cardId, 1);
                _cl2 = tokenContract.cardLevels(_cardId, 2);
            }

            if (_tv.level == 1) {
                uint256 _tokenStamina = getTokenStaminaTotal(
                    _tokenIds[i],
                    _nftContractAddress
                );
                if (_tokenStamina > 0) {
                    _stamina += getTokenStaminaTotal(
                        _tokenIds[i],
                        _nftContractAddress
                    );
                    _conversionRateSum += _cl1.conversionRate;
                }
            }
        }
        _stamina =
            (_cl2.maxStamina *
                (_stamina *
                    _cl1.conversionRate +
                    (_cl2.conversionRate - _conversionRateSum) *
                    _cl1.maxStamina *
                    STAMINA_DECIMALS)) /
            (_cl1.maxStamina * _cl2.conversionRate);

        nftStamina[_nftContractAddress][_newTokenId] = uint32(_stamina);
    }
}