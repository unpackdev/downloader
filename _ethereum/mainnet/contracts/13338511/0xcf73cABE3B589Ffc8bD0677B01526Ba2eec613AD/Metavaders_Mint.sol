// SPDX-License-Identifier: MIT

/// @title: Metavaders - Mint
/// @author: PxGnome
/// @notice: Used to handle mint with metavaders NFT contract
/// @dev: This is Version 1.0
//
// ███╗   ███╗███████╗████████╗ █████╗ ██╗   ██╗ █████╗ ██████╗ ███████╗██████╗ ███████╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
// ██╔████╔██║█████╗     ██║   ███████║██║   ██║███████║██║  ██║█████╗  ██████╔╝███████╗
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚██╗ ██╔╝██╔══██║██║  ██║██╔══╝  ██╔══██╗╚════██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║ ╚████╔╝ ██║  ██║██████╔╝███████╗██║  ██║███████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝
//
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

// Abstract Contract Used for Inheriting
abstract contract IMetavader_Mint {
    function mint(address to, uint256 num) public virtual;
    function reserveMint(address to, uint256 num) public virtual;
    function balanceOf(address _owner) public virtual returns(uint256);
    function totalSupply() public view virtual returns (uint256);
}

contract Metavaders_Mint is 
    Ownable
{   
    using Strings for uint256;
    address public metavadersAddress;

    IMetavader_Mint MetavaderContract;

    // Mint Info
    uint256 public max_mint = 10101;
    uint256 private _reserved = 200; // Reserved amount for special usage
    uint256 public price = 0.07 ether;
    uint256 private _max_gas = 200000000000;
    uint256 public start_time = 1633363200; // start time:  Monday, October 4, 2021 4:00:00 PM UTC
    uint256 public max_sale = 10;
    uint256 public max_wallet = 20;
    bool public _paused = true;

    // Presale
    uint256 private _presale_supply = 1000;
    uint256 public max_presale = 5;
    bool public whiteListEnd = false;

    mapping(address => bool) whitelist;
    mapping(address => uint256) mintPerWallet;

    // -- CONSTRUCTOR FUNCTIONS -- //
    // 10101 Metavaders in total
    constructor(address _metavadersAddress) {
        metavadersAddress = _metavadersAddress;
        MetavaderContract = IMetavader_Mint(_metavadersAddress);
    }

    // // -- UTILITY FUNCTIONS -- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    // Update Metavader Address Incase There Is an Issue
    function updateMetavadersAddress(address _address) public onlyOwner {
        metavadersAddress = _address;
    }

    // Withdraw to owner addresss
    function withdrawAll() public payable onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance)); 
        return balance;
    }

    function addToWhiteList(address _address) public onlyOwner {
        whitelist[_address] = true;
        // emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        // emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        if (whiteListEnd == true) {
            return true;
        } else {
            return whitelist[_address];
        }
    }


    // -- MINT FUNCTIONS  --//
    function public_mint(uint256 num) public payable virtual {
        require( tx.gasprice < _max_gas,                                    "Please set lower gas price and retry"); // Set a cap on gas
        require( !_paused,                                                  "Mint is paused" );
        require( block.timestamp > start_time,                              "Mint not yet started"); // start time:  1633374000 = Monday, October 4, 2021 7:00:00 PM UTC
        require( num <= max_sale,                                           "Exceeded max mint per txn");
        require( (mintPerWallet[_msgSender()] + num) <= max_wallet,         "Exceeded mint per wallet");
        // require( MetavaderContract.balanceOf(_msgSender()) < max_wallet,    "Exceeded mint per wallet");
        uint256 supply = MetavaderContract.totalSupply();
        require( supply + num < max_mint - _reserved,                       "Exceeds maximum supply" );
        require( msg.value >= price * num,                                  "Ether sent incorrect");

        MetavaderContract.mint(_msgSender(), num);
        mintPerWallet[_msgSender()] += num;
    }

    // Presale Mint Function
    function presale_mint(uint256 num) public payable virtual {
        require(tx.gasprice < _max_gas,                                     "Please set lower gas price and retry"); // Set a cap on gas
        require( !_paused,                                                  "Mint is paused" );        
        require(isWhitelisted(_msgSender()) == true || whiteListEnd,        "You are not on whitelist");
        require( num <= max_presale,                                        "Exceeded max presale mint per txn");
        require( (mintPerWallet[_msgSender()] + num) <= max_presale,        "Exceeded mint per wallet");
        uint256 supply = MetavaderContract.totalSupply();
        require( supply + num < _presale_supply,                            "Exceeds max presale supply" );
        require( msg.value >= price * num,                                  "Ether sent incorrect");

        MetavaderContract.mint(_msgSender(), num);
        mintPerWallet[_msgSender()] += num;
    }

    // Minted the reserve
    function reserveMint(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Metavaders supply" );
        // uint256 supply = MetavaderContract.totalSupply();
        MetavaderContract.reserveMint(_to, _amount);
        _reserved -= _amount;
    }

    // Get wallet mint numbers for troubleshooting if needed
    function getWalletMinted(address checkAdd) external view returns (uint256 minted) {
        return mintPerWallet[checkAdd];
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    function setGasMax(uint256 _newGasMax) public onlyOwner {
        _max_gas = _newGasMax;
    }
    function setStartTime(uint256 new_start_time) public onlyOwner {
        start_time = new_start_time;
    }
    function setPresaleSupply(uint256 new_presale_supply) public onlyOwner {
        _presale_supply = new_presale_supply;
    }
    function setMaxPresale(uint256 new_max_presale) public onlyOwner {
        max_presale = new_max_presale;
    }
    function setMaxSale(uint256 new_max_sale) public onlyOwner {
        max_sale = new_max_sale;
    }
    function setMaxWallet(uint256 new_max_wallet) public onlyOwner {
        max_wallet = new_max_wallet;
    }
    function setWhiteListEnd(bool new_whiteListEnd) public onlyOwner {
        whiteListEnd = new_whiteListEnd;
    }


    // Pause sale/mint in case of special reason
    function pause(bool val) public onlyOwner {
        _paused = val;
    }

}
