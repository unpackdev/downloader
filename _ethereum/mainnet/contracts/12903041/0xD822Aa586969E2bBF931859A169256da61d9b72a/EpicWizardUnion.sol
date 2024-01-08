pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
  address public owner;

   /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
  constructor() {
    owner = msg.sender;
  }

   /**
    * @dev Throws if called by any account other than the owner.
    */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

abstract contract WizardMinting is ERC721Enumerable {
  function _mintWizards(address owner, uint256 startingIndex, uint16 number) internal {
    for (uint i = 0; i < number; i++) {
      _safeMint(owner, startingIndex + i);
    }
  }
}

abstract contract WizardSelling is WizardMinting, Ownable, Pausable {
  uint256 constant maxWizards = 10778;
  uint constant sellableWizardStartingIndex = 62;
  uint constant giveawayWizardStartingIndex = 12;
  uint constant specialWizardStartingIndex  = 1;
  uint16 constant maxWizardsToBuyAtOnce = 77;
  // 0.07 Ether fixed price for single wizard
  uint constant singleWizardPrice = 50000000 gwei;

  uint256 public nextWizardForSale;
  uint public nextWizardToGiveaway;
  uint public nextSpecialWizard;

  constructor() {
    nextWizardForSale = sellableWizardStartingIndex;
    nextWizardToGiveaway = giveawayWizardStartingIndex;
    nextSpecialWizard    = specialWizardStartingIndex;
  }

  function buyWizards(uint16 wizardsToBuy)
    public
    payable
    whenNotPaused
  {
    require(wizardsToBuy > 0, "Cannot buy 0 wizards");
    require(leftForSale() >= wizardsToBuy, "Not enough wizards left on sale");
    require(wizardsToBuy <= maxWizardsToBuyAtOnce, "Cannot buy that many wizards at once");
    require(msg.value >= singleWizardPrice * wizardsToBuy, "Insufficient funds sent.");
    _mintWizards(msg.sender, nextWizardForSale, wizardsToBuy);

    nextWizardForSale += wizardsToBuy;
  }

  function leftForSale() public view returns(uint256) {
    return maxWizards - nextWizardForSale;
  }

  function leftForGiveaway() public view returns(uint) {
    return sellableWizardStartingIndex - nextWizardToGiveaway;
  }

  function leftSpecial() public view returns(uint) {
    return giveawayWizardStartingIndex - nextSpecialWizard;
  }

  function giveawayWizard(address to) public onlyOwner {
    require(leftForGiveaway() >= 1);
    _mintWizards(to, nextWizardToGiveaway++, 1);
  }

  function mintSpecialWizard(address to) public onlyOwner {
    require(leftSpecial() >= 1);
    _mintWizards(to, nextSpecialWizard++, 1);
  }

  function startSale() public onlyOwner whenPaused {
    _unpause();
  }

  function pauseSale() public onlyOwner whenNotPaused {
    _pause();
  }
}

contract EpicWizardUnion is WizardSelling {
  string _provenanceHash;
  string baseURI_;

  constructor() ERC721("Epic Wizard Union", "EWU") {
    _pause();
    setBaseURI("https://shielded-eyrie-24836.herokuapp.com");
  }

  function withdraw() public payable onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setProvenanceHash(string memory provenanceHash)
    public
    onlyOwner
  {
    _provenanceHash = provenanceHash;
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseURI_ = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI_;
  }

  function isApprovedOrOwner(address target, uint256 tokenId)
    public
    view
    returns (bool) {
    return _isApprovedOrOwner(target, tokenId);
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  function tokensInWallet(address wallet) public view returns (uint256[] memory) {
    uint256[] memory tokens = new uint256[](balanceOf(wallet));

    for (uint i = 0; i < tokens.length; i++) {
      tokens[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return tokens;
  }

  function burn(uint256 tokenId) public virtual {
     require(_isApprovedOrOwner(_msgSender(), tokenId), "CryptoWizards: caller is not owner nor approved");
     _burn(tokenId);
 }
}
