pragma solidity 0.6.12;
import "./Storage.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Address.sol";

contract CrimeGold is Initializable, ERC20Upgradeable, PausableUpgradeable {
  mapping(address => bool) private _isExcludedFromBurn;

  address public pancakePair;
  uint256 public _burnRatePercent;
  uint256 public _timestampWhenCanMintForReward;
  uint256 constant public _mintForRewardFreezeTime = 30 days;

  using SafeMathUpgradeable for uint256;

  mapping(address => bool) public _isIncludeAddressPairBurn;

  function initialize(Storage _storage) public initializer {
    __ERC20_init("CrimeGold", "CRIME");
    __Pausable_init(_storage);

    _burnRatePercent = 25;

    _isExcludedFromBurn[_msgSender()] = true;
    _isExcludedFromBurn[0x60281456944D1E42A601214a605DCf02C7EAc429] = true;
    _isExcludedFromBurn[0xfE61Be7BeAfC8Cbf6b40FE6312386162D9060513] = true;
    _isExcludedFromBurn[0xeB85a89e2F6d92a5DE1bdEc6AB71B074872e8477] = true;
    _isExcludedFromBurn[0xb7ECbff34A8df061ffE6Aae773454E2F894ff899] = true;
    _isExcludedFromBurn[0x5d2A6763D4C30890A914b5fa0581D145d6766450] = true;
    _isExcludedFromBurn[0x1A380cA88E1Cc21d8e5FA4e1403a2A8E2B62Ef93] = true;
    _isExcludedFromBurn[0xf5914A534237f2FDB401f337253553217dB99178] = true;
    _isExcludedFromBurn[0xb4D0A3e93a0742d8BCdFe51E6b73a88Cac035EA5] = true;
    _isExcludedFromBurn[0xd6F5190D0087b7B17a95BbE0BbDE3213AB796472] = true;
    _isExcludedFromBurn[0x121dc3C640d80c223cd7708948029EA3d2741923] = true;
    _isExcludedFromBurn[0xC5C89c96C938a8A56B1Ab5C49aa586d928b33540] = true;
    _isExcludedFromBurn[0x57055bFDCD3361739d5c206eC6C4e51d476f5960] = true;
    _isExcludedFromBurn[0x7C55A1B92C3F563046f50369f0b6863C3fFC88D7] = true;
    _isExcludedFromBurn[0x5a59838Ba26B53f67b0511980038CC4613eAa89d] = true;
    _isExcludedFromBurn[0x8aA52F8d845f4339400d6c6Ee7D48e8934Cb2447] = true;
    _isExcludedFromBurn[0x3e49Fe36d12ec9859a7ED806B948a2F0d04b08d5] = true;
    _isExcludedFromBurn[0xC67343ceeb2aE96CEcA6bE38eAe10087FA5bDd29] = true;
    _isExcludedFromBurn[0x7E4BDE53491530A8302e9D6bCF57FfC207a532bA] = true;
    _isExcludedFromBurn[0x89bF06a1e66615456FafA529A5D05411D735F04a] = true;
    _isExcludedFromBurn[0x99BeF93074F3d91762615ce0aAD960d65d2037f1] = true;

    _mint(msg.sender, 800 * 10 ** 18);
    _pause();
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function transfer(address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint256 burnedAmount;

    if((pancakePair == recipient || _isIncludeAddressPairBurn[recipient]) && !_isExcludedFromBurn[sender]) { 
      burnedAmount = amount.mul(_burnRatePercent).div(10**2);
      _burn(sender, burnedAmount);
    }

    super._transfer(sender, recipient, amount.sub(burnedAmount));
  }

  function setAddressPairBurn(address _address, bool _isInclude) external {
    onlyOwner();
    _isIncludeAddressPairBurn[_address] = _isInclude;
  }

  function pause() external whenNotPaused {
    onlyOwner();
    _pause();
  }

  function unpause() external whenPaused {
    onlyOwner();
    _unpause();
  }

  function mintForReward(
    address crimeCashGameAddress,
    uint256 amountOfTokensForCrimeCashGame, 
    address devAddress,
    uint256 amountOfTokensForDev, 
    address advertisementAddress,
    uint256 amountOfTokensForAdvertisement) external whenNotPaused {
    onlyOwner();
    _isContract(crimeCashGameAddress);
    _canMintForReward();

    _timestampWhenCanMintForReward = block.timestamp.add(_mintForRewardFreezeTime);
    
    _mint(crimeCashGameAddress, amountOfTokensForCrimeCashGame);
    _mint(devAddress, amountOfTokensForDev);
    _mint(advertisementAddress, amountOfTokensForAdvertisement);
  }

  function _isContract(address addr) internal view {
    require(Address.isContract(addr), "ERC20: crimeCashGameAddress is non contract address");
  }

  function _canMintForReward() internal view {
    require(block.timestamp >= _timestampWhenCanMintForReward, "ERC20: freeze time mintForReward()");
  }

  function setAddressExcludedFromBurn(address addr, bool isExcluded) external{
    onlyOwner();
    _isExcludedFromBurn[addr] = isExcluded;
  }
}
