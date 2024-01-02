// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC1155URIStorageUpgradeable.sol";

contract OKXBadge is
    Initializable,
    UUPSUpgradeable,
    ERC1155URIStorageUpgradeable,
    OwnableUpgradeable
{
    string private _name;

    address public operator;

    event SetOperator(address newOperator);

    struct OKXBadgeBatch {
        address account; // mint: to; burn: from;
        uint256[] ids;
        uint256[] amounts;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "OKXBadge: not the operator address.");
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(string memory name_, address newOperator)
        public
        initializer
    {
        __ERC1155_init("");
        __ERC1155URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _name = name_;
        operator = newOperator;
        emit SetOperator(newOperator);
    }

    //-------------------------------
    //------- Owner functions ---
    //-------------------------------
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit SetOperator(newOperator);
    }

    //-------------------------------
    //------- Operator functions ----
    //-------------------------------
    function setURI(uint256 tokenId, string memory tokenURI)
        external
        onlyOperator
    {
        _setURI(tokenId, tokenURI);
    }

    function batchMint(OKXBadgeBatch[] calldata mints) external onlyOperator {
        for (uint256 i = 0; i < mints.length; i++) {
            _mintBatch(mints[i].account, mints[i].ids, mints[i].amounts, "");
        }
    }

    function batchBurn(OKXBadgeBatch[] calldata burns) external onlyOperator {
        for (uint256 i = 0; i < burns.length; i++) {
            _burnBatch(burns[i].account, burns[i].ids, burns[i].amounts);
        }
    }

    //-------------------------------
    //------- View functions --------
    //-------------------------------
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function name() public view returns (string memory) {
        return _name;
    }
}
