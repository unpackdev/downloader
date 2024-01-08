// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Fiat24Account.sol";

contract Fiat24Token is ERC20PausableUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 internal WalkinLimit;
    uint256 internal WithdrawCharge;
    uint256 private constant MINIMALCOMMISIONFEE = 10;
    Fiat24Account fiat24account;

    mapping (address => uint256) public walkinAccumulated;

    function __Fiat24Token_init_(address fiat24accountProxyAddress,
                               string memory name_,
                               string memory symbol_,
                               uint256 walkinLimit,
                               uint256 withdrawCharge) internal initializer {
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __ERC20_init_unchained(name_, symbol_);
      _setupDecimals(2);
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(OPERATOR_ROLE, _msgSender());
      fiat24account = Fiat24Account(fiat24accountProxyAddress);
      WithdrawCharge = withdrawCharge;
      WalkinLimit = walkinLimit;
  }

  function mint(uint256 amount) public {
      require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
      _mint(fiat24account.ownerOf(9101), amount);
  }

  function burn(uint256 amount) public {
      require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
      _burn(fiat24account.ownerOf(9104), amount);
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    //require(tokenTransferAllowed(_msgSender(), recipient, amount), "No FIAT24 account, accounts blocked or transfer limit exceeded");
    if(recipient == fiat24account.ownerOf(9102)) {
        _transfer(_msgSender(), recipient, amount.sub(WithdrawCharge, "Withdraw charge exceeds withdraw amount"));
        _transfer(_msgSender(), fiat24account.ownerOf(9202), WithdrawCharge);
    } else {
        if(fiat24account.balanceOf(recipient) > 0 && fiat24account.isMerchant(fiat24account.getAccountOfAddress(recipient))) {
            uint256 commissionFee = amount.mul(fiat24account.merchantRate(fiat24account.getAccountOfAddress(recipient))).div(10000);
            if(commissionFee >= MINIMALCOMMISIONFEE) {
                _transfer(_msgSender(), recipient, amount.sub(commissionFee, "Commission fee exceeds payment amount"));
                _transfer(_msgSender(), fiat24account.ownerOf(9201), commissionFee);
            } else {
                _transfer(_msgSender(), recipient, amount);
            }
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
    }
    return true;
  }

  function transferByAccountId(uint256 recipientAccountId, uint256 amount) public returns(bool){
    return transfer(fiat24account.ownerOf(recipientAccountId), amount);
  }

  function balanceOfByAccountId(uint256 accountId) public view returns(uint256) {
    return balanceOf(fiat24account.ownerOf(accountId));
  }

  function tokenTransferAllowed(address from, address to, uint256 amount) public view returns(bool){
    require(!fiat24account.paused(), "All account transfers are paused");
    require(!paused(), "All account transfers of this currency are paused");
    // not minting, not burning
    if(from != address(0) && to != address(0)){
        // bool fromHasMembership = fiat24account.balanceOf(from) > 0;
        // bool toHasMembership = fiat24account.balanceOf(to) > 0;
        // Fiat24Account.Status fromClientStatus = Fiat24Account.Status.Na;
        // Fiat24Account.Status toClientStatus = Fiat24Account.Status.Na;
        // if(fromHasMembership) {
        //     uint256 accountId = fiat24account.getAccountOfAddress(from);
        //     if(accountId != 0) {
        //         fromClientStatus = fiat24account.status(accountId);
        //     } else {
        //         fromClientStatus = Fiat24Account.Status.Invitee;
        //     }
        // }
        // if(toHasMembership) {
        //     uint256 accountId = fiat24account.getAccountOfAddress(to);
        //     if(accountId != 0) {
        //         toClientStatus = fiat24account.status(accountId);
        //     } else {
        //         toClientStatus = Fiat24Account.Status.Invitee;
        //     }
        // }
        if(balanceOf(from) < amount) {
            return false;
        }
        uint256 toAmount = amount + balanceOf(to);
        Fiat24Account.Status fromClientStatus;
        uint256 accountIdFrom = fiat24account.getAccountOfAddress(from);
        if(accountIdFrom != 0) {
            fromClientStatus = fiat24account.status(accountIdFrom);
        } else {
            fromClientStatus = Fiat24Account.Status.Invitee;
        }
        Fiat24Account.Status toClientStatus;
        uint256 accountIdTo = fiat24account.getAccountOfAddress(to);
        if(accountIdTo != 0) {
            toClientStatus = fiat24account.status(accountIdTo);
        } else {
            toClientStatus = Fiat24Account.Status.Invitee;
        }
        if((fromClientStatus == Fiat24Account.Status.Live) &&
           (toClientStatus == Fiat24Account.Status.Live || toClientStatus == Fiat24Account.Status.SoftBlocked ||
            (toClientStatus == Fiat24Account.Status.Invitee && toAmount <= WalkinLimit))) {
          return true;
        } else {
          return false;
        }
        // // if(fromHasMembership) {
        // //     uint256 accountId = fiat24account.getAccountOfAddress(from);
        // //     if(accountId != 0) {
        // //         fromClientStatus = fiat24account.status(accountId);
        // //     } else {
        // //         fromClientStatus = Fiat24Account.Status.Invitee;
        // //     }
        // // }
        // // if(toHasMembership) {
        // //     uint256 accountId = fiat24account.getAccountOfAddress(to);
        // //     if(accountId != 0) {
        // //         toClientStatus = fiat24account.status(accountId);
        // //     } else {
        // //         toClientStatus = Fiat24Account.Status.Invitee;
        // //     }
        // // }

        // if(toAmount > WalkinLimit) {
        //     if((fromHasMembership && toHasMembership) &&
        //         (fromClientStatus == Fiat24Account.Status.Live) &&
        //         (toClientStatus == Fiat24Account.Status.Live ||
        //         toClientStatus == Fiat24Account.Status.SoftBlocked) /*||
        //         (fromClientStatus == Fiat24Account.Status.Invitee && amount <= WalkinLimit)*/) {
        //         return true;
        //     } /*else {
        //         if(toHasMembership &&
        //             (toClientStatus == Fiat24Account.Status.Live || toClientStatus == Fiat24Account.Status.SoftBlocked) &&
        //             (amount <= WalkinLimit) ) {
        //             return true;
        //         }
        //     }*/
        // } else {
        //     // if(!fromHasMembership && !toHasMembership) {
        //     //     return true;
        //     // }

        //     if((fromHasMembership && !toHasMembership) &&
        //         !(fromClientStatus == Fiat24Account.Status.Blocked ||
        //         fromClientStatus == Fiat24Account.Status.Closed ||
        //         fromClientStatus == Fiat24Account.Status.SoftBlocked ||
        //         fromClientStatus == Fiat24Account.Status.Invitee)) {
        //             return true;
        //     }

        //     if((!fromHasMembership && toHasMembership) &&
        //         !(toClientStatus == Fiat24Account.Status.Blocked ||
        //         toClientStatus == Fiat24Account.Status.Closed)) {
        //             return true;
        //     }

        //     if((fromHasMembership && toHasMembership) &&
        //         !(fromClientStatus == Fiat24Account.Status.Blocked ||
        //         toClientStatus == Fiat24Account.Status.Blocked  ||
        //         fromClientStatus == Fiat24Account.Status.SoftBlocked ||
        //         fromClientStatus == Fiat24Account.Status.Closed ||
        //         toClientStatus == Fiat24Account.Status.Closed ||
        //         fromClientStatus == Fiat24Account.Status.Invitee)) {
        //             return true;
        //     }
        // }
        // return false;
    }
  }

  function setWalkInLimit(uint256 walkinLimit) public {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
    WalkinLimit = walkinLimit;
  }

  function setWithdrawCharge(uint256 withdrawCharge) public {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
    WithdrawCharge = withdrawCharge;
  }

  function sendToSundry(address from, uint256 amount) public {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
    _transfer(from, fiat24account.ownerOf(9103), amount);
  }

  function pause() public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
    _pause();
  }

  function unpause() public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    require(!fiat24account.paused(), "Fiat24Token: all account transfers are paused");
    require(!paused(), "Fiat24Token: all account transfers of this currency are paused");
    // not minting, not burning
    if(from != address(0) && to != address(0) && to != fiat24account.ownerOf(9103)){
        require(tokenTransferAllowed(from, to, amount), "Fiat24Token: No FIAT24 account, accounts blocked or transfer limit exceeded");
    }
    super._beforeTokenTransfer(from, to, amount);
  }
}
