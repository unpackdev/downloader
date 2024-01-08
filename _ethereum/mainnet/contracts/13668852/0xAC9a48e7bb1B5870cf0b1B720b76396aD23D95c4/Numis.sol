// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: NumisNFT
//  https://www.numisnft.com/
//  NumisNFT - Roman Empire Set

import "./ERC721TradableNumis.sol";

/**
 * @title Numis
 * NumisNFT: Roman Empire Collection
 */
 
contract Numis is ERC721TradableNumis {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721TradableNumis("NumisNFT Roman Empire Collection", "ROMA", _proxyRegistryAddress) {}

    bool    private _active;
    string  private _theBaseURI = "https://mint.numisnft.com/";
    uint256 constant private PRICE = 90000000000000000;    // 0.09 ETH
    uint256 constant private MAX_QUANTITY = 10;           // Maximum allowed quantity to purchase in one transaction
    uint256 constant public  COMMUNITY_QUOTA = 10;       // 10% of the sale proceeds stays in the community
    address constant public  COMMUNITY_WALLET = 0x15D3b7e79fF937A2055cD716B4Cb2fbf9868e810;
    address constant public  NUMIS_WALLET = 0xB4EF72BeD4653a8100841BfF7E1Ad4dBEb5ebDC3;

    function baseTokenURI() override public view returns (string memory) {
        return strConcat(_theBaseURI,"item?token_id=");
    }

    function contractURI() public view returns (string memory) {
        return strConcat(_theBaseURI,"collection");
    }



    // Views
    function active() external view returns(bool) {
        return _active;
    }


    // Sale
    function give_to_community(uint256 coins) internal {
        uint256 amount = (coins*PRICE*COMMUNITY_QUOTA).div(100);
        payable(COMMUNITY_WALLET).transfer(amount);
    }

    function purchase(uint256 coins) external payable {
        require(_active, "Inactive");
        require(coins <= remaining() && coins <= MAX_QUANTITY, "Too many coins requested");
        require(msg.value == coins*PRICE, "Invalid purchase amount sent");
        for (uint i = 0; i < coins; i++) {
            mintTo(msg.sender);
        }
        give_to_community(coins);
    }



    // Owner's functions

    modifier onlyNumis() {
        require((owner() == _msgSender() || NUMIS_WALLET == _msgSender()), "You are not Numis!");
        _;
    }

    function setBaseMetadataURI( string memory _newBaseMetadataURI) public onlyNumis {
        _theBaseURI = _newBaseMetadataURI;
    }

    function activate() external onlyNumis {
        require(!_active, "Already active");
        _active = true;
    }

    function pause() external onlyNumis {
        require(_active, "Already paused");
        _active = false;
    }

    function premine(uint256 coins) external onlyNumis {
        require(!_active, "Already active");
        for (uint i = 0; i < coins; i++) {
            mintTo(msg.sender);
        }
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyNumis {
        recipient.transfer(amount);
    }


    // Strings
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

}