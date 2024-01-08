// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlindboxStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Utils is Ownable, BlindboxStorage{
    
    using SafeMath for uint256;
    address internal gasFeeCollector;
    uint256 internal gasFee;
    constructor() {
       

    }
    function init() public {
         MATIC = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //for eth chain wrapped ethereum 
        USD = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        platform = 0x9c427ea9cE5fd3101a273815Ff8530f2AC75Db37;
        nft = INFT(0x54994ba4b4A42297B3B88E27185CDe1F51DcA288);
        dex = IDEX(0x9d5dc3cc15E5618434A2737DBF76158C59CA1e65);
        _setOwner(_msgSender());
    }
    function setVRF(address _vrf) onlyOwner public {
        vrf = IRand(_vrf);
        emit VRF(address(vrf));
    }
    function setGaseFeeData(address _address, uint256 gasFeeInUSDT ) onlyOwner public  {
       gasFeeCollector = _address;
       gasFee = gasFeeInUSDT;
    }
    function getRand() internal returns(uint256) {

        vrf.getRandomNumber();
        uint256 rndm = vrf.getRandomVal();
        return rndm.mod(100); // taking to limit value within range of 0 - 99
    }
    function blindCreateCollection(string memory name_, string memory symbol_) onlyOwner public {
        dex.createCollection(name_, symbol_);
    }

    function transferOwnerShipCollection(address[] memory collections, address newOwner) onlyOwner public {
       for (uint256 index = 0; index < collections.length; index++) {
            dex.transferCollectionOwnership(collections[index], newOwner);
       }
    }

    // event
    event VRF(address indexed vrf);
    
}