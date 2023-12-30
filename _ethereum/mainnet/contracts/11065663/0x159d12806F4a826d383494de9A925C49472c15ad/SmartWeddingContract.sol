pragma solidity ^0.4.24;


contract SmartWeddingContract {
  event WrittenContractProposed(uint timestamp, string ipfsHash, address wallet);
  event Signed(uint timestamp, address wallet);
  event ContractSigned(uint timestamp);
  event DivorceApproved(uint timestamp, address wallet);
  event Divorced(uint timestamp);
  event FundsSent(uint timestamp, address wallet, uint amount);
  event FundsReceived(uint timestamp, address wallet, uint amount);
  event WeddingCreated(uint timestamp, address husbandAddress, string husbandFullName, address wifeAddress, string wifeFullName, string weddingDate);

  bool public signed = false;
  bool public divorced = false;

  mapping (address => bool) private hasSigned;
  mapping (address => bool) private hasDivorced;

  address public husbandAddress;
  string public husbandFullName;
  
  address public wifeAddress;
  string public wifeFullName;
  
  string public weddingDate;
  string public writtenContractIpfsHash;



  /**
   * @dev Modifier that only allows spouse execution.
    */
  modifier onlySpouse() {
    require(msg.sender == husbandAddress || msg.sender == wifeAddress, "Sender is not a spouse!");
    _;
  }

  /**
   * @dev Modifier that checks if the contract has been signed by both spouses.
    */
  modifier isSigned() {
    require(signed == true, "Contract has not been signed by both spouses yet!");
    _;
  }

  /**
   * @dev Modifier that only allows execution if the spouses have not been divorced.
    */
  modifier isNotDivorced() {
    require(divorced == false, "Can not be called after spouses agreed to divorce!");
    _;
  }

  /**
   * @dev Private helper function to check if a string is not equal to another.
   */
  function isNotSameString(string memory string1, string memory string2) private pure returns (bool) {
    return keccak256(abi.encodePacked(string1)) != keccak256(abi.encodePacked(string2));
  }

  /**
   * @dev Constructor: Set the wallet addresses of both spouses.
   * @param _husbandAddress Wallet address of the husband.
   * @param _wifeAddress Wallet address of the wife.
   */
  constructor(address _husbandAddress, string _husbandFullName, address _wifeAddress, string _wifeFullName, string _weddingDate) public {
    require(_husbandAddress != address(0), "Husband address must not be zero!");
    require(_wifeAddress != address(0), "Wife address must not be zero!");
    require(_husbandAddress != _wifeAddress, "Husband address must not equal wife address!");

    husbandAddress = _husbandAddress;
    husbandFullName = _husbandFullName;
    wifeAddress = _wifeAddress;
    wifeFullName = _wifeFullName;
    weddingDate = _weddingDate;
    emit WeddingCreated(now, _husbandAddress, _husbandFullName, _wifeAddress, _wifeFullName, _weddingDate);
  }

  /**
   * @dev Default function to enable the contract to receive funds.
    */
  function() external payable isSigned isNotDivorced {
    emit FundsReceived(now, msg.sender, msg.value);
  }

  /**
   * @dev Propose a written contract (update).
   * @param _writtenContractIpfsHash IPFS hash of the written contract PDF.
   */
  function proposeWrittenContract(string _writtenContractIpfsHash) external onlySpouse isNotDivorced {
    require(signed == false, "Written contract ipfs hash can not be changed. Both spouses have already signed it!");

    // Update written contract ipfs hash
    writtenContractIpfsHash = _writtenContractIpfsHash;

    emit WrittenContractProposed(now, _writtenContractIpfsHash, msg.sender);

    // Revoke previous signatures
    if (hasSigned[husbandAddress] == true) {
      hasSigned[husbandAddress] = false;
    }
    if (hasSigned[wifeAddress] == true) {
      hasSigned[wifeAddress] = false;
    }
  }

  /**
   * @dev Sign the contract.
   */
  function signContract() external onlySpouse {
    require(isNotSameString(writtenContractIpfsHash, ""), "Written contract ipfs hash has been proposed yet!");
    require(hasSigned[msg.sender] == false, "Spouse has already signed the contract!");

    // Sender signed
    hasSigned[msg.sender] = true;

    emit Signed(now, msg.sender);

    // Check if both spouses have signed
    if (hasSigned[husbandAddress] && hasSigned[wifeAddress]) {
      signed = true;
      emit ContractSigned(now);
    }
  }

  /**
   * @dev Send ETH to a target address.
   * @param _to Destination wallet address.
   * @param _amount Amount of ETH to send.
   */
  function pay(address _to, uint _amount) external onlySpouse isSigned isNotDivorced {
    require(_to != address(0), "Sending funds to address zero is prohibited!");
    require(_amount <= address(this).balance, "Not enough balance available!");

    // Send funds to the destination address
    _to.transfer(_amount);

    emit FundsSent(now, _to, _amount);
  }

 

  /**
   * @dev Request to divorce. The other spouse needs to approve this action.
   */
  function divorce() external onlySpouse isSigned isNotDivorced {
    require(hasDivorced[msg.sender] == false, "Sender has already approved to divorce!");

    // Sender approved
    hasDivorced[msg.sender] = true;

    emit DivorceApproved(now, msg.sender);

    // Check if both spouses have approved to divorce
    if (hasDivorced[husbandAddress] && hasDivorced[wifeAddress]) {
      divorced = true;
      emit Divorced(now);

      // Get the contracts balance
      uint balance = address(this).balance;

      // Split the remaining balance half-half
      if (balance != 0) {
        // Ignore any remainder due to low value
        uint balancePerSpouse = balance / 2;

        // Send transfer to the husband
        husbandAddress.transfer(balancePerSpouse);
        emit FundsSent(now, husbandAddress, balancePerSpouse);

        // Send transfer to the wife
        wifeAddress.transfer(balancePerSpouse);
        emit FundsSent(now, wifeAddress, balancePerSpouse);
      }
    }
  }

}