// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

interface INftStakingPool {
    function getTokenStamina(uint256 _tokenId, address _nftContractAddress)
        external
        view
        returns (uint256 stamina);

    function mergeTokens(
        uint256 _newTokenId,
        uint256[] memory _tokenIds,
        address _nftContractAddress
    ) external;
}


interface IRainiNft1155 is IERC1155 {
    struct CardLevel {
        uint64 conversionRate; // number of base tokens required to create
        uint32 numberMinted;
        uint128 tokenId; // ID of token if grouped, 0 if not
        uint32 maxStamina; // The initial and maxiumum stamina for a token
    }

    struct Card {
        uint64 costInUnicorns;
        uint64 costInRainbows;
        uint16 maxMintsPerAddress;
        uint32 maxSupply; // number of base tokens mintable
        uint32 allocation; // number of base tokens mintable with points on this contract
        uint32 mintTimeStart; // the timestamp from which the card can be minted
        string pathUri;
    }

    struct TokenVars {
        uint128 cardId;
        uint32 level;
        uint32 number; // to assign a numbering to NFTs
        bytes1 mintedContractChar;
    }

    function maxTokenId() external view returns (uint256);

    function contractChar() external view returns (bytes1);

    function burn(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external;

    function cardLevels(uint256 _cardId, uint256 _level)
        external
        view
        returns (CardLevel memory);

    function tokenVars(uint256 _tokenId)
        external
        view
        returns (TokenVars memory);

    function mint(
        address _to,
        uint256 _cardId,
        uint256 _cardLevel,
        uint256 _amount,
        bytes1 _mintedContractChar,
        uint256 _number
    ) external;
}

contract RainiNft1155v1Merge is AccessControl, ReentrancyGuard {
    address public nftStakingPoolAddress;

    uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

    mapping(uint256 => uint256) public mergeFees;



    IRainiNft1155 public nftContract;

    constructor(address _nftContractAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        nftContract = IRainiNft1155(_nftContractAddress);
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    function setFees(
        uint256[] memory _mergeFees
    ) external onlyOwner {
        for (uint256 i = 1; i < _mergeFees.length; i++) {
            mergeFees[i] = _mergeFees[i];
        }
    }

    function setNftStakingPoolAddress(address _nftStakingPoolAddress)
        external
        onlyOwner
    {
        nftStakingPoolAddress = (_nftStakingPoolAddress);
    }

    struct MergeData {
        uint256 cost;
        uint256 totalPointsBurned;
        uint256 currentTokenToMint;
        bool willCallPool;
    }

    function merge(
        uint256 _cardId,
        uint256 _level,
        uint256 _mintAmount,
        uint256[] memory _tokenIds,
        uint256[] memory _burnAmounts
    ) external payable nonReentrant {
        IRainiNft1155.CardLevel memory _cardLevel = nftContract.cardLevels(
            _cardId,
            _level
        );

        require(
            _level > 0 && _cardLevel.conversionRate > 0,
            "merge not allowed"
        );

        MergeData memory _locals = MergeData({
            cost: 0,
            totalPointsBurned: 0,
            currentTokenToMint: 0,
            willCallPool: false
        });

        _locals.cost = _cardLevel.conversionRate * _mintAmount;

        uint256[] memory mergedTokensIds;
        INftStakingPool nftStakingPool;

        _locals.willCallPool =
            nftStakingPoolAddress != address(0) &&
            _level > 0 &&
            nftContract.cardLevels(_cardId, _level - 1).tokenId == 0;
       
        if (_locals.willCallPool) {
            mergedTokensIds = new uint256[](_tokenIds.length);
            if (_locals.willCallPool) {
                nftStakingPool = INftStakingPool(nftStakingPoolAddress);
            }            
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _burnAmounts[i] <=
                    nftContract.balanceOf(_msgSender(), _tokenIds[i]),
                "not enough balance"
            );
            IRainiNft1155.TokenVars memory _tempTokenVars = nftContract
                .tokenVars(_tokenIds[i]);
            require(_tempTokenVars.cardId == _cardId, "card mismatch");
            require(
                _tempTokenVars.level < _level,
                "bad merge"
            );
            IRainiNft1155.CardLevel memory _tempCardLevel = nftContract
                .cardLevels(_tempTokenVars.cardId, _tempTokenVars.level);
            if (_tempTokenVars.level == 0) {
                _locals.totalPointsBurned += _burnAmounts[i];
            } else {
                _locals.totalPointsBurned +=
                    _burnAmounts[i] *
                    _tempCardLevel.conversionRate;
            }
            nftContract.burn(
                _tokenIds[i],
                _burnAmounts[i],
                _msgSender()
            );

            if (_locals.willCallPool) {
                mergedTokensIds[i] = _tokenIds[i];
                if (
                    _locals.totalPointsBurned >
                    (_locals.currentTokenToMint + 1) *
                        _cardLevel.conversionRate ||
                    i == _tokenIds.length - 1
                ) {
                    _locals.currentTokenToMint++;
                    if (_locals.willCallPool) {
                        nftStakingPool.mergeTokens(
                            _locals.currentTokenToMint +
                                nftContract.maxTokenId(),
                            mergedTokensIds,
                            address(nftContract)
                        );
                    }                    
                    if (_locals.currentTokenToMint < _mintAmount) {
                        mergedTokensIds = new uint256[](
                            _cardLevel.conversionRate
                        );
                    }
                }
            }
        }

        require(
            _locals.totalPointsBurned == _locals.cost,
            "bad no tkns burned"
        );

        require(mergeFees[_level] * _mintAmount <= msg.value, "Not enough ETH");

        (bool success, ) = _msgSender().call{
            value: msg.value - mergeFees[_level] * _mintAmount
        }(""); // refund excess Eth
        require(success, "transfer failed");

        nftContract.mint(
            _msgSender(),
            _cardId,
            _level,
            _mintAmount,
            nftContract.contractChar(),
            0
        );
    }
    
    // Allow the owner to withdraw Ether payed into the contract
    function withdrawEth(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "not enough balance");
        (bool success, ) = _msgSender().call{value: _amount}("");
        require(success, "transfer failed");
    }
}
