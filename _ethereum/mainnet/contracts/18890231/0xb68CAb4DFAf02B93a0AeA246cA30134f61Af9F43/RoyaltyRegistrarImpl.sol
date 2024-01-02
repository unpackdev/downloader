// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RoyaltyRegistrar.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IContract {
    function owner() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract RoyaltyToken is ERC20 {
    address payable registrar;
    address currency;
    address hostContract;
    constructor(string memory name, string memory symbol, address to, uint256 amount, address payable _registrar, address _currency, address _hostContract) ERC20(name, symbol) {
      _mint(to, amount);
      registrar = _registrar;
      currency = _currency;
      hostContract = _hostContract;
    }

    /**
    * @dev Transfer registrar state for the token as well
    * @param from Address sending the tokens.
    * @param to Address receiving the tokens.
    * @param amount Number of tokens being transferred.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0) && to != address(0)) {
            RoyaltyRegistrarImpl registrarImpl = RoyaltyRegistrarImpl(registrar);
            // Transfer state along with tokens.
            registrarImpl.updateWithdrawn(hostContract, from, to, amount, currency);
        }
    }
}

contract RoyaltyRegistrarImpl is RoyaltyRegistrar, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  address public seaport;
  mapping(address=>address) claimed;
  mapping(address => bool) private authorizedTokens;
  mapping(address=>uint256) percentages;
  mapping(address=>mapping(address => address)) hostContractToRoyaltyTokens;
  mapping(address => mapping(address => uint256)) royaltyBalances;
  mapping(address => mapping(address => mapping(address => uint256))) withdrawn;
  uint256 public constant MAX_PERCENTAGE = 10 ** 20;
  uint256 public constant MAX_TOKEN_SUPPLY = 10 ** 18;

  /**
    * @dev Creates a new ERC20 token.
    * @param _name Name of the new ERC20 token.
    * @param _symbol Symbol of the new ERC20 token.
    * @param _owner Address to mint the initial supply to.
    * @param _currency Address of the currency being used.
    * @param _hostContract Address of the host contract.
    * @return Address of the newly created ERC20 token.
    */
  function createERC20(
    string memory _name,
    string memory _symbol,
    address _owner,
    address _currency,
    address _hostContract
  ) internal returns (address) {
    ERC20 newToken = new RoyaltyToken(_name, _symbol, _owner, MAX_TOKEN_SUPPLY, payable(address(this)), _currency, _hostContract);
    authorizedTokens[address(newToken)] = true;
    return address(newToken);
  }

  modifier onlyAuthorizedTokens() {
    require(authorizedTokens[msg.sender], "Only authorized tokens can call this function");
    _;
  }

  /**
    * @dev Updates the state for tokens transferred.
    * @param hostContract Address of the host contract.
    * @param sender Address sending the tokens.
    * @param recipient Address receiving the tokens.
    * @param amount Number of tokens being transferred.
    * @param currency Address of the currency being used.
    */
  function updateWithdrawn(address hostContract, address sender, address recipient, uint256 amount, address currency) external onlyAuthorizedTokens {
    uint256 senderBalance = IERC20(hostContractToRoyaltyTokens[hostContract][currency]).balanceOf(sender);
    uint256 senderWithdrawn = withdrawn[hostContract][currency][sender];
    uint256 recipientWithdrawn = withdrawn[hostContract][currency][recipient];

    uint256 transferredWithdrawn = (senderWithdrawn * amount + (senderBalance - 1)) / senderBalance;

    withdrawn[hostContract][currency][sender] = senderWithdrawn - transferredWithdrawn;
    withdrawn[hostContract][currency][recipient] = recipientWithdrawn + transferredWithdrawn;
  }

   /**
    * @dev Sets the seaport address.
    * @param _seaport New seaport address.
    */
  function setSeaport(address _seaport) external onlyOwner {
    require(seaport == address(0), "Already set");
    seaport = _seaport;
  }

  /**
    * @dev Claims royalties for a host contract.
    * @param _hostContract Address of the host contract.
    * @param _percentage Royalty percentage being claimed.
    */
  function claimRoyalty(address _hostContract, uint256 _percentage) external virtual override {
    require(claimed[_hostContract] == address(0), "Token already claimed.");
    require(_percentage <= MAX_PERCENTAGE, "Maximum royalty is 100%");
    IContract hostContract = IContract(_hostContract);
    require(hostContract.owner() == msg.sender, "Only the owner of a contract can claim royalty proceeds.");
    address token = createERC20("Royalty Token", "RT", msg.sender, address(0), _hostContract);
    percentages[_hostContract] = _percentage;
    claimed[_hostContract] = msg.sender;
    hostContractToRoyaltyTokens[_hostContract][address(0)] = token;
    emit RoyaltyClaimed(_hostContract, address(0), msg.sender, _percentage, token);
  }

    /**
    * @dev Claims royalties for a host contract.
    * @param _hostContract Address of the host contract.
    * @param _percentage Royalty percentage being claimed.
    */
    function claimRoyaltyForRevoked(address _hostContract, uint256 _percentage, address recipient) external virtual onlyOwner override {
      require(claimed[_hostContract] == address(0), "Token already claimed.");
      require(_percentage <= MAX_PERCENTAGE, "Maximum royalty is 100%");
      require(recipient != address(0), "Zero address");
      IContract hostContract = IContract(_hostContract);
      address token = createERC20("Royalty Token", "RT", recipient, address(0), _hostContract);
      percentages[_hostContract] = _percentage;
      claimed[_hostContract] = recipient;
      hostContractToRoyaltyTokens[_hostContract][address(0)] = token;
      emit RoyaltyClaimed(_hostContract, address(0), recipient, _percentage, token);
    }

  /**
    * @dev Mints a new RoyaltyToken for the provided host contract and currency.
    * @param _hostContract Address of the host contract.
    * @param currency Address of the currency.
    */
  function mintRoyaltyToken(address _hostContract, address currency) external virtual override {
    require(claimed[_hostContract] != address(0), "Token not claimed.");
    require(msg.sender == claimed[_hostContract], "Not owner.");
    require(hostContractToRoyaltyTokens[_hostContract][currency] == address(0), "Royalty token minted");
    address token = createERC20("Royalty Token", "RT", claimed[_hostContract], currency, _hostContract);
    hostContractToRoyaltyTokens[_hostContract][currency] = token;
    emit RoyaltyClaimed(_hostContract, currency, msg.sender, percentages[_hostContract], token);
  }

  /**
  * @dev Splits the royalty token among multiple addresses based on provided weights.
  * @param _hostContract Address of the host contract.
  * @param currency Address of the currency.
  * @param addresses List of addresses to split the royalty token among.
  * @param weights List of weights corresponding to how much each address receives.
  */
  function split(address _hostContract, address currency, address[] calldata addresses, uint256[] calldata weights) external virtual override {
    require(addresses.length == weights.length, "Arrays length mismatch");

    address token = hostContractToRoyaltyTokens[_hostContract][currency];
    uint256 totalAmount = IERC20(token).balanceOf(msg.sender);
    uint256 remainingAmount = totalAmount;
    uint256 amount;

    for (uint256 i = 0; i < addresses.length; i++) {
        amount = totalAmount * weights[i] / 1e20;
        remainingAmount = remainingAmount - amount;
        require(remainingAmount <= totalAmount, "Integer overflow");
        IERC20(token).safeTransferFrom(msg.sender, addresses[i], amount);
    }

    emit RoyaltySplit(_hostContract, currency, addresses, weights);
  }

  function getWithdrawn(address hostContract, address currency) external view override returns(uint256) {
    return withdrawn[hostContract][currency][msg.sender];
  }

  function getWithdrawn(address[] calldata hostContracts, address[] calldata currencies) external view override returns(uint256[] memory) {
    require (hostContracts.length == currencies.length, "Different length input");
    require(hostContracts.length != 0, "Zero length");
    uint256[] memory res = new uint256[](hostContracts.length);
    for (uint256 i = 0; i < hostContracts.length;) {
      res[i] = withdrawn[hostContracts[i]][currencies[i]][msg.sender];
      unchecked {
        ++i;
      }
    }
    return res;
  }

  function getRoyaltyBalance(address hostContract, address currency) external view override returns(uint256) {
    return royaltyBalances[hostContract][currency];
  }

  function getRoyaltyBalance(address[] calldata hostContracts, address[] calldata currencies) external view override returns(uint256[] memory) {
    require (hostContracts.length == currencies.length, "Different length input");
    require(hostContracts.length != 0, "Zero length");
    uint256[] memory res = new uint256[](hostContracts.length);
    for (uint256 i = 0; i < hostContracts.length;) {
      res[i] = royaltyBalances[hostContracts[i]][currencies[i]];

      unchecked {
        ++i;
      }
    }
    return res;
  }

  function getClaimed(address hostContract) external view override returns(address) {
    return claimed[hostContract];
  }

  function getHostContractRoyaltyToken(address hostContract, address currency) external view override returns(address) {
    return hostContractToRoyaltyTokens[hostContract][currency];
  }

  /**
    * @dev Withdraws royalties.
    * @param recipient Address to receive the withdrawn royalties.
    * @param hostContract Address of the host contract.
    * @param currency Address of the currency being used.
    */
  function withdraw(address recipient, address hostContract, address currency) nonReentrant external override {
    // Get the address of the ERC20 token contract that represents the royalties for the given collection and currency.
    address royaltyTokenAddress = hostContractToRoyaltyTokens[hostContract][currency];

    // Get the total amount of royalties that have been deposited for the collection and currency.
    uint256 totalRoyalties = royaltyBalances[hostContract][currency];

    uint256 ownerBalance = IERC20(royaltyTokenAddress).balanceOf(recipient);
    uint256 amountWithdrawn = withdrawn[hostContract][currency][recipient];

    // Calculate the amount of royalties that the caller can withdraw based on their ERC20 token balance and subtract the amount they have already withdrawn.
    uint256 availableRoyalties = totalRoyalties * ownerBalance / MAX_TOKEN_SUPPLY - amountWithdrawn;
    require(availableRoyalties > 0, "No royalties available for withdrawal.");

    // Update state
    withdrawn[hostContract][currency][recipient] = withdrawn[hostContract][currency][recipient] + availableRoyalties;

    // Transfer
    if (currency == address(0)) {
        (bool success,) = recipient.call{value: availableRoyalties}("");
        require(success, "Transfer failed");
    } else {
        IERC20(currency).safeTransfer(recipient, availableRoyalties);
    }

    emit Withdraw(recipient, hostContract, currency, availableRoyalties);
  }

  function updateRoyalties(address hostContract, address currency, uint256 amount) external override {
    require(msg.sender == seaport, "Seaport only");
    require(hostContractToRoyaltyTokens[hostContract][currency] != address(0), "Royalty token not found");
    royaltyBalances[hostContract][currency] += amount;
    emit RoyaltiesUpdated(hostContract, currency, amount);
  }

  function depositRoyalties(address hostContract, address currency, uint256 amount) nonReentrant external override payable {
      require(hostContractToRoyaltyTokens[hostContract][currency] != address(0), "Royalty token not found");

      if (currency != address(0)) {
          IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
      } else {
        require(msg.value == amount, "Insufficient funds");
      }

      royaltyBalances[hostContract][currency] += amount;
      emit RoyaltiesDeposited(hostContract, currency, amount);
  }

  /**
    * @dev Sets the royalty percentage for a host contract.
    * @param _hostContract Address of the host contract.
    * @param _newPercentage New royalty percentage.
    */
  function setPercentage(address _hostContract, uint256 _newPercentage) external virtual override {
    require(_newPercentage <= MAX_PERCENTAGE, "Maximum royalty is 100%");
    address royaltyToken = hostContractToRoyaltyTokens[_hostContract][address(0)];
    uint256 totalSupply = IERC20(royaltyToken).totalSupply();
    uint256 callerBalance = IERC20(royaltyToken).balanceOf(msg.sender);
    require(callerBalance > totalSupply / 2, "Caller does not own a majority of the token supply");
    require(_newPercentage <= percentages[_hostContract], "New royalty cannot be more than current royalty");

    percentages[_hostContract] = _newPercentage;
    emit NewPercentage(_hostContract, _newPercentage);
  }

  function getRoyaltyPercentage(address _hostContract) external view override returns (uint256) {
    return percentages[_hostContract];
  }

  /**
    * @dev External function to allow the contract to receive ether.
    */
  receive() external payable { }
}