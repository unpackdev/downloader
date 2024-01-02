/*
   ________          _       ______           __                  
  / ____/ /_  ____ _(_)___  / ____/___ ______/ /_____  _______  __
 / /   / __ \/ __ `/ / __ \/ /_  / __ `/ ___/ __/ __ \/ ___/ / / /
/ /___/ / / / /_/ / / / / / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ / 
\____/_/ /_/\__,_/_/_/ /_/_/    \__,_/\___/\__/\____/_/   \__, /  
                                                         /____/   
  ChainFactory Smart-Contract

  Web:      https://chainfactory.app/
  X:        https://x.com/ChainFactoryApp
  Telegram: https://t.me/ChainFactory
  Discord:  https://discord.gg/fpjxD39v3k
  YouTube:  https://youtube.com/@UpfrontDeFi

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library Create2 {
  function predictAddress(bytes memory bytecode, bytes32 salt) internal view returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

    return address(uint160(uint256(hash)));
  }

  function deploy(bytes memory bytecode, bytes32 salt) internal returns (address result) {
    assembly {
      result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }

    require(result != address(0), "Deploy failed");
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IMultiSignatureWallet {
  function listManagers(bool) external view returns (address[] memory);
}

interface IStake {
  function stakedAmount(address account) external view returns (uint256);
}

abstract contract CF_Ownable {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() virtual {
    require(_owner == msg.sender, "Unauthorized");

    _;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));

    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract CF_Common {
  string internal constant _version = "1.0.0";
  IERC20 internal FACTORY_TOKEN;
  IStake internal FACTORY_STAKE;
  address internal MULTISIGN_ADDRESS;
  address internal TREASURY_ADDRESS;
  address[] internal _userList;
  uint256[] internal _templateList;
  uint24 internal constant denominator = 1000;
  bool internal _locked;
  bool internal _initialized;

  mapping(address => userData) internal _userData;
  mapping(uint8 => discountLevel) internal _discountLevel;
  mapping(uint256 => templateData) internal _templateData;

  struct templateData {
    bool exists;
    bool active;
    bool discountable;
    mapping(uint256 => uint256) price;
    uint256 features;
  }

  struct templateDataView {
    uint256 id;
    bool discountable;
    uint256 price;
    uint256[] features;
  }

  struct userData {
    bool exists;
    uint256 balance;
    mapping(address => deployData) deploy;
    address[] deployList;
    addedCreditData[] addedCredit;
    mapping(address => referredData) referred;
    address[] referredList;
  }

  struct userDataView {
    uint256 balance;
    deployView[] deploy;
    addedCreditData[] addedCredit;
    referredDataView[] referred;
  }

  struct addedCreditData {
    uint32 timestamp;
    uint256 amount;
    address origin;
  }

  struct deployData {
    bytes32 nonce;
    uint256 templateId;
    uint32 timestamp;
    uint256 price;
    uint256 amount;
    uint256 credit;
    uint256 discount;
    uint256 features;
  }

  struct deployView {
    address contractAddress;
    uint256 templateId;
    uint32 timestamp;
    uint256 price;
    uint256 amount;
    uint256 credit;
    uint256 discount;
    uint256 features;
    bytes32 nonce;
  }

  struct discountLevel {
    bool exists;
    uint24 percent;
    uint24 discount;
  }

  struct discountLevelView {
    uint8 level;
    uint24 percent;
    uint24 discount;
  }

  struct referredData {
    bool exists;
    uint256 deploys;
    uint256 amount;
  }

  struct referredDataView {
    address user;
    uint256 deploys;
    uint256 amount;
  }

  function _percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    unchecked {
      return (amount * bps) / (100 * uint256(denominator));
    }
  }

  function _timestamp() internal view returns (uint32) {
    unchecked {
      return uint32(block.timestamp % 2**32);
    }
  }

  function version() external pure returns (string memory) {
    return _version;
  }
}

contract ChainFactory is CF_Ownable, CF_Common {
  event Deposit(address indexed from, uint256 amount);
  event ContractDeployed(address indexed user, uint256 templateId, uint256 amount, address contractAddress);
  event AddedCredit(address indexed user, uint256 amount);
  event SetDiscountLevel(uint8 level, uint24 percent, uint24 discount);

  modifier nonReentrant() {
    require(!_locked, "No re-entrancy");

    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyOwner() virtual override {
    require(msg.sender == _owner || (MULTISIGN_ADDRESS != address(0) && msg.sender == MULTISIGN_ADDRESS), "Unauthorized");

    _;
  }

  modifier onlyManager() {
    require(MULTISIGN_ADDRESS != address(0));

    address[] memory managers = IMultiSignatureWallet(MULTISIGN_ADDRESS).listManagers(true);

    uint256 cnt = managers.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (managers[i] != msg.sender) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Not manager");

    _;
  }

  modifier isTemplate(uint256 templateId) {
    require(_templateData[templateId].exists && _templateData[templateId].active, "Unknown template");

    _;
  }

  function initialize() external {
    require(!_initialized);

    _transferOwnership(msg.sender);
    _initialized = true;
  }

  function setTemplate(uint256 templateId, bool active, bool discountable, uint256[] calldata price) external onlyOwner {
    uint256 cnt = price.length;

    require(cnt > 0 && cnt < 64);

    if (!_templateData[templateId].exists) {
      _templateData[templateId].exists = true;
      _templateList.push(templateId);
    }

    _templateData[templateId].active = active;
    _templateData[templateId].discountable = discountable;

    unchecked {
      _templateData[templateId].features = cnt - 1;

      for (uint256 f; f < cnt; f++) { _templateData[templateId].price[f] = price[f]; }
    }
  }

  function _addUser(address _addr) private {
    _userList.push(_addr);
    _userData[_addr].exists = true;
  }

  /// @notice Add credit to an user
  /// @param user Target address
  /// @param amount Credit to add
  function addCredit(address user, uint256 amount) external onlyOwner nonReentrant {
    require(amount > 0);
    require(_userData[user].exists, "Unknown user");

    unchecked {
      _userData[user].balance += amount;
      _userData[user].addedCredit.push(addedCreditData(_timestamp(), amount, msg.sender));

      emit AddedCredit(user, amount);
    }
  }

  /// @notice Add credit to your balance
  function addCredit() public payable nonReentrant {
    require(msg.value > 0);

    _addCredit(msg.sender, msg.value);
  }

  function _addCredit(address user, uint256 amount) private {
    if (!_userData[user].exists) { _addUser(user); }

    unchecked {
      _userData[user].balance += amount;
      _userData[user].addedCredit.push(addedCreditData(_timestamp(), amount, user));

      emit AddedCredit(user, amount);
    }

    if (amount > 0 && address(TREASURY_ADDRESS) != address(0)) {
      (bool success, ) = TREASURY_ADDRESS.call{ value: amount }("");

      require(success, "Transfer error");
    }
  }

  /// @notice Returns the price of a template based on the specified features
  /// @param templateId Identifier of the template
  /// @param features Bitmask of the desired features
  function getTemplatePrice(uint256 templateId, uint256 features) public view isTemplate(templateId) returns (uint256 price) {
    unchecked {
      price += _templateData[templateId].price[0];

      if (features == 0) { return price; }

      uint256 cnt = _templateData[templateId].features + 1;

      for (uint256 f; f < cnt; f++) {
        if ((features & 1 << f) == 0) { continue; }

        price += _templateData[templateId].price[f + 1];
      }
    }
  }

  /// @notice Pay and deploy a customized template with desired features
  /// @param templateId Identifier of the template
  /// @param features Bitmask of the desired features
  /// @param nonce Randomly generated and unique
  /// @param bytecode Compiled version of the Smart-Contract
  /// @param referral Affiliated address
  /// @dev This function must be used from an external front-end to update additional settings after the tx is completed or your code won't be verified
  /// @dev Use the zero address as referral for no affiliation
  function deployContract(uint256 templateId, uint256 features, bytes32 nonce, bytes memory bytecode, address referral) external payable isTemplate(templateId) nonReentrant returns (address contractAddress) {
    uint256 amount = msg.value;
    uint256 price = getTemplatePrice(templateId, features);
    uint256 discount = _percentage(uint256(price), uint256(_getDiscountPercent(msg.sender)));
    uint256 credit;
    uint256 refund;

    if (!_userData[msg.sender].exists) { _addUser(msg.sender); }

    unchecked {
      if (discount > 0) { price -= discount; }

      if (_userData[msg.sender].balance > 0) {
        credit = _userData[msg.sender].balance >= price ? price : _userData[msg.sender].balance;

        _userData[msg.sender].balance -= credit;
      }

      require(amount + credit >= price, "Underpayment");

      if (amount > price) {
        refund = (amount + credit) - price;
        amount -= refund;

        _addCredit(msg.sender, refund);
      }

      if (referral != address(0)) {
        require(referral != msg.sender, "Invalid referral");
        require(_userData[referral].exists, "Unknown referral address");

        if (!_userData[referral].referred[msg.sender].exists) {
          _userData[referral].referredList.push(msg.sender);
          _userData[referral].referred[msg.sender] = referredData(true, 0, 0);
        }

        ++_userData[referral].referred[msg.sender].deploys;
        _userData[referral].referred[msg.sender].amount += amount;
      }
    }

    if (amount > 0 && address(TREASURY_ADDRESS) != address(0)) {
      (bool success, ) = TREASURY_ADDRESS.call{ value: amount }("");

      require(success, "Transfer error");
    }

    address predictAddress = Create2.predictAddress(bytecode, nonce);
    require(!Address.isContract(predictAddress), "Already exists");

    contractAddress = Create2.deploy(bytecode, nonce);
    require(predictAddress == contractAddress, "Not the predicted one");

    _userData[msg.sender].deployList.push(contractAddress);
    _userData[msg.sender].deploy[contractAddress] = deployData(nonce, templateId, _timestamp(), price, amount, credit, discount, features);

    emit ContractDeployed(msg.sender, templateId, amount, contractAddress);
  }

  /// @notice List of available templates
  function listTemplates() public view returns (templateDataView[] memory data) {
    uint256 cnt = _templateList.length;
    uint256 len = _countActiveTemplates();
    uint256 i;

    data = new templateDataView[](len);

    unchecked {
      for (uint256 t; t < cnt; t++) {
        uint256 templateId = _templateList[t];

        if (!_templateData[templateId].active) { continue; }

        uint256 fcnt = _templateData[templateId].features;
        uint256[] memory features = new uint256[](fcnt);

        for (uint256 f = 1; f - 1 < fcnt; f++) { features[uint256(f - 1)] = uint256(_templateData[templateId].price[f]); }

        data[i++] = templateDataView(templateId, _templateData[templateId].discountable, _templateData[templateId].price[0], features);
      }
    }
  }

  /// @notice List of existent users
  function listUsers() external view returns (address[] memory data) {
    uint256 cnt = _userList.length;
    uint256 i;

    data = new address[](cnt);

    unchecked {
      for (uint256 u; u < cnt; u++) { data[i++] = _userList[u]; }
    }
  }

  /// @notice Details of a specific user
  /// @param account User address
  function getUserInfo(address account) external view returns (userDataView memory user) {
    require(_userData[account].exists, "Unknown user");

    uint256 cnt = _userData[account].deployList.length;

    user.balance = _userData[account].balance;
    user.deploy = new deployView[](cnt);
    user.addedCredit = _userData[account].addedCredit;

    unchecked {
      for (uint256 d; d < cnt; d++) {
        address contractAddress = _userData[account].deployList[d];
        deployData memory deploy = _userData[account].deploy[contractAddress];

        user.deploy[d] = deployView(contractAddress, deploy.templateId, deploy.timestamp, deploy.price, deploy.amount, deploy.credit, deploy.discount, deploy.features, deploy.nonce);
      }
    }
  }

  /// @notice List of available discounts
  /// @custom:return `list[].level` Assigned slot level
  /// @custom:return `list[].percent` Threshold for eligibility based on the percentage of tokens you own (balance or staked) of total supply
  /// @custom:return `list[].discount` Discount to apply
  function listDiscountLevels() external view returns (discountLevelView[] memory list) {
    list = new discountLevelView[](5);

    unchecked {
      for (uint8 i; i < 5; i++) { list[i] = discountLevelView(i, _discountLevel[i].percent, _discountLevel[i].discount); }
    }
  }

  function setDiscountLevel(uint8 level, uint24 percent, uint24 discount) external onlyOwner {
    require(level < 3);

    unchecked {
      require(percent <= denominator * 100);

      if (level + 1 < 3 && _discountLevel[level + 1].exists) { require(_discountLevel[level + 1].percent > percent); }
      if (level - 1 >= 0 && _discountLevel[level - 1].exists) { require(_discountLevel[level - 1].percent < percent); }
    }

    if (!_discountLevel[level].exists) { _discountLevel[level].exists = true; }

    _discountLevel[level].percent = percent;
    _discountLevel[level].discount = discount;

    emit SetDiscountLevel(level, percent, discount);
  }

  function _getDiscountPercent(address user) private view returns (uint24 discount) {
    if (address(FACTORY_TOKEN) == address(0)) { return 0; }

    uint256 balance = FACTORY_TOKEN.balanceOf(user);
    uint256 staked = address(FACTORY_STAKE) != address(0) ? FACTORY_STAKE.stakedAmount(user) : 0;

    if (balance == 0 && staked == 0) { return 0; }

    uint256 amount = balance > staked ? balance : staked;

    unchecked {
      uint24 pct = uint24((uint256(denominator) * amount * 100) / FACTORY_TOKEN.totalSupply());

      for (uint8 i; i < 3; i++) {
        if (!_discountLevel[i].exists || pct < _discountLevel[i].percent) { continue; }
        if (pct > _discountLevel[i].percent) { break; }

        discount = _discountLevel[i].discount;
      }
    }
  }

  function _countActiveTemplates() private view returns (uint256 active) {
    uint256 cnt = _templateList.length;

    unchecked {
      for (uint256 t; t < cnt; t++) {
        if (!_templateData[_templateList[t]].active) { continue; }

        active++;
      }
    }
  }

  function setMultiSignatureWallet(address account) external onlyOwner {
    MULTISIGN_ADDRESS = account;
  }

  function setTreasury(address payable account) external onlyOwner {
    TREASURY_ADDRESS = account;
  }

  function setFactoryInterfaces(address token, address stake) external onlyOwner {
    FACTORY_TOKEN = IERC20(token);
    FACTORY_STAKE = IStake(stake);
  }

  function recoverERC20(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }

  function recoverETH(address payable to, uint256 amount) external onlyOwner {
    (bool success, ) = to.call{ value: amount }("");

    require(success);
  }

  receive() external payable { }
  fallback() external payable { }
}