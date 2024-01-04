// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./AccessControl.sol";
import "./Context.sol";
import "./CustomERC777.sol";
import "./KingOfTheHill.sol";
import "./KOTHPresale.sol";

contract KOTH is Context, CustomERC777, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GAME_MASTER_ROLE = keccak256("GAME_MASTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address owner, address presaleContract) CustomERC777("KOTH", "KOTH", new address[](0)) {
        _onCreate(owner, presaleContract);
    }

    function _onCreate(address owner, address presaleContract) private {
        _pause();
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(GAME_MASTER_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(MINTER_ROLE, presaleContract);
        _setupRole(PAUSER_ROLE, owner);
        _setupRole(PAUSER_ROLE, presaleContract);
        _register(presaleContract);
    }

    function _register(address presaleContract) private {
        KOTHPresale presale = KOTHPresale(payable(presaleContract));
        presale.setKOTH();
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "KOTH: sender must be a minter for minting");
        _;
    }

    modifier onlyGameMaster() {
        require(hasRole(GAME_MASTER_ROLE, _msgSender()), "KOTH: sender must be a game master");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "KOTH: sender must be a pauser");
        _;
    }

    function pause() public onlyPauser() {
        _pause();
    }

    function unpause() public onlyPauser() {
        _unpause();
    }

    function mint(address account, uint256 amount) public onlyMinter() {
        _mint(account, amount, "", "");
    }

    // Set game contract as default operator
    function addGameContract(address game) public onlyGameMaster() {
        require(game != address(0), "KOTH: game is zero address");
        require(defaultOperators().length == 0, "KOTH: game contract is already set");
        _addDefaultOperator(game);
    }

    // Unset game contract as default operator
    function removeGameContract(address game) public onlyGameMaster() {
        _removeDefaultOperator(game);
    }
}
