//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./DefaultOperatorFilterer.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract NFTDasMagazine20243Minter is Ownable {

    address public nftDasMagazinAddress = 0x07F027e77290c2337cf7046B48A1815150A0Abc9;
    address public nftDasMagazineAddress = 0x476Ae7237d50E01C84d8f04E7C8021909600A898;

    address public nftDasMagazine20243Address = 0x7ed81A876c74bbF0899aE9F1Bc1E09D45B60e223;

    uint256 public publicPrice = 0.02 ether;

    uint256 public holderPrice = 0.01 ether;

    bool public isMintEnabled = true;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    function getPublicPrice() public view returns (uint256) {
        return publicPrice;
    }

    function setPublicPrice(uint256 _price)
        public
        onlyOwner
    {
        publicPrice = _price;
    }

    function getHolderPrice() public view returns (uint256) {
        return holderPrice;
    }

    function setHolderPrice(uint256 _price)
        public
        onlyOwner
    {
        holderPrice = _price;
    }

    function setNFTDasMagazinAddress(address _address)  public onlyOwner {
        nftDasMagazinAddress = _address;
    }

    function setNFTDasMagazineAddress(address _address)  public onlyOwner {
        nftDasMagazineAddress = _address;
    }

    function setNFTDasMagazine20243Address(address _address)  public onlyOwner {
        nftDasMagazine20243Address = _address;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20243Address);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }


    function mintHolder(uint256 amount, uint256 tokenId) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= holderPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");
        
        ERC1155 magazinToken = ERC1155(nftDasMagazinAddress);
        ERC1155 magazineToken = ERC1155(nftDasMagazineAddress);
   
        require(magazinToken.balanceOf(msg.sender, tokenId) == 1 || magazineToken.balanceOf(msg.sender, tokenId) == 1, "Not eligible");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20243Address);
        
        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }

        //Mint Magazine NFT if amount is greater or equal than 3
        if(amount >= 3){
            uint amountMagazin = amount / 3;
            for(uint256 i = 0; i < amountMagazin; i++){
                token.mint(msg.sender, _idTracker.current(), 1, "");
                _idTracker.increment();
            }
        }
    }

    function mintPublic(uint256 amount) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= publicPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(nftDasMagazine20243Address);

        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }

          //Mint Magazine NFT if amount is greater or equal than 3
        if(amount >= 3){
            uint amountMagazin = amount / 3;
            for(uint256 i = 0; i < amountMagazin; i++){
                token.mint(msg.sender, _idTracker.current(), 1, "");
                _idTracker.increment();
            }
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
