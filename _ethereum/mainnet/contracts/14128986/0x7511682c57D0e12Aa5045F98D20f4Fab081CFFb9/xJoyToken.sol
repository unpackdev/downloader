// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Authorizable.sol";

contract xJoyToken is ERC20, Ownable, Authorizable {
    using SafeMath for uint256;
    bool public PURCHASER_TRANSFER_LOCK_FLAG;
    address[] public purchasers;
    mapping(address => uint256) public purchasedAmounts;
    uint256 public manualMinted = 0;

    // Modifiers.
    /**
     * @dev Ensures that the anti-whale rules are enforced.
     */
    modifier canTransfer(address sender) {
        require(checkTransferable(sender), "The purchaser can't transfer in locking period");
        _;
    }

    constructor(
      string memory _name,
      string memory _symbol
    ) ERC20(_name, _symbol) {
      addAuthorized(_msgSender());
      PURCHASER_TRANSFER_LOCK_FLAG = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function manualMint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        manualMinted = manualMinted.add(_amount);
    }

    // add purchaser
    function addPurchaser(address addr, uint256 amount) public onlyAuthorized {
      uint256 purchasedAmount = purchasedAmounts[addr];
      if (purchasedAmount == 0) {
          purchasers.push(addr);
      }
      purchasedAmounts[addr] = purchasedAmount + amount;       
    }

    // add transfer
    function lockTransferForPurchaser(bool bFlag) public onlyAuthorized {
      PURCHASER_TRANSFER_LOCK_FLAG = bFlag;
    }

    // check sale period
    function checkTransferable(address sender) public view returns (bool) {
      uint256  purchasedAmount = purchasedAmounts[sender];
      bool bFlag = PURCHASER_TRANSFER_LOCK_FLAG && purchasedAmount > 0;
      return !bFlag;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override
    canTransfer(sender) {
        super._transfer(sender, recipient, amount);
    }    
}