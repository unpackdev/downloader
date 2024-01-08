// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

import "./ERC20.sol";
import "./Ownable.sol";

contract PollenToken is ERC20, Ownable {
    address public dao;
    address public reserve;

    modifier onlyDAO() {
        require(msg.sender == dao, "Pollen: only callable by DAO contract");
        _;
    }

    constructor(address _reserve) ERC20("Pollen", "PLN") {
        reserve = _reserve;
        _mint(_reserve, 94000000000000000000000000); // 94M
    }

    ///@notice Sets the address of the PollenDAO, which has sole mint/burn privileges
    /// Can only be set once
    ///@param daoAddress address of DAO contract
    function setDaoAddress(address daoAddress) external onlyOwner {
        require(
            daoAddress != address(0),
            "Pollen: DAO contract cannot be zero address"
        );
        require(dao == address(0), "Pollen: DAO address has already been set");
        dao = daoAddress;
    }

    ///@notice Mints PLN as rewards for positive portfolio returns
    /// Can only be called by the DAO
    ///@param amount amount to mint
    function mint(address to, uint256 amount) external onlyDAO {
        _mint(to, amount);
    }

    ///@notice Burns PLN for portfolio lossess
    /// Can only be called by the DAO
    ///@param amount amount to burn
    function burn(uint256 amount) external onlyDAO {
        _burn(dao, amount);
    }
}
