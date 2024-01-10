pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT


import "./ERC721B.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./ERC165.sol";

import "./HexStrings.sol";
import "./ToColor.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

abstract contract ERC2981ContractWideRoyalties is IERC2981, ERC165 {
    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;



    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }
}

contract YourCollectible is ERC721B, Ownable, ReentrancyGuard, ERC2981ContractWideRoyalties {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  bool public mintingActive = false;

   address payable public constant recipient =
    payable(0x38B2bAC6431604dFfEc17a1E6Adc649a9Ea0eFba);

    uint256 public price = 0.00 ether;



  constructor() public ERC721B("ETHERHEARTS", "EHRT") Ownable() {
    // RELEASE THE LOOGIES!
    _setRoyalties(owner(), 130);
  }


  mapping (uint256 => bytes3) public color;
 
  mapping (uint256 => uint256) public messages;
  mapping (uint256 => uint256) public chubbiness;
  uint256 mintDeadline = block.timestamp + 24 hours;
  
            

      function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }



        function activeCheck() public onlyOwner {
          owner();

        mintingActive = !mintingActive;
    }

      function devMintItem(uint256 quantity)
      public
      
      onlyOwner     
      returns (uint256)
      
  { 
  


      uint256 id; 
      _safeMint(msg.sender, quantity);
      for (uint i=0; i < quantity; i++)   {
      _tokenIds.increment();
      id = _tokenIds.current();
     
      tokenURI(id);
      
     
      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number+quantity), address(this), id, quantity));  
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
  
      messages[id] = (uint8(predictableRandom[4]) % 29 );
      }
    
      return id;
  }

  function mintItem(uint256 quantity)
      public  
      nonReentrant    
      returns (uint256)
  { 
      uint256 lastTokenId = super.totalSupply();
      require( block.timestamp < mintDeadline, 'DONE MINTING');
      require(mintingActive, '\u2764\ufe0f minting soon \u2764\ufe0f');  
      require( quantity <=uint256(5), 'leave some \u2764\ufe0f for the rest of us!');
      require( lastTokenId + quantity <= uint256(222), 'till next year loves \u2764\ufe0f');
      require(!isContract(msg.sender), 'no bots allowed fren.');

      price = price;

      uint256 id; 
      _safeMint(msg.sender, quantity);
      for (uint i=0; i < quantity; i++)   {
      _tokenIds.increment();
      id = _tokenIds.current() - 1;
     
      tokenURI(id);
      
     
      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number+quantity), address(this), id, quantity));  
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
  
      messages[id] = (uint8(predictableRandom[4]) % 29 );
      }


    
      return id;
  }



  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      
      string memory name = string(abi.encodePacked('EtherHeart #',id.toString()));
      string memory description = string(abi.encodePacked('this heart beats the color#',color[id].toColor(),' !!!'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));
      

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://buidlguidl.com',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    

    string memory svg = string(abi.encodePacked(
      '<svg width="100%" height="100%" viewBox="0 0 900 900" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;

  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string[32] memory messageTxt = [ 'RIGHT-CLICK MY HEART','I \u27e0 U','U SWEPT ME OFF MY FLOOR','TOGETHER TILL \u27e0 2.0 SHIPS', 'U RUG MY WORLD', 'BE MINED', 'HODL ME', '0x0x', 'FRONT RUN ME', 'MEV AND CHILL?', 'UR ON MY WHITELIST', 'DECENTRALIZE ME BABY', 'UR MY 1/1', 'BE MY BAY-C', 'EVM COMPATIBLE', 'MAXI 4 U', 'ON-CHAIN HOTTIE', 'U R NONFUNGIBLE TO ME', 'U R MY CRYPTONITE', 'CURATE ME', 'GWEI OUT WITH ME', 'SEEDPHRASE 2 MY \u2764\ufe0f', 'UR A FOX', 'ETHERSCAN ME', '\u26f5 OPEN TO YOUR SEA \u26f5', 'UR MY FOUNDATION', 'U R SUPERRARE', 'ILY.ETH', '$LOOK-in GOOD', 'JPEG ME', 'NON-FUNGIBLE BABY', 'MY LOVE IS LIQUID'  ] ;
    string memory render = string(abi.encodePacked(
        '<g id="head">',
          '<path id="Bottom" d="M70,279.993C70,279.993 63.297,379.987 70,427.647C85.329,536.631 300.49,820.025 450.016,820.025C599.542,820.025 817.839,533.159 830.014,423.782C835.6,373.594 830.007,280.007 830.007,280.007" style="fill:#', 
          color[id].toColor(), ';stroke:rgb(0,0,0);stroke-width:5px;"/>',
        '<path id="Top" d="M449.75,149.777C426.146,149.777 401.744,80.04 249.999,80.001C139.6,79.972 70,169.594 70,279.993C70,450.051 347.857,689.996 450.004,689.996C552.151,689.996 830.007,449.95 830.007,280.007C830.007,169.801 760.231,80.049 650.026,80.049C486.311,80.049 473.355,149.777 449.75,149.777Z" style="fill:#',
        color[id].toColor(), ';stroke:rgb(0,0,0);stroke-width:5px;"/>',
        '<text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" stroke="rgb(211, 73, 78)" stroke-width= "5" font-weight="400" font-size="48" font-family="Helvetica" fill="rgb(211, 73, 78)">' , messageTxt[messages[id]], '</text>',
        '</g>'
      ));

    return render;
  }


}