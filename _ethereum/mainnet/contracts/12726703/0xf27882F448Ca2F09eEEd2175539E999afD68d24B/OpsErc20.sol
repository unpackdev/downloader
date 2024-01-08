pragma solidity 0.6.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";


contract OpsErc20  is ERC20, Ownable{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    string  private constant  TOKEN_NAME     = "Ops";
    string  private constant TOKEN_SYMBOL   = "OPS";
    uint8 private constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 5000000 * (10 ** uint256(DECIMALS));
    uint256 public constant INITIAL_CAP = 100000000 * (10 ** uint256(DECIMALS));
    uint256 private _cap;

    constructor()
     ERC20(TOKEN_NAME,TOKEN_SYMBOL)public { 
            require(INITIAL_SUPPLY <= INITIAL_CAP);

            _mint(_msgSender(), INITIAL_SUPPLY);

            _cap = INITIAL_CAP;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public  {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public  {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    function mint(address account, uint256 amount) public onlyMinter   {
        require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), " _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "_delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

 
}