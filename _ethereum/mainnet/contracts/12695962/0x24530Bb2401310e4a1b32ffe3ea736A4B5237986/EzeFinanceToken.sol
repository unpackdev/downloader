// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import openzeppelin
import "./Context.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

// import contract
import "./PausableToken.sol";

contract EzeFinanceToken is Context, PausableToken, AccessControl {
    using SafeMath for uint256;

    // public
    uint256 public MAX_SUPPLY;
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    address payable public immutable CHARITY_JESUS_PRO;

    // private
    uint256 private constant _decimals = 18;

    // modifier
    modifier shouldBePauser(address src) {
        require(hasRole(PAUSER_ROLE, src), "caller should be pauser.");
        _;
    }

    constructor(address payable _CHARITY_JESUS_PRO)
        PausableToken("EZE Finance Token", "EZE")
    {
        CHARITY_JESUS_PRO = _CHARITY_JESUS_PRO;
        MAX_SUPPLY = 777777777 * (10**_decimals);

        _setupRole(SNAPSHOT_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 value) public whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller should be minter");

        // totalSupply can not exceed MAX_SUPPLY
        require(
            totalSupply().add(value) <= MAX_SUPPLY,
            "Total supply can not exceed MAX_SUPPLY"
        );

        // mint tokens
        _mint(to, value);
    }

    function snapshot() public {
        require(hasRole(SNAPSHOT_ROLE, _msgSender()));
        _snapshot();
    }

    function pause() public shouldBePauser(_msgSender()) {
        _pause();
    }

    function unpause() public shouldBePauser(_msgSender()) {
        _unpause();
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev send ethers to JesusPro charity program
     */
    function sendEthToJesusPro(uint256 value) external returns (bool) {
        require(
            _msgSender() == CHARITY_JESUS_PRO,
            "Caller: should be JesusPro wallet."
        );
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "Insufficient ether balance");
        CHARITY_JESUS_PRO.transfer(value);
        return true;
    }
}
