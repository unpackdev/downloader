// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/core/IPool.sol

pragma solidity >=0.4.21 <0.6.0;

contract IUSDCPool{
  function deposit(uint256 _amount) public;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);
}

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;

contract TransferableToken{
    function balanceOf(address _owner) public returns (uint256 balance) ;
    function transfer(address _to, uint256 _amount) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) ;
}


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        TransferableToken token = TransferableToken(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/core/pool/CompoundPool.sol

pragma solidity >=0.4.21 <0.6.0;





contract CurveInterface{
  function add_liquidity(uint256[2] memory uamounts, uint256 min_mint_amount) public;
  function remove_liquidity(uint256 _amount, uint256[2] memory min_uamounts) public;
  function remove_liquidity_imbalance(uint256[2] memory uamounts, uint256 max_burn_amount) public;

  address public curve;
}
contract PriceInterface{
  function get_virtual_price() public view returns(uint256);
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
}

contract CRVGaugeInterface{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
}

contract MinterInterface{
  function mint(address gauge_addr) public;
}

contract CompoundPool is IUSDCPool, TokenClaimer, Ownable{
  address public crv_token_addr;
  address public lp_token_addr;

  CRVGaugeInterface public crv_gauge_addr;
  MinterInterface public crv_minter_addr;
  CurveInterface public pool_deposit;

  address public usdc;
  address public dai;
  address public cusdc;
  address public cdai;

  constructor() public{
    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    lp_token_addr = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    crv_gauge_addr = CRVGaugeInterface(0x7ca5b0a2910B33e9759DC7dDB0413949071D7575);
    crv_minter_addr = MinterInterface(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    pool_deposit = CurveInterface(0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06);

    usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    cusdc = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    cdai = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
  }

  function deposit(uint256 _amount) public{
    deposit_usdc(_amount);
    deposit_to_gauge();
  }
  function deposit_usdc(uint256 _amount) public{
    uint256[2] memory uamounts = [uint256(0), _amount];
    pool_deposit.add_liquidity(uamounts, 0);
  }

  function deposit_to_gauge() public{
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), 0);
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), get_lp_token_balance());
    crv_gauge_addr.deposit(get_lp_token_balance());
  }


  function withdraw(uint256 _amount) public{
    withdraw_from_gauge(_amount);
    withdraw_from_curve(_amount);
  }

  function withdraw_from_gauge(uint256 _amount) public{
    crv_gauge_addr.withdraw(_amount);
  }

  function withdraw_from_curve(uint256 _amount) public{
    //pool_deposit.remove_liquidity(get_lp_token_balance(), [uint256(0), 0]);
    require(_amount <= get_lp_token_balance(), "too large amount");
    pool_deposit.remove_liquidity(_amount, [uint256(0), 0]);
    uint256 dai_amout = IERC20(dai).balanceOf(address(this));
    PriceInterface(pool_deposit.curve()).exchange_underlying(0, 1, dai_amout, 0);
  }

  function get_virtual_price() public view returns(uint256){
    return PriceInterface(pool_deposit.curve()).get_virtual_price();
  }

  function get_lp_token_balance() public view returns(uint256){
    return IERC20(lp_token_addr).balanceOf(address(this));
  }

  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }

  function earn_crv() public{
    crv_minter_addr.mint(address(crv_gauge_addr));
  }

  function claimStdToken(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }
}