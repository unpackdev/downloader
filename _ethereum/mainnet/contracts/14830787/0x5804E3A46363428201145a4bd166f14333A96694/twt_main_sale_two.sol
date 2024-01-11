pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "./token_two_interface.sol";
import "./recovery.sol";
import "./randomiser.sol";

struct vData {
    address from;
    uint256 max_mint;
    bytes   signature;
}

contract TheWorldTodayMainSaleTwo is recovery,randomiser {

    token_two_interface             public  token;
    address                         public  oldToken;
    mapping (address => bool)               admins;
    uint256                         public  sale_price    = 8e16;

    address payable                 public  wallet;
    bool                            public  minting = false;
    uint256            constant     public  max_public_mint = 100;

    uint256              constant   public  base = 1147;
    uint256                         public  counter = 1147;
    mapping(address => uint256)     public  public_minted;

    modifier onlyAdmin() {
        require(admins[msg.sender] || (msg.sender == owner()),"onlyAdmin = no entry");
        _;
    }

    event SetAdmin(address _addr, bool _state);

    function enable_minting(bool _minting) external onlyAdmin {
        minting = _minting;
    }

    constructor(
        token_two_interface  _token, 
        address[] memory _admins,
        address payable _wallet
    )  recovery(_wallet) randomiser(1) {
        token = _token;
        wallet = _wallet;
        for (uint j = 0; j < _admins.length; j++) {
            admins[_admins[j]] = true;
        }
        setNumTokensLeft(1, 13800 - 1147);
    }


    function public_main_mint(uint256 number_to_mint) external payable {
        require(minting,"minting not enabled");
        bool adminMint = (admins[msg.sender] || (msg.sender == owner())) && msg.value == 0;
        if ( !adminMint ){
            require(msg.value == number_to_mint * sale_price,"incorrect amount sent");
            require(number_to_mint <= max_public_mint,"number requested in one tx exceeds max_public_mint");
        }
        _mintCards(number_to_mint,msg.sender);
        public_minted[msg.sender] += number_to_mint;
        sendETH(wallet,msg.value);
    }

    function sendETH(address dest, uint amount) internal {
        (bool sent, ) = payable(dest).call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }



    function _mintCards(uint number_of_tokens, address user) internal {
        uint256 newCounter = counter + number_of_tokens;
        require(newCounter < 13801,"Not enough tokens left to mint");
        uint256[] memory tokenIDArray = new uint256[](number_of_tokens);
        bytes32 srn = blockhash(block.number);
        //console.log(number_of_tokens," being minted ",tokenIDArray.length);
        for (uint pos = 0; pos < number_of_tokens; pos++) {
            
            tokenIDArray[pos] = randomTokenURI(1,uint256(srn)) + base;
            //console.log(tokenIDArray[pos]);
            srn = keccak256(abi.encodePacked(srn,pos,msg.sender));
        }
        token.mintBatchToOneR(user, tokenIDArray);

        counter += number_of_tokens;

    }

    function setAdmin(address _addr, bool _state) external  onlyAdmin {
        admins[_addr] = _state;
        emit SetAdmin(_addr,_state);
    }


}