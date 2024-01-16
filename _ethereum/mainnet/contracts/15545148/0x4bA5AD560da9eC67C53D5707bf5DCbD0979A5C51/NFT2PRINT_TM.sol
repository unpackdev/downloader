// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";



//    _   _ _____ _____ ____  ____  ____  ___ _   _ _____                    
//   | \ | |  ___|_   _|___ \|  _ \|  _ \|_ _| \ | |_   _|___ ___  _ __ ___  
//   |  \| | |_    | |   __) | |_) | |_) || ||  \| | | | / __/ _ \| '_ ` _ \ 
//   | |\  |  _|   | |  / __/|  __/|  _ < | || |\  | | || (_| (_) | | | | | |
//   |_| \_|_|     |_| |_____|_|   |_| \_\___|_| \_| |_(_)___\___/|_| |_| |_|
//                                                                       



contract ToyNFTContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
    }
}

contract NFT2PRINT_TM is AccessControl  {
bytes32 public constant PRINT_ROLE = keccak256("PRINT_ROLE");

    struct ToyID {
        uint256 data;
        address toyCreatorAddres;         
    }
    
    mapping (uint256 => ToyID) public toyData;
    
    bool public isProductionEnabled = true;
    uint256 public standard_ToyPrice = 0.05 ether;
    uint256 public large_ToyPrice = 0.40 ether;
    uint256 public totalToysCreated = 0;

    
    ToyNFTContract private immutable toyaddr;
    
    constructor(address ToyAddress) {
        toyaddr = ToyNFTContract(ToyAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function toggleToyProductionEnabled() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isProductionEnabled = !isProductionEnabled;  
    }

    function setProductionPrice(uint256 _standardPrice, uint _largePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        standard_ToyPrice = _standardPrice;
        large_ToyPrice = _largePrice;
    }

    function createToy(uint256[] memory _tokenIds, uint256 _noStandardToys, uint256 _noLargeToys) public payable {

        uint256 totaltokenIds;
        totaltokenIds = _tokenIds.length;
        require(isProductionEnabled, "Production is disabled");
        require(msg.value >= ((standard_ToyPrice * _noStandardToys) + (large_ToyPrice * _noLargeToys)) , "Ether value sent is not correct");

        for(uint256 i = 0; i < totaltokenIds ; i++ ){
            require(toyaddr.ownerOf(_tokenIds[i]) == msg.sender, "You must own the orignal NFT");          
        }
        
        totalToysCreated += _noStandardToys + _noLargeToys;
    }

    function setToyID(uint256 _uidToy, uint256 _data, address _toyCreatorAddres) external onlyRole(PRINT_ROLE) {

        ToyID storage toy = toyData[_uidToy];
      
        toy.data = _data;
        toy.toyCreatorAddres = _toyCreatorAddres;
    }

    
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 contractBalance = address(this).balance;
        bool success = true;

        (success, ) = payable(0x0108E1348D42192a749Ae029fa2Ad7b5c2E6F210).call{
            value: (95 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0x4B8229Db7bBd5901FfbB387A0E7c67E3fb90fC61).call{
            value: (5 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");
    }

}