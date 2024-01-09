pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "./token_interface.sol";
import "./recovery_split.sol";

import "./console.sol";

struct vData {
    address from;
    uint256 max_mint;
    bytes   signature;
}

contract as10k_sale is recovery_split{

    address                         public  signer;
    mapping (address => uint256)    public  green_minted;
    mapping (address => uint256)    public  public_minted;
    mapping (address => uint256)    public  admin_minted;
    token_interface                 public  token;
    mapping (address => bool)               admins;

    uint256           constant      public  green_minting_starts = 1644483600;
    uint256           constant      public  public_minting_starts = 1644512400;
    uint256                                 max_public_mint = 3;

    modifier onlyAdmin() {
        require(admins[msg.sender],"onlyAdmin = no entry");
        _;
    }

    constructor(
        token_interface  _token, 
        address _signer, 
        address[] memory _admins,
        address[] memory _wallets, 
        uint256[] memory _shares 
    ) recovery_split(_wallets,_shares) {
        token = _token;
        signer = _signer;
        for (uint j = 0; j < _admins.length; j++) {
            admins[_admins[j]] = true;
        }
    }

    function admin_mint(uint256 number_to_mint) external onlyAdmin {
        uint256 already_minted = admin_minted[msg.sender];
        require(already_minted < 250,"You have already reached your admin mint limit");
        uint256 spare = 250 - already_minted;
        uint256 to_mint = (spare < number_to_mint) ? spare : number_to_mint;
        token.mintCards(to_mint,msg.sender);
        admin_minted[msg.sender] = already_minted + to_mint;
    }

    function public_mint(uint256 number_to_mint) external payable {
        require(block.timestamp > public_minting_starts,"Public mint not open");
        uint256 already_minted = public_minted[msg.sender];
        uint256 mpm = max_public_mint;
        require(already_minted < mpm,"You have already reached your public mint limit");
        uint256 spare = mpm - already_minted;
        uint256 to_mint = (spare < number_to_mint) ? spare : number_to_mint;
        token.mintCards(to_mint,msg.sender);
        public_minted[msg.sender] = already_minted + to_mint;
    } 


    function mint_green(uint number_to_mint,vData calldata info) external payable {
        require(block.timestamp > green_minting_starts,"GM not open");
        require(info.from == msg.sender,"Invalid FROM field");
        uint256 already_minted = green_minted[msg.sender];
        require(already_minted < info.max_mint,"You have already reached your green mint limit");
        require(verify(info),"Invalid GM secret");
        uint256 spare = info.max_mint - already_minted;
        uint256 to_mint = (spare < number_to_mint) ? spare : number_to_mint;
        token.mintCards(to_mint,info.from);
        green_minted[msg.sender] = already_minted + to_mint;
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