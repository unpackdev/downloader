// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./ownable.sol";
import "./variables.sol";
import "./Initializable.sol";
import "./events.sol";
import "./interfaces.sol";
import "./helpers.sol";

contract InteropBetaImplementation is Variables, Initializable, Helpers, Events {
    ListInterface public immutable list;
    IndexInterface public immutable instaIndex;

    constructor(
        address _instaIndex
    ) {
        instaIndex = IndexInterface(_instaIndex);
        list = ListInterface(IndexInterface(_instaIndex).list());
    }

    function initialize(address owner_) public initializer {
        _owner = owner_;
    }

    function submitAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) external {
        uint256 sourceChainId = getChainID();
        address dsaAddr = msg.sender;
        uint256 sourceDsaId = list.accountID(dsaAddr);
        require(sourceDsaId != 0, "msg.sender-not-dsa");

        bytes32 key = keccak256(abi.encode(sourceChainId, targetChainId, vnonce));
        
        emit LogSubmit(
            position,
            actionId,
            keccak256(abi.encodePacked(actionId)),
            sourceDsaSender,
            sourceDsaId,
            targetDsaId,
            sourceChainId,
            targetChainId,
            vnonce,
            metadata
        );
        
        actionDsaAddress[key] = dsaAddr;
        vnonce++;
    }

    function submitSystemAction(
        string memory systemActionId,
        Position memory position,
        bytes memory metadata
    ) external {
        uint256 sourceChainId = getChainID();
        require(IGnosisSafe(owner()).isOwner(msg.sender), "not-gnosis-safe-owner");

        bytes32 key = keccak256(abi.encode(sourceChainId, vnonce));

        emit LogSubmitSystem(
            position,
            systemActionId,
            keccak256(abi.encodePacked(systemActionId)),
            owner(),
            msg.sender,
            vnonce,
            metadata
        );

        vnonce++;
    }

    function submitRevertAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {
        uint256 sourceChainId = getChainID();
        address sourceDsaAddr = list.accountAddr(sourceDsaId);
        require(sourceDsaAddr != address(0), "dsa-not-valid");

        bytes32 key = keccak256(abi.encode(sourceChainId, targetChainId, _vnonce));

        require(IGnosisSafe(owner()).isOwner(msg.sender), "not-gnosis-safe-owner");

        if (executeMapping[key] == false) executeMapping[key] = false;
        
        emit LogRevert(
            position,
            actionId,
            keccak256(abi.encodePacked(actionId)),
            sourceDsaSender,
            sourceDsaId,
            targetDsaId,
            sourceChainId,
            targetChainId,
            _vnonce,
            metadata
        );
    }

    /**
     * @dev cast sourceAction
     */
    function sourceAction(
        Spell[] memory sourceSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) 
        external 
        onlyOwner
    {
        ActionVariables memory s;

        s.key = keccak256(abi.encode(sourceChainId, targetChainId, _vnonce));

        require(executeMapping[s.key] == false, "already-executed");

        s.dsa = AccountInterface(list.accountAddr(sourceDsaId));
        require(address(s.dsa) != address(0), "dsa-not-valid");
        
        sendSourceTokens(position.withdraw, address(s.dsa));

        s.success = cast(s.dsa, sourceSpells);
        if (s.success) {
            executeMapping[s.key] = true;
            emit LogValidate(
                sourceSpells,
                position,
                actionId,
                keccak256(abi.encodePacked(actionId)),
                sourceDsaSender,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce,
                metadata
            );
        } else {
            revert ErrorSourceFailed({
                vnonce: vnonce,
                sourceChainId: sourceChainId,
                targetChainId: targetChainId
            });
        }

        require(s.dsa.isAuth(sourceDsaSender), "source-dsa-sender-not-auth");
    }

    function sourceSystemAction(
        string memory systemActionId,
        Position memory position,
        uint256 _vnonce,
        bytes memory metadata
    ) external onlyOwner {
        uint256 sourceChainId = getChainID();

        bytes32 key = keccak256(abi.encode(sourceChainId, _vnonce));
        require(executeMapping[key] == false, "already-executed");
        executeMapping[key] = true;

        sendSourceTokens(position.withdraw, address(owner()));

        emit LogRebalanceSystem(
            position,
            systemActionId,
            keccak256(abi.encodePacked(systemActionId)),
            owner(),
            msg.sender,
            _vnonce,
            metadata
        );
    }

    /**
     * @dev cast sourceActionRevert
     */
    function sourceRevertAction(
        Spell[] memory sourceSpells,
        Spell[] memory sourceRevertSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    )
        external
        onlyOwner
    {
        ActionVariables memory s;

        bool revertSpells = sourceRevertSpells.length > 0;

        s.key = keccak256(abi.encode(sourceChainId, targetChainId, _vnonce));

        require((revertSpells && executeMapping[s.key] == true) || executeMapping[s.key] == false, "revertSpells || executeMapping[s.key] == false");
        s.dsa = AccountInterface(list.accountAddr(sourceDsaId));
        require(address(s.dsa) != address(0), "invalid-dsa");

        sendSourceTokens(position.supply, address(s.dsa));

        if (revertSpells) {
            s.success = cast(s.dsa, sourceRevertSpells);

            if (s.success) {
                emit LogSourceRevert(
                    sourceSpells,
                    sourceRevertSpells,
                    position,
                    actionId,
                    keccak256(abi.encodePacked(actionId)),
                    sourceDsaSender,
                    sourceDsaId,
                    targetDsaId,
                    sourceChainId,
                    targetChainId,
                    _vnonce,
                    metadata
                );
            } else {
                revert();
            }
        } else {
            executeMapping[s.key] = true;
        }

        require(s.dsa.isAuth(sourceDsaSender), "source-dsa-sender-not-auth");
    }

    /**
     * @dev cast targetAction
     */
    function targetAction(
        Spell[] memory sourceSpells,
        Spell[] memory targetSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    )
        external
        onlyOwner
    {
        ActionVariables memory t;

        t.key = keccak256(abi.encode(sourceChainId, targetChainId, _vnonce));

        require(executeMapping[t.key] == false, "already-executed");
        
        if (targetDsaId == 0) targetDsaId = uint64(list.accounts());
        t.dsa = AccountInterface(list.accountAddr(targetDsaId));
        require(address(t.dsa) != address(0), "invalid-dsa");

        sendTargetTokens(position.supply, address(t.dsa));

        {
            t.success = cast(t.dsa, targetSpells);

            if (t.success) {
                executeMapping[t.key] = true;
                emit LogExecute(
                    sourceSpells,
                    targetSpells,
                    position,
                    actionId,
                    keccak256(abi.encodePacked(actionId)),
                    sourceDsaSender,
                    sourceDsaId,
                    targetDsaId,
                    sourceChainId,
                    targetChainId,
                    _vnonce,
                    metadata
                );
            } else {
                revert ErrorTargetFailed({
                    vnonce: vnonce,
                    sourceChainId: sourceChainId,
                    targetChainId: targetChainId
                });
            }
        }

        require(t.dsa.isAuth(sourceDsaSender), "source-dsa-sender-not-auth");
    }

     /**
     * @dev cast targetRevertAction
     */
    function targetRevertAction(
        Spell[] memory sourceSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    )
        external
        onlyOwner
    {
        ActionVariables memory t;

        t.key = keccak256(abi.encode(sourceChainId, targetChainId, _vnonce));

        require(executeMapping[t.key] == false, "already-executed");
        executeMapping[t.key] = true;
        emit LogTargetRevert(
            sourceSpells,
            position,
            actionId,
            keccak256(abi.encodePacked(actionId)),
            sourceDsaSender,
            sourceDsaId,
            targetDsaId,
            sourceChainId,
            targetChainId,
            _vnonce,
            metadata
        );
    }
}