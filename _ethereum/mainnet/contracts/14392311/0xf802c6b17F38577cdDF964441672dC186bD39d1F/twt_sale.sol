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

contract TheWorldTodaySale is recovery {

    address                         public  signer;
    mapping (address => uint256)    public  green_minted;
    mapping (address => uint256)    public  public_minted;
    mapping (address => uint256)    public  admin_minted;
    token_interface                 public  token;
    mapping (address => bool)               admins;
    uint256                         public  presale_price = 8e16;
    uint256                         public  sale_price    = 8e16;


    uint256                         public  green_minting_starts;
    uint256                         public  public_minting_starts;
    uint256                                 max_public_mint = 10;

    address payable                 public  wallet;

    modifier onlyAdmin() {
        require(admins[msg.sender] || (msg.sender == owner()),"onlyAdmin = no entry");
        _;
    }

    constructor(
        token_interface  _token, 
        address _signer, 
        uint256 _green_start,
        uint256 _main_start,
        address[] memory _admins,
        address payable _wallet
    )  recovery(_wallet) {
        token = _token;
        signer = _signer;
        wallet = _wallet;
        green_minting_starts = _green_start;
        public_minting_starts = _main_start;
        for (uint j = 0; j < _admins.length; j++) {
            admins[_admins[j]] = true;
        }
    }

    function setGM(uint256 gm) external onlyAdmin {
        green_minting_starts = gm;
    }

    function setPM(uint256 pm) external onlyAdmin {
        public_minting_starts = pm;
    }


    function public_mint(uint256 number_to_mint) external payable {
        require(block.timestamp > public_minting_starts,"Public mint not open");
        require(msg.value == number_to_mint * sale_price,"incorrect amount sent");
        require(number_to_mint <= max_public_mint,"number requested in one tx exceeds max_public_mint");
        token.mintCards(number_to_mint,msg.sender);
        uint minted_here = public_minted[msg.sender] += number_to_mint;
        require(minted_here < 11,"Max public mint per address : 10");
        sendETH(wallet,msg.value);
    } 


    function mint_green(uint number_to_mint,vData calldata info) external payable {
        require(block.timestamp > green_minting_starts,"GM not open");
        require(block.timestamp < public_minting_starts,"Public mint already started");
        require(info.from == msg.sender,"Invalid FROM field");
        uint256 already_minted = green_minted[msg.sender];
        require(already_minted + number_to_mint <= info.max_mint,"You have already reached (or will exceed) your green mint limit");
        require(verify(info),"Invalid GM secret");
        require(msg.value == number_to_mint * presale_price,"incorrect amount sent");
        token.mintCards(number_to_mint,info.from);
        green_minted[msg.sender] = already_minted + number_to_mint;
        sendETH(wallet,msg.value);
    }

    function sendETH(address dest, uint amount) internal {
        (bool sent, ) = payable(dest).call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }


    function verify(vData memory info) internal  view returns (bool) {
        require(info.from != address(0), "INVALID_SIGNER");
        bytes memory cat = abi.encode(info.from, info.max_mint);
        bytes32 hash = keccak256(cat);
        require (info.signature.length == 65,"Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8   sigV;
        bytes memory signature = info.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data =  keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(
                data,
                sigV,
                sigR,
                sigS
            );
        return
            signer == recovered;
    }

}