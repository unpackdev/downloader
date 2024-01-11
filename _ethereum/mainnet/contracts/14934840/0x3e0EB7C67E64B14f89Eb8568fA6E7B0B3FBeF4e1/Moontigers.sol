//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// .......................................................................
// .......................................................................
// .......................Welcome to Moontigers...........................
// .................................O.....................................
// ................................\|/....................................
// ................................/.\....................................
// .......................................................................
// .......................................................................
// .......................................................................
// .......................................................................


import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract Moontigers is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public MAX_SUPPLY = 5000;
    string public baseURI;
    string public contractURI;
    uint256 public price;
    mapping(address => uint256) private addressMintCount;

    constructor()
        ERC721A("Moontigers", "MOONTIGERS")
    {
        baseURI = "ipfs://bafybeidkasyv4lk7xov26zvyjgmmx3sn4bgwcjtxjjzyeefwzdh2yg6jfi/";
        contractURI = "ipfs://bafybeihefer5z5y2tfrgtylzsc62ge3yobezomizvx36ht3mls7o35rfhi/";
        price = 1000000000000000 wei;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function updatePrice(uint256 _price) external onlyOwner() {
      price = _price;
    }

    function updateBaseURI(string memory _uri) external onlyOwner {
      baseURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(
          _exists(_tokenId),
          "ERC721Metadata: URI set of nonexistent token"
      );

      return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function getContractURI() public view returns (string memory) {
      return string(abi.encodePacked(contractURI, "contractURI.json"));
    }

    function updatecontractURI(string memory _newURI) public onlyOwner {
      contractURI = _newURI;
    }

    function mint(uint _quantity) external payable {
      require(addressMintCount[msg.sender] + _quantity <= 5,
        "This purchase would exceed the maximum Moontigers you are allowed to mint"
      );
      uint totalPrice;
      uint supply;
      unchecked {
        if (addressMintCount[msg.sender] + _quantity <= 2) {
          totalPrice = 0;
        } else if (addressMintCount[msg.sender] >= 2) {
          totalPrice = _quantity * price;
        } else {
          totalPrice = _quantity * price - (2 - addressMintCount[msg.sender]) * price;
        }
        supply = totalSupply() + _quantity;
      }

      require(msg.value >= totalPrice, "Send more eth");
      require(supply <= MAX_SUPPLY, "Max supply reached");


      addressMintCount[msg.sender] += _quantity;
      _mint(msg.sender, _quantity);
    }

    function getSnacks() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }
}