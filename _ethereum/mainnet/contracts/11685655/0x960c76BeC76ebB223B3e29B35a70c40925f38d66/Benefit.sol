pragma solidity ^0.4.24;// SPDX-License-Identifier: MIT



//True POZ Token will have this, 
interface IPOZBenefit {
    function IsPOZHolder(address _Subject) external view returns(bool);
}// stakeOf(address account) public view returns (uint256)
// SPDX-License-Identifier: MIT



interface IStaking {
    function stakeOf(address account) public view returns (uint256) ;
}/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}// SPDX-License-Identifier: MIT







contract Benefit is IPOZBenefit, Ownable {
    constructor() public {
        MinHold = 1;
        IsToken = true;
    }

    bool public IsToken;
    address public TokenAddress;
    address public POZBenefit_Address;
    uint256 public MinHold;

    function SetMinHold (uint256 _MinHold) public onlyOwner {
        require(_MinHold>0,'Must be more then 0');
        MinHold = _MinHold;
    }

    function SwapIsToken() public onlyOwner {
        IsToken = !IsToken;
    }

    function SetTokenAddress(address _New_Address) public onlyOwner {
        TokenAddress = _New_Address;
    }

    function SetPOZBenefitAddress(address _New_Address) public onlyOwner {
        POZBenefit_Address = _New_Address;
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function CheckStaking(address _Subject) internal view returns (uint256)
    {
       return IStaking(TokenAddress).stakeOf(_Subject);
    }

    function IsPOZHolder(address _Subject) external view returns (bool) {
        return IsPOZInvestor(_Subject);
    }

    function IsPOZInvestor(address _investor) internal view returns (bool) {
        if (TokenAddress == address(0x0) && POZBenefit_Address == address(0x0))
            return false; // Last file in line, no change result
        return ((TokenAddress != address(0x0) &&
           (IsToken? CheckBalance(TokenAddress, _investor) :CheckStaking(_investor)) >= MinHold) ||
            (POZBenefit_Address != address(0x0) &&
                IPOZBenefit(POZBenefit_Address).IsPOZHolder(_investor)));
    }
}