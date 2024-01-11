//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IGMUOracle.sol";
import "./SafeMath.sol";
import "./ERC20RebasePermit.sol";

contract ARTHGmuRebaseERC20 is ERC20RebasePermit, Ownable {
    using SafeMath for uint256;

    IGMUOracle public gmuOracle;
    uint8 public decimals = 18;
    string public symbol;

    event GmuOracleChange(address indexed oracle);

    constructor(
        string memory _name,
        string memory _symbol,
        address _gmuOracle,
        address governance,
        uint256 chainId
    ) ERC20RebasePermit(_name, chainId) {
        symbol = _symbol;
        setGMUOracle(_gmuOracle);
        _transferOwnership(governance); // transfer ownership to governance
    }

    function gonsPerFragment()
        public
        view
        override
        returns (uint256)
    {
        // make the gons per fragment be as per the gmu oracle
        return gmuOracle.getPrice();
    }

    function gonsDecimals()
        public
        view
        override
        virtual
        returns (uint256)
    {
        return gmuOracle.getDecimalPercision();
    }

    /**
     * @dev only governance can change the gmu oracle
     */
    function setGMUOracle(address _gmuOracle)
        public
        onlyOwner
    {
        gmuOracle = IGMUOracle(_gmuOracle);
        emit GmuOracleChange(_gmuOracle);
    }
}
