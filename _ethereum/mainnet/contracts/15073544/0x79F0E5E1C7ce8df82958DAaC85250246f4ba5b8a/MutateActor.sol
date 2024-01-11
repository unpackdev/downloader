// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IBaseCollection.sol";
import "./IMutateCollection.sol";

contract MutateActor is
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    struct RuleEntry {
        address origin;
        address catalyst;
        address outcome;
    }

    struct HistoryEntry {
        uint256 originId;
        uint256 catalystId;
        uint256 outcomeId;
    }

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    address public _burnWallet;

    RuleEntry private _curRule;
    RuleEntry[] private _allRules;

    mapping(address => mapping(address => HistoryEntry[]))
        private _mutateHistory;
    mapping(bytes32 => bool) private _checkMutated; // keccak256(origin_address, outcome_address, origin_id) => is_mutated_flag

    event NftMutated(
        address indexed account,
        address indexed origin,
        address indexed outcome,
        address catalyst,
        uint256 originId,
        uint256 catalystId,
        uint256 outcomeId
    );
    event MutateRuleAdded(
        address indexed origin,
        address indexed catalyst,
        address indexed outcome
    );

    function initialize(
        address burnWallet,
        address originCollection,
        address catalystCollection,
        address outcomeCollection
    ) public initializer {
        __Ownable_init();

        require(
            originCollection != address(0) &&
                catalystCollection != address(0) &&
                outcomeCollection != address(0),
            "Invalid params"
        );

        _burnWallet = burnWallet;

        _curRule = RuleEntry({
            origin: originCollection,
            catalyst: catalystCollection,
            outcome: outcomeCollection
        });
        _allRules.push(_curRule);
    }

    function mutateNft(uint256 originId, uint256 catalystId) external {
        address originCollection = _curRule.origin;
        address outcomeCollection = _curRule.outcome;
        address catalystCollection = _curRule.catalyst;

        require(
            !checkMutated(originCollection, outcomeCollection, originId),
            "Already mutated"
        );

        require(
            IERC721Upgradeable(originCollection).ownerOf(originId) ==
                _msgSender(),
            "Not owned originId"
        );
        // Catalyst nft should be sent user => contract => burn wallet
        IERC721Upgradeable(catalystCollection).safeTransferFrom(
            _msgSender(),
            address(this),
            catalystId
        );
        IERC721Upgradeable(catalystCollection).safeTransferFrom(
            address(this),
            _burnWallet,
            catalystId
        );

        // Mutate NFT with same token_id as original NFT
        IMutateCollection(outcomeCollection).mutateMint(originId, _msgSender());

        bytes32 hash = keccak256(
            abi.encodePacked(originCollection, outcomeCollection, originId)
        );
        _checkMutated[hash] = true;

        emit NftMutated(
            _msgSender(),
            originCollection,
            outcomeCollection,
            catalystCollection,
            originId,
            catalystId,
            originId
        );
    }

    function checkMutated(
        address origin,
        address outcome,
        uint256 originId
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(origin, outcome, originId));
        return _checkMutated[hash];
    }

    function updateBurnWalelt(address burnWallet) external onlyOwner {
        _burnWallet = burnWallet;
    }

    function setNewRule(
        address originCollection,
        address catalystCollection,
        address outcomeCollection
    ) external onlyOwner {
        require(
            originCollection != address(0) &&
                catalystCollection != address(0) &&
                outcomeCollection != address(0),
            "Invalid params"
        );

        uint256 ruleCount = _allRules.length;
        bool existingRule = false;
        // Check if this rule is used before
        for (uint256 i = 0; i < ruleCount; i++) {
            address origin = _allRules[i].origin;
            address outcome = _allRules[i].outcome;
            address catalyst = _allRules[i].catalyst;
            if (
                originCollection == origin &&
                catalystCollection == catalyst &&
                outcomeCollection == outcome
            ) {
                existingRule = true;
                break;
            }
        }

        _curRule = RuleEntry({
            origin: originCollection,
            catalyst: catalystCollection,
            outcome: outcomeCollection
        });

        // Add to the rule array in case of used before
        if (!existingRule) {
            _allRules.push(_curRule);
            emit MutateRuleAdded(
                originCollection,
                catalystCollection,
                outcomeCollection
            );
        }
    }

    function recoverERC20(address token, uint256 amount) external onlyOwner {
        require(
            IERC20Upgradeable(token).balanceOf(address(this)) >= amount,
            "Not enough to withdraw"
        );
        IERC20Upgradeable(token).transferFrom(
            address(this),
            _msgSender(),
            amount
        );
    }

    function recoverETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough to withdraw");

        AddressUpgradeable.sendValue(payable(_msgSender()), amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
