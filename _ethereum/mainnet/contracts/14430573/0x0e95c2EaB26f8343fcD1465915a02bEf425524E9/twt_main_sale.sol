pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "./token_interface.sol";
import "./recovery.sol";

import "./console.sol";

struct vData {
    address from;
    uint256 max_mint;
    bytes   signature;
}

contract TheWorldTodayMainSale is recovery {

    mapping (address => uint256)    public  public_minted;
    token_interface                 public  token;
    mapping (address => bool)               admins;
    uint256                         public  sale_price    = 8e16;

    address payable                 public  wallet;
    uint256                         public  max_public_mint = 50;
    bool                            public  minting = true;

    modifier onlyAdmin() {
        require(admins[msg.sender] || (msg.sender == owner()),"onlyAdmin = no entry");
        _;
    }

    function enable_minting(bool _minting) external onlyAdmin {
        minting = _minting;
    }

    constructor(
        token_interface  _token, 
        address[] memory _admins,
        address payable _wallet
    )  recovery(_wallet) {
        token = _token;
        wallet = _wallet;
        for (uint j = 0; j < _admins.length; j++) {
            admins[_admins[j]] = true;
        }
    }


    function public_main_mint(uint256 number_to_mint) external payable {
        require(minting,"minting not enabled");
        require(msg.value == number_to_mint * sale_price,"incorrect amount sent");
        require(number_to_mint <= max_public_mint,"number requested in one tx exceeds max_public_mint");
        token.mintCards(number_to_mint,msg.sender);
        public_minted[msg.sender] += number_to_mint;
        sendETH(wallet,msg.value);
    }

    function sendETH(address dest, uint amount) internal {
        (bool sent, ) = payable(dest).call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }

}