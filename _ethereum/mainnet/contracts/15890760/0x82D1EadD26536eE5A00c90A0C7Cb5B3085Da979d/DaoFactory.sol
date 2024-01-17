// SPDX-License-Identifier: MIT

import "./DaoToken.sol";
import "./IERC20Dao.sol";
import "./Pausable.sol";
import "./IDAOJoin.sol";

pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title DaoFactory
 * @notice Contract which manages daos in MetaPlayerOne.
 */
contract DaoFactory is Pausable {
    struct Dao { string name; string symbol; address owner_of; uint256 amount; uint256 limit; uint256 price; address token_address; }

    mapping(address => Dao) private _dao_by_contract;
    mapping(address => address[]) private _daos_by_owner;
    mapping(address => address) private _owner_by_dao;
    mapping(address => bool) private _is_activated;

    /**
    * @dev setup owner of this contract.
    */
    constructor (address owner_of_) Pausable(owner_of_) {}
    
    /**
    * @dev emits when new dao has been created or added to DaoFactory.
    */
    event daoCreated(string name, string symbol, address owner_of, uint256 presale, uint256 limit, uint256 price, address token_address, address join_address, bool created);

    /**
    * @dev function which creates dao with params.
    * @param name name of ERC20 which you want to add to DaoFactory.
    * @param symbol symbol of ERC20 which you want to add to DaoFactory.
    * @param presale presale of ERC20 which you want to add to DaoFactory.
    * @param limit limit of ERC20 which you want to add to DaoFactory.
    * @param price mint price of ERC20 which you want to add to DaoFactory.
    */
    function createDao(string memory name, string memory symbol, uint256 presale, uint256 limit, uint256 price) public notPaused {
        DaoToken token = new DaoToken(name, symbol, msg.sender, presale, limit, price);
        address join;
        try token.limit() { join = IDAOJoin(address(token)).joinAddress(); } catch {} 
        address token_address = address(token);
        _dao_by_contract[token_address] = Dao(name, symbol, msg.sender, presale, limit, price, token_address);
        _daos_by_owner[msg.sender].push(token_address);
        _owner_by_dao[token_address] = msg.sender;
        _is_activated[token_address] = true;
        emit daoCreated(name, symbol, msg.sender, presale, limit, price, token_address, join, true);
    }

    /**
    * @dev function which creates dao with params.
    * @param token_address token address of ERC20 which you want to add to DaoFactory.
    */
    function addDao(address token_address) public notPaused {
        require(!_is_activated[token_address], "Dao is already activated");
        IERC20Dao token = IERC20Dao(token_address);
        uint256 limit = 0;
        uint256 presale = 0;
        uint256 price = 0;
        try token.limit() { limit = token.limit(); } catch {}
        try token.presale() { presale = token.presale(); } catch {}
        try token.price() { price = token.price(); } catch {}
        _dao_by_contract[token_address] = Dao(token.name(), token.symbol(), msg.sender, presale, limit, price, token_address);
        _daos_by_owner[msg.sender].push(token_address);
        _owner_by_dao[token_address] = msg.sender;
        _is_activated[token_address] = true;
        emit daoCreated(token.name(), token.symbol(), msg.sender, presale, limit, price, token_address, address(0), false);
    }

    /**
    * @dev function which creates dao with params.
    * @param owner_of address of user, which daos should be returned
    * @return address list of dao addresses which this user register
    */
    function getDaosByOwner(address owner_of) public view returns (address[] memory) {
        return _daos_by_owner[owner_of];
    }

    /**
    * @dev function which creates dao with params.
    * @param dao_address includes name of project, project description and project banner and project logo
    * @return owner_of returns owner of requested dao.
    */
    function getDaoOwner(address dao_address) public view returns (address) {
        return _owner_by_dao[dao_address];
    }
}
