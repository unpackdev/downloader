import "./ERC20.sol";
import "./Ownable.sol";

//  _____ _              _     _         _____ _               _      
// /  __ \ |            | |   | |       /  __ \ |             (_)     
// | /  \/ |__   ___  __| | __| | __ _  | /  \/ | __ _ ___ ___ _  ___ 
// | |   | '_ \ / _ \/ _` |/ _` |/ _` | | |   | |/ _` / __/ __| |/ __|
// | \__/\ | | |  __/ (_| | (_| | (_| | | \__/\ | (_| \__ \__ \ | (__ 
//  \____/_| |_|\___|\__,_|\__,_|\__,_|  \____/_|\__,_|___/___/_|\___|
                                                                   
                                                                   

contract CheddaTokenClassic is ERC20, Ownable
{
    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    

    
    constructor() ERC20('Chedda Token Classic', 'CHEDDAC') 
    {
        // Exclude dev wallet from fees for testing
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
            
        _mint(msg.sender, 50_000_000_000 * 10 ** 18);
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {
        uint256 singleFee = (amount / 100);     //Calculate 1% fee
        uint256 totalFee = singleFee * 4;       //Calculate total fee (4%)
        uint256 newAmmount = amount - totalFee; //Calc new amount
        
        if(isExcludedFromFee(_msgSender()))
        {
            _transfer(_msgSender(), recipient, amount);
        }
        else
        {
            _burn(_msgSender(), totalFee);
            _transfer(_msgSender(), recipient, newAmmount);
        }
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        uint256 singleFee = (amount / 100);     //Calculate 1% fee
        uint256 totalFee = singleFee * 4;       //Calculate total fee (4%)
        uint256 newAmmount = amount - totalFee; //Calc new amount
		
		uint256 currentAllowance = allowance(sender,_msgSender());
		
		if (currentAllowance != type(uint256).max) 
		{
			require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
			
			unchecked
			{
				_approve(sender, _msgSender(), currentAllowance - amount);
			}
		}
        
        if(isExcludedFromFee(_msgSender()))
        {
            _transfer(sender, recipient, amount);
        }
        else
        {
            _burn(sender, totalFee);
            _transfer(sender, recipient, newAmmount);
        }
        
        return true;
    }
    
    function isExcluded(address account) public view returns (bool) 
    {
        return _isExcluded[account];
    }

    function setExcludeFromFee(address account, bool excluded) external onlyOwner() 
    {
        _isExcludedFromFee[account] = excluded;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) 
    {
        return _isExcludedFromFee[account];
    }
}