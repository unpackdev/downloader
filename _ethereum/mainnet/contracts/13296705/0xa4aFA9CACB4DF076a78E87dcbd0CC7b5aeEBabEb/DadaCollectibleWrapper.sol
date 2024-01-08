// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IDadaCollectible {
   function transfer(address to, uint drawingId, uint printIndex) external returns (bool success);
   function DrawingPrintToAddress(uint print) external returns (address _address);
   function buyCollectible(uint drawingId, uint printIndex) external payable;
}

contract DadaCollectibleWrapper is ERC721URIStorage, Ownable {

    IDadaCollectible public _DadaContract;

    mapping(uint => uint) public  _tokenIDToDrawingID;

    string private _baseTokenURI;
    address public _owner;

    event Wrapped(uint indexed drawingID, uint printID);
    event Unwrapped(uint indexed drawingID, uint printID);

   constructor(address dadaCollectibleAddress) ERC721("Wrapped Creeps and Weirdos","CAW")  {
       _owner = msg.sender;
       _DadaContract = IDadaCollectible(dadaCollectibleAddress);
       _baseTokenURI = "https://dadacollectibles.s3.eu-north-1.amazonaws.com/Dada+Metadata/";
   }

    function _baseURI() internal override view virtual returns (string memory)  {
    return _baseTokenURI;
     }

     function _setBaseURI(string memory baseUri) public {
         require(_owner == msg.sender);
        _baseTokenURI = baseUri;
     }

    /**
   * @dev Returns an URI for a given token ID
   */
  function tokenURI(uint256 _tokenId) public override view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(_tokenIDToDrawingID[_tokenId]))
    );
  }

    function wrap(uint drawingId, uint printIndex) public {

        address owner_address = _DadaContract.DrawingPrintToAddress(printIndex);
        // Check if caller owns the ERC20
        require(owner_address == msg.sender, "Does not own ERC20");

        _DadaContract.buyCollectible(drawingId, printIndex);

        // Check if buy succeeded
        require(_DadaContract.DrawingPrintToAddress(printIndex) == address(this), "An error occured");

        _tokenIDToDrawingID[printIndex] = drawingId;

        _mint(msg.sender, printIndex);
        emit Wrapped(drawingId, printIndex);
    }

    function unwrap(uint drawingId, uint printIndex) public {
        // Check if caller owns the drawing
         require(ownerOf(printIndex) == msg.sender, "Does not own ERC721");
         bool success = _DadaContract.transfer(msg.sender,drawingId,printIndex);

         // Check if transfer succeeded
         require(success);

         _burn(printIndex);
         emit Unwrapped(drawingId, printIndex);
    }

}
