// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC1155.sol";
import "./IERC2981.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./CTHelpers.sol";
import "./ConditionalTokenLibrary.sol";
import "./IOracle.sol";
import "./IConditionalTokens.sol";
import "./ITokenURIBuilder.sol";
import "./IWETH.sol";
import "./ERC1155WithRevokableDefaultOperatorFilterer.sol";

contract ConditionalTokens is
    IConditionalTokens,
    ERC1155WithRevokableDefaultOperatorFilterer,
    IERC2981,
    Ownable
{
    using SafeERC20 for IERC20;

    /// @dev Emitted upon the successful preparation of a condition.
    /// @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    event ConditionPreparation(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount
    );

    event ConditionResolution(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount,
        uint256[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 outputAmount,
        uint256 decimalOffset
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 inputAmount,
        uint256 decimalOffset
    );
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 conditionId,
        uint256[] indexSets,
        uint256 decimalOffset,
        uint256 payout
    );
    event ConvertDecimalOffset(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256 indexSet,
        uint256 inputAmount,
        uint8 fromDecimalOffset,
        uint8 toDecimalOffset,
        uint256 outputAmount
    );

    address public immutable weth;
    ITokenURIBuilder public tokenURIBuilder;
    address public royaltyReceiver;

    /// Oracle is allowed to prepareCondition. It acts as a permission-list on whether which address can set questions.
    mapping(address => bool) public allowedOracle;

    // ConditionID -> Condition
    mapping(bytes32 => ConditionalTokenLibrary.Condition) public conditions;

    // CollectionId -> Collection
    mapping(bytes32 => ConditionalTokenLibrary.Collection) public collections;

    // positionId -> Position
    mapping(uint256 => ConditionalTokenLibrary.Position) public positions;

    /// Mapping key is an condition ID. Value represents numerators of the payout vector associated with the condition. This array is initialized with a length equal to the outcome slot count. E.g. Condition with 3 outcomes [A, B, C] and two of those correct [0.5, 0.5, 0]. In Ethereum there are no decimal values, so here, 0.5 is represented by fractions like 1/2 == 0.5. That's why we need numerator and denominator values. Payout numerators are also used as a check of initialization. If the numerators array is empty (has length zero), the condition was not created/prepared. See getOutcomeSlotCount.
    mapping(bytes32 => uint256[]) public payoutNumerators;
    /// Denominator is also used for checking if the condition has been resolved. If the denominator is non-zero, then the condition has been resolved.
    mapping(bytes32 => uint256) public payoutDenominator;

    constructor(address _weth) ERC1155("") {
        royaltyReceiver = msg.sender;
        weth = _weth;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    function getCondition(bytes32 _conditionId)
        public
        view
        returns (ConditionalTokenLibrary.Condition memory)
    {
        return conditions[_conditionId];
    }

    function getCollection(bytes32 _collectionId)
        public
        view
        returns (ConditionalTokenLibrary.Collection memory)
    {
        return collections[_collectionId];
    }

    function getPosition(uint256 _positionId)
        public
        view
        returns (ConditionalTokenLibrary.Position memory)
    {
        return positions[_positionId];
    }

    function getERC20Decimals(ERC20 _token) public view returns (uint8) {
        try _token.decimals() returns (uint8 decimal) {
            return decimal;
        } catch {}
        return 0;
    }

    function decimals(uint256 _positionId) public view returns (uint256) {
        ConditionalTokenLibrary.Position memory position = positions[_positionId];
        return getERC20Decimals(ERC20(address(position.collateralToken))) - position.decimalOffset;
    }

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param _questionId An identifier for the question to be answered by the oracle.
    /// @param _outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(bytes32 _questionId, uint256 _outcomeSlotCount) external {
        require(allowedOracle[msg.sender], "oracle not allowed");

        // Limit of 256 because we use a partition array that is a number of 256 bits.
        require(_outcomeSlotCount <= 256, "too many outcome slots");
        require(_outcomeSlotCount > 1, "there should be more than one outcome slot");
        bytes32 conditionId = CTHelpers.getConditionId(msg.sender, _questionId, _outcomeSlotCount);
        require(payoutNumerators[conditionId].length == 0, "condition already prepared");
        payoutNumerators[conditionId] = new uint256[](_outcomeSlotCount);
        conditions[conditionId] = ConditionalTokenLibrary.Condition(
            IOracle(msg.sender),
            _questionId,
            _outcomeSlotCount
        );
        emit ConditionPreparation(conditionId, msg.sender, _questionId, _outcomeSlotCount);
    }

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param _questionId The question ID the oracle is answering for
    /// @param _payouts The oracle's answer
    function reportPayouts(bytes32 _questionId, uint256[] calldata _payouts) external {
        uint256 outcomeSlotCount = _payouts.length;
        require(outcomeSlotCount > 1, "there should be more than one outcome slot");
        // IMPORTANT, the oracle is enforced to be the sender because it's part of the hash.
        bytes32 conditionId = CTHelpers.getConditionId(msg.sender, _questionId, outcomeSlotCount);
        require(
            payoutNumerators[conditionId].length == outcomeSlotCount,
            "condition not prepared or found"
        );
        require(payoutDenominator[conditionId] == 0, "payout denominator already set");

        uint256 den = 0;
        for (uint256 i = 0; i < outcomeSlotCount; i++) {
            uint256 num = _payouts[i];
            den += num;

            require(payoutNumerators[conditionId][i] == 0, "payout numerator already set");
            payoutNumerators[conditionId][i] = num;
        }
        require(den > 0, "payout is all zeroes");
        payoutDenominator[conditionId] = den;
        emit ConditionResolution(
            conditionId,
            msg.sender,
            _questionId,
            outcomeSlotCount,
            payoutNumerators[conditionId]
        );
    }

    /// @dev Internal helper function used by splitPosition and splitPositionETH
    function split(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _outputAmount,
        uint8 _decimalOffset
    ) internal returns (uint256 freeIndexSet) {
        require(
            conditions[_conditionId].oracle.canSplit(
                _collateralToken,
                0,
                _conditionId,
                _partition,
                _decimalOffset
            ),
            "oracle rejected split"
        );
        require(_partition.length > 1, "got empty or singleton partition");
        require(payoutNumerators[_conditionId].length > 0, "condition not prepared yet");
        require(
            getERC20Decimals(ERC20(address(_collateralToken))) >= _decimalOffset,
            "_decimalOffset must be less than decimals of _collateralToken"
        );

        // For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
        uint256 fullIndexSet = (1 << payoutNumerators[_conditionId].length) - 1;
        // freeIndexSet starts as the full collection
        freeIndexSet = fullIndexSet;

        uint256[] memory positionIds = new uint256[](_partition.length);
        uint256[] memory amounts = new uint256[](_partition.length);

        for (uint256 i = 0; i < _partition.length; i++) {
            uint256 indexSet = _partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            bytes32 collectionId = CTHelpers.getCollectionId(
                _parentCollectionId,
                _conditionId,
                indexSet
            );
            positionIds[i] = CTHelpers.getPositionId(
                _collateralToken,
                collectionId,
                _decimalOffset
            );
            if (collections[collectionId].conditionId == 0) {
                collections[collectionId] = ConditionalTokenLibrary.Collection(
                    _parentCollectionId,
                    _conditionId,
                    indexSet
                );
            }
            if (positions[positionIds[i]].collectionId == 0) {
                positions[positionIds[i]] = ConditionalTokenLibrary.Position(
                    _collateralToken,
                    collectionId,
                    _decimalOffset
                );
            }
            amounts[i] = _outputAmount;
        }

        if (freeIndexSet == 0) {
            if (_parentCollectionId != bytes32(0)) {
                _burn(
                    msg.sender,
                    CTHelpers.getPositionId(_collateralToken, _parentCollectionId, _decimalOffset),
                    _outputAmount
                );
            }
        } else {
            // Partitioning a subset of outcomes for the condition in this branch.
            // For example, for a condition with three outcomes A, B, and C, this branch
            // allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
            _burn(
                msg.sender,
                CTHelpers.getPositionId(
                    _collateralToken,
                    CTHelpers.getCollectionId(
                        _parentCollectionId,
                        _conditionId,
                        fullIndexSet ^ freeIndexSet
                    ),
                    _decimalOffset
                ),
                _outputAmount
            );
        }

        _mintBatch(
            msg.sender,
            positionIds, // position ID is the ERC 1155 token ID
            amounts,
            ""
        );

        emit PositionSplit(
            msg.sender,
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _partition,
            _outputAmount,
            _decimalOffset
        );
    }

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `_outputAmount * 10**_decimalOffset` collateral from the message sender to itself. Otherwise, this contract will burn `_outputAmount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `_outputAmount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param _collateralToken The address of the positions' backing collateral token.
    /// @param _parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param _conditionId The ID of the condition to split on.
    /// @param _partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param _outputAmount The output amount of conditional token (DecimalOffset educted).
    /// @param _decimalOffset Offset of decimal between collateral token and conditional token
    function splitPosition(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _outputAmount,
        uint8 _decimalOffset
    ) external {
        uint256 freeIndexSet = split(
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _partition,
            _outputAmount,
            _decimalOffset
        );

        if (freeIndexSet == 0 && _parentCollectionId == bytes32(0)) {
            _collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _outputAmount * 10**_decimalOffset
            );
        }
    }

    function splitPositionETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external payable {
        IERC20 collateralToken = IERC20(weth);
        require(msg.value % 10**_decimalOffset == 0, "remainder found");
        uint256 outputAmount = msg.value / 10**_decimalOffset;

        uint256 freeIndexSet = split(
            collateralToken,
            0,
            _conditionId,
            _partition,
            outputAmount,
            _decimalOffset
        );

        require(freeIndexSet == 0, "incorrect split");
        IWETH(weth).deposit{ value: msg.value }();
    }

    /// @dev Internal helper function used by mergePositions and mergePositionsETH
    function merge(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _inputAmount,
        uint8 _decimalOffset
    ) internal returns (uint256 freeIndexSet) {
        require(
            conditions[_conditionId].oracle.canMerge(
                _collateralToken,
                _parentCollectionId,
                _conditionId,
                _partition,
                _decimalOffset
            ),
            "oracle rejected merge"
        );
        require(_partition.length > 1, "got empty or singleton partition");
        require(payoutNumerators[_conditionId].length > 0, "condition not prepared yet");

        uint256 fullIndexSet = (1 << payoutNumerators[_conditionId].length) - 1;
        freeIndexSet = fullIndexSet;
        uint256[] memory positionIds = new uint256[](_partition.length);
        uint256[] memory amounts = new uint256[](_partition.length);
        for (uint256 i = 0; i < _partition.length; i++) {
            uint256 indexSet = _partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            bytes32 collectionId = CTHelpers.getCollectionId(
                _parentCollectionId,
                _conditionId,
                indexSet
            );
            positionIds[i] = CTHelpers.getPositionId(
                _collateralToken,
                collectionId,
                _decimalOffset
            );
            if (collections[collectionId].conditionId == 0) {
                collections[collectionId] = ConditionalTokenLibrary.Collection(
                    _parentCollectionId,
                    _conditionId,
                    indexSet
                );
            }
            if (positions[positionIds[i]].collectionId == 0) {
                positions[positionIds[i]] = ConditionalTokenLibrary.Position(
                    _collateralToken,
                    collectionId,
                    _decimalOffset
                );
            }

            amounts[i] = _inputAmount;
        }
        _burnBatch(msg.sender, positionIds, amounts);

        if (freeIndexSet == 0) {
            if (_parentCollectionId != bytes32(0)) {
                _mint(
                    msg.sender,
                    CTHelpers.getPositionId(_collateralToken, _parentCollectionId, _decimalOffset),
                    _inputAmount,
                    ""
                );
            }
        } else {
            _mint(
                msg.sender,
                CTHelpers.getPositionId(
                    _collateralToken,
                    CTHelpers.getCollectionId(
                        _parentCollectionId,
                        _conditionId,
                        fullIndexSet ^ freeIndexSet
                    ),
                    _decimalOffset
                ),
                _inputAmount,
                ""
            );
        }

        emit PositionsMerge(
            msg.sender,
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _partition,
            _inputAmount,
            _decimalOffset
        );
    }

    function mergePositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _inputAmount,
        uint8 _decimalOffset
    ) external {
        uint256 freeIndexSet = merge(
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _partition,
            _inputAmount,
            _decimalOffset
        );

        if (freeIndexSet == 0 && _parentCollectionId == bytes32(0)) {
            _collateralToken.safeTransfer(msg.sender, _inputAmount * 10**_decimalOffset);
        }
    }

    function mergePositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _inputAmount,
        uint8 _decimalOffset
    ) external payable {
        IERC20 collateralToken = IERC20(weth);

        uint256 freeIndexSet = merge(
            collateralToken,
            0,
            _conditionId,
            _partition,
            _inputAmount,
            _decimalOffset
        );

        require(freeIndexSet == 0, "incorrect merge");
        uint256 outputAmount = _inputAmount * 10**_decimalOffset;
        IWETH(weth).withdraw(outputAmount);

        (bool success, ) = payable(msg.sender).call{ value: outputAmount }("");
        require(success, "fail to send ether");
    }

    /// @dev Internal helper function used by redeemPositions and redeemPositionsETH
    function redeem(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) internal returns (uint256 totalPayout) {
        uint256 den = payoutDenominator[_conditionId];
        require(den > 0, "result for condition not received yet");
        uint256 outcomeSlotCount = payoutNumerators[_conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        totalPayout = 0;

        uint256 fullIndexSet = (1 << outcomeSlotCount) - 1;
        for (uint256 i = 0; i < _indexSets.length; i++) {
            uint256 indexSet = _indexSets[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            uint256 positionId = CTHelpers.getPositionId(
                _collateralToken,
                CTHelpers.getCollectionId(_parentCollectionId, _conditionId, indexSet),
                _decimalOffset
            );

            uint256 payoutNumerator = 0;
            for (uint256 j = 0; j < outcomeSlotCount; j++) {
                if (indexSet & (1 << j) != 0) {
                    payoutNumerator += payoutNumerators[_conditionId][j];
                }
            }

            uint256 payoutStake = balanceOf(msg.sender, positionId);
            if (payoutStake > 0) {
                totalPayout += (payoutStake * payoutNumerator) / den;
                _burn(msg.sender, positionId, payoutStake);
            }
        }

        require(totalPayout > 0, "zero payout");

        if (_parentCollectionId != bytes32(0)) {
            _mint(
                msg.sender,
                CTHelpers.getPositionId(_collateralToken, _parentCollectionId, _decimalOffset),
                totalPayout,
                ""
            );
        }

        emit PayoutRedemption(
            msg.sender,
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _indexSets,
            _decimalOffset,
            totalPayout
        );
    }

    function redeemPositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external {
        uint256 totalPayout = redeem(
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _indexSets,
            _decimalOffset
        );

        if (_parentCollectionId == 0) {
            _collateralToken.safeTransfer(msg.sender, totalPayout * 10**_decimalOffset);
        }
    }

    function redeemPositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external payable {
        IERC20 collateralToken = IERC20(weth);
        uint256 totalPayout = redeem(collateralToken, 0, _conditionId, _indexSets, _decimalOffset);

        uint256 totalPayoutETH = totalPayout * 10**_decimalOffset;
        IWETH(weth).withdraw(totalPayoutETH);

        (bool success, ) = payable(msg.sender).call{ value: totalPayoutETH }("");
        require(success, "fail to send ether");
    }

    /// @dev Gets the outcome slot count of a condition.
    /// @param _conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 _conditionId) external view returns (uint256) {
        return payoutNumerators[_conditionId].length;
    }

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param _oracle The account assigned to report the result for the prepared condition.
    /// @param _questionId An identifier for the question to be answered by the oracle.
    /// @param _outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(
        address _oracle,
        bytes32 _questionId,
        uint256 _outcomeSlotCount
    ) external pure returns (bytes32) {
        return CTHelpers.getConditionId(_oracle, _questionId, _outcomeSlotCount);
    }

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param _parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param _conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param _indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet
    ) external view returns (bytes32) {
        return CTHelpers.getCollectionId(_parentCollectionId, _conditionId, _indexSet);
    }

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param _collateralToken Collateral token which backs the position.
    /// @param _collectionId ID of the outcome collection associated with this position.
    /// @param _decimalOffset Number of decimal offset against collateralToken.
    function getPositionId(
        IERC20 _collateralToken,
        bytes32 _collectionId,
        uint256 _decimalOffset
    ) external pure returns (uint256) {
        return CTHelpers.getPositionId(_collateralToken, _collectionId, _decimalOffset);
    }

    /// @dev Obtain tokenURI directly from TokenURIBuilder, which will eventually call Oracle for image.
    /// @param _positionId position ID (token ID).
    function uri(uint256 _positionId) public view override returns (string memory) {
        ConditionalTokenLibrary.Position memory position = positions[_positionId];
        ConditionalTokenLibrary.Collection memory collection = collections[position.collectionId];
        ConditionalTokenLibrary.Condition memory condition = conditions[collection.conditionId];
        return
            tokenURIBuilder.tokenURI(
                condition,
                collection,
                position,
                _positionId,
                decimals(_positionId)
            );
    }

    /// @dev Returns the amount of royalty, which would be fixed 1% of salePrice
    /// @param _salePrice Sale Price of the Token.
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
        return (royaltyReceiver, _salePrice / 100);
    }

    /// @dev ERC165 standard
    /// @param _interfaceId interfaceId of the contract
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            _interfaceId == type(IConditionalTokens).interfaceId ||
            _interfaceId == type(IERC2981).interfaceId || // 0x2a55205a
            super.supportsInterface(_interfaceId);
    }

    /// @dev To set whether the oracle address can prepareCondition a condition
    /// @param _oracle oracle address
    /// @param _isAllowed flag
    function setAllowedOracle(address _oracle, bool _isAllowed) external onlyOwner {
        allowedOracle[_oracle] = _isAllowed;
    }

    /// @dev Update the receiver of royalty
    /// @param _royaltyReceiver Royalty Receiver
    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    /// @dev Update tokenURIBuilder contract
    /// @param _tokenURIBuilder New tokenURIBuilder contract
    function setTokenURIBuilder(ITokenURIBuilder _tokenURIBuilder) external onlyOwner {
        tokenURIBuilder = _tokenURIBuilder;
    }

    function convertDecimalOffset(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet,
        uint256 _inputAmount,
        uint8 _fromDecimalOffset,
        uint8 _toDecimalOffset
    ) external {
        require(
            conditions[_conditionId].oracle.canConvertDecimalOffset(
                _collateralToken,
                _parentCollectionId,
                _conditionId,
                _indexSet,
                _fromDecimalOffset,
                _toDecimalOffset
            ),
            "oracle rejected convertDecimalOffset"
        );
        require(
            (_fromDecimalOffset > _toDecimalOffset) ||
                (_inputAmount % 10**(_toDecimalOffset - _fromDecimalOffset) == 0),
            "remainder found"
        );
        require(_fromDecimalOffset != _toDecimalOffset, "converting to same decimalOffset");
        require(payoutNumerators[_conditionId].length > 0, "condition not prepared yet");
        require(
            getERC20Decimals(ERC20(address(_collateralToken))) >= _toDecimalOffset,
            "_toDecimalOffset must be less than decimals of _collateralToken"
        );
        bytes32 collectionId = CTHelpers.getCollectionId(
            _parentCollectionId,
            _conditionId,
            _indexSet
        );
        uint256 fromPositionId = CTHelpers.getPositionId(
            _collateralToken,
            collectionId,
            _fromDecimalOffset
        );
        uint256 toPositionId = CTHelpers.getPositionId(
            _collateralToken,
            collectionId,
            _toDecimalOffset
        );
        _burn(msg.sender, fromPositionId, _inputAmount);

        if (positions[toPositionId].collectionId == 0) {
            positions[toPositionId] = ConditionalTokenLibrary.Position(
                _collateralToken,
                collectionId,
                _toDecimalOffset
            );
        }

        uint256 outputAmount = _fromDecimalOffset > _toDecimalOffset
            ? _inputAmount * 10**(_fromDecimalOffset - _toDecimalOffset)
            : _inputAmount / 10**(_toDecimalOffset - _fromDecimalOffset);
        _mint(msg.sender, toPositionId, outputAmount, "");

        emit ConvertDecimalOffset(
            msg.sender,
            _collateralToken,
            _parentCollectionId,
            _conditionId,
            _indexSet,
            _inputAmount,
            _fromDecimalOffset,
            _toDecimalOffset,
            outputAmount
        );
    }

    function owner()
        public
        view
        virtual
        override(Ownable, RevokableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}
