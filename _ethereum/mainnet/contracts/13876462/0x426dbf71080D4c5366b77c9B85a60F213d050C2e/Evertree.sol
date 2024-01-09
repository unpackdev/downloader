// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract Evertree is  Initializable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PausableUpgradeable,
    ReentrancyGuardUpgradeable {

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // @notice _name is the name of the token (EVERTREE), non upgradeable shall be set in the initializer
    string private _name;

    // @notice _symbol is the symbol (ETRE) of the token, non upgradeable shall be set in the initializer
    string private _symbol;

    // @notice _cap is the amount of ETRE that will be able to be minted forever (240M)
    uint256 private _cap;

    // @notice _totalSupply is the amount of ETRE minted / available, the supply will increase progressively until the _cap is reached
    uint256 private _totalSupply;

  

    // @notice the owner of the contract (the account used to deploy it, not the same as operator)
    address public _owner;

    address payable public ceo;
    address payable public cfo;
    address payable public cto;
    address public business;
    address public charity;
    uint8 public _decimals;

    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

  
       // _authorizeUpgrade of the token only from the owner of the contract (UUPSProxy interface implementation)
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // initialize is the initialization function of the contract to enable the upgradeable behaviour via the UUPS Proxy

    function initialize(
        address owner_,
        uint256 cap_,
        uint256 totalSupply_
    ) public initializer {
        
        _name = "EVERTREE";
        _symbol = "ETRE";

        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __ERC20Pausable_init_unchained();
        __UUPSUpgradeable_init();

        _decimals = 18;

        _owner = owner_;
        _cap = cap_ * 10 ** decimals();
        
        ceo = payable(0x77DaD28f302EBD245f15480Be38037197cC4135d);
        cfo = payable(0x479D80a319df59814Fa45e08817798ff96273607);
        cto = payable(0x2264D2D5E550A5521681fB093aaCE0Ff73C22C41);
      
        _totalSupply = totalSupply_ * 10 ** decimals();
        mint(_owner, _totalSupply);

        cLevelBalance(ceo, 1920000 * 10 ** decimals());
        cLevelBalance(cto, 1920000 * 10 ** decimals());
        cLevelBalance(cfo, 1920000 * 10 ** decimals());
        
    }

    modifier onlyOwnerOrCTO() {
      require(msg.sender == _owner || msg.sender == cto);
      _;
    }

    modifier capNotReached(uint256 amount) {
              require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
              _;

    }

    function mint(address to, uint256 amount) private capNotReached(amount) onlyOwnerOrCTO {
        super._mint(to, amount);
        emit Mint(msg.sender, to, amount);
    }

    function cLevelBalance(address payable acct, uint256 amount) private capNotReached(amount) onlyOwnerOrCTO {
        _transfer(_owner, acct, amount);
    }

    function cap() public view virtual returns(uint256) {
      return _cap;
    }

    event Mint(address indexed from, address indexed to, uint256 amount);

  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

}
