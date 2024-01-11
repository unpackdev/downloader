// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./AccessControlEnumerable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IHoneyToken.sol";
import "./tag.sol";

contract Hive is AccessControlEnumerable {
    
    bytes32 public constant HONEY_SPENDER = keccak256("HONEY_SPENDER");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    using SafeERC20 for IHoneyToken;
    using SafeMath for uint256;

    IHoneyToken public honeyTokenContract;

    mapping(address => mapping(uint256 => uint256))
        public depositsByTokenIdOfCollection;
    mapping(address => mapping(uint256 => uint256))
        public spentHoneyByTokenIdOfCollection;

    uint256 public spentHoney;

    event Deposit(
        address _address,
        address indexed _collection,
        uint256 indexed _tokenId,
        uint256 _amount
    );
    event Spend(
        address _address,
        address indexed _collection,
        uint256 indexed _tokenId,
        uint256 _amount
    );

    constructor(IHoneyToken _honeyTokenContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        honeyTokenContract = _honeyTokenContract;
    }

    function depositHoneyToTokenIdsOfCollections(
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) public {
        uint256 totalHoney;
        uint256 lengthToMatch = _collections.length;

        require(
            _tokenIds.length == lengthToMatch &&
                _amounts.length == lengthToMatch,
            "depositHoneyToTokenIdOfCollection: array length mismatch"
        );

        for (uint256 i = 0; i < lengthToMatch; i++) {
            require(
                _amounts[i] != 0,
                "depositHoneyToTokenIdOfCollection: amount deposited must be greater than zero"
            );
            depositsByTokenIdOfCollection[_collections[i]][
                _tokenIds[i]
            ] += _amounts[i];
            totalHoney += _amounts[i];
            emit Deposit(
                msg.sender,
                _collections[i],
                _tokenIds[i],
                _amounts[i]
            );
        }

        honeyTokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            totalHoney
        );
    }

    function spendHoneyFromTokenIdsOfCollections(
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) public onlyRole(HONEY_SPENDER) {
        uint256 totalHoney;
        uint256 lengthToMatch = _collections.length;

        require(
            _tokenIds.length == lengthToMatch &&
                _amounts.length == lengthToMatch,
            "spendHoneyFromTokenIdOfCollection: array length mismatch"
        );

        for (uint256 i = 0; i < lengthToMatch; i++) {
            require(
                depositsByTokenIdOfCollection[_collections[i]][_tokenIds[i]] >=
                    spentHoneyByTokenIdOfCollection[_collections[i]][
                        _tokenIds[i]
                    ].add(_amounts[i]),
                "spendHoneyFromTokenIdOfCollection: not enough honey remaining in hive for collection and tokenId"
            );

            spentHoneyByTokenIdOfCollection[_collections[i]][
                _tokenIds[i]
            ] += _amounts[i];

            totalHoney += _amounts[i];

            emit Spend(tx.origin, _collections[i], _tokenIds[i], _amounts[i]);
        }

        spentHoney += totalHoney;
    }

    function getBalanceByTokenIdsOfCollection(
        address _collection,
        uint256[] calldata _tokenIds
    )
        public
        view
        returns (uint256[] memory)
    {

        uint256[] memory balances = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            balances[i] =
                depositsByTokenIdOfCollection[_collection][_tokenIds[i]] -
                spentHoneyByTokenIdOfCollection[_collection][_tokenIds[i]];
        }
        return (balances);

    }

    function getBalanceByTokenIdsOfCollections(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) public view returns (uint256[][] memory) {
        require(
            _collections.length == _tokenIds.length,
            "getSpentHoneyByTokenIdsOfCollections: array mismatch"
        );
        uint256[][] memory balances = new uint256[][](_collections.length);

        for (uint256 i = 0; i < _collections.length; i++) {
            
            balances[i] = getBalanceByTokenIdsOfCollection(_collections[i], _tokenIds[i]);
            
        }
        return balances;
    }

    function withdrawSpentHoney(address _address)
        public
        onlyRole(MANAGER_ROLE)
    {
        honeyTokenContract.safeTransfer(_address, spentHoney);
        spentHoney = 0;
    }
}
